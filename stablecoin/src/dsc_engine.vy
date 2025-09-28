# pragma version 0.4.3

from interfaces import i_dsc
from interfaces import AggregatorV3Interface
from ethereum.ercs import IERC20

# ------------------------------------------------------------------
#                         STATE VARIABLES
# ------------------------------------------------------------------
DSC: public(immutable(i_dsc))
COLLATERAL_TOKENS: public(immutable(address[2]))
ADDITIONAL_FEED_PRECISION: public(constant(uint256)) = 1 * (10**10)
PRECISION: public(constant(uint256)) = 1 * (10 ** 18)
LIQUIDATION_THRESHOLD: public(constant(uint256)) = 50
LIQUIDATION_PRECISION: public(constant(uint256)) = 100
MIN_HEALTH_FACTOR: public(constant(uint256)) = 1 * (10 ** 18)

# Storage variable
token_to_price_feed: public(HashMap[address, address])
user_to_token_to_amount_deposited: public(HashMap[address, HashMap[address, uint256]])
user_to_dsc_mint: public(HashMap[address, uint256])

# ------------------------------------------------------------------
#                              EVENTS
# ------------------------------------------------------------------
event CollateralDeposited:
    user: indexed(address)
    amount: indexed(uint256)

# ------------------------------------------------------------------
#                        EXTERNAL FUNCTIONS
# ------------------------------------------------------------------
@deploy
def __init__(
    token_addresses: address[2],
    price_feed_addresses: address[2],
    dsc_address:address
):
    DSC = i_dsc(dsc_address)
    COLLATERAL_TOKENS = token_addresses
    self.token_to_price_feed[token_addresses[0]] = price_feed_addresses[0]
    self.token_to_price_feed[token_addresses[1]] = price_feed_addresses[1]

@external
def deposit_collateral(token_collateral_address: address, amount_collateral: uint256):
    self._deposit_collateral(token_collateral_address, amount_collateral) 

@external
def mint_dsc():
    pass
    

# ------------------------------------------------------------------
#                        INTERNAL FUNCTIONS
# ------------------------------------------------------------------
@internal
def _deposit_collateral(token_collateral_address: address, amount_collateral: uint256):
    # Checks
    assert amount_collateral > 0, "amount of collateral needs to be positive"
    assert self.token_to_price_feed[token_collateral_address] != empty(address), "Token not supported"
    
    # Effects
    self.user_to_token_to_amount_deposited[msg.sender][token_collateral_address] += amount_collateral
    # log CollateralDeposited(msg.sender, amount_collateral)

    # Interactions
    success: bool = extcall IERC20(token_collateral_address).transferFrom(msg.sender, self, amount_collateral)
    assert success, "Transder failed"


@internal
def _mint_dsc(amount_to_mint: uint256):
    assert amount_to_mint > 0, "the mint amount needs to be positive"

    self.user_to_dsc_mint[msg.sender] += amount_to_mint
    assert self._health_factor(msg.sender) >= MIN_HEALTH_FACTOR, "health factor broken" 
    extcall DSC.mint(msg.sender, amount_to_mint)

@internal
def _get_account_information(user: address) -> (uint256, uint256):
    # both amount in dollars
    total_dsc_minted: uint256 = self.user_to_dsc_mint[user]
    collateral_value_in_usd: uint256 = self._get_account_collateral_value(user)
    return total_dsc_minted, collateral_value_in_usd



@internal
def _get_account_collateral_value(user: address) -> uint256:
    total_collateral_value_usd: uint256 = 0
    for token: address in COLLATERAL_TOKENS:
        amount: uint256 = self.user_to_token_to_amount_deposited[user][token]
        total_collateral_value_usd += self._get_usd_value(token, amount)
    return total_collateral_value_usd


@internal
@view
def _get_usd_value(token: address, amount: uint256) -> uint256:
    price_feed: AggregatorV3Interface = AggregatorV3Interface(self.token_to_price_feed[token])
    price: int256 = staticcall price_feed.latestAnswer()
    return (convert(price, uint256) * ADDITIONAL_FEED_PRECISION * amount) // PRECISION


@internal 
def _health_factor(user: address) -> uint256:
    total_mint:uint256 = 0
    total_collateral:uint256 = 0
    total_mint, total_collateral = self._get_account_information(user)
    return self._calculate_health_factor(total_mint, total_collateral)

@internal
def _calculate_health_factor(total_mint: uint256, total_collateral: uint256) -> uint256:
    if total_mint == 0:
        return max_value(uint256)
    collateral_adjusted_threshold: uint256 = (total_collateral * LIQUIDATION_THRESHOLD) // LIQUIDATION_PRECISION
    return (collateral_adjusted_threshold * PRECISION) // total_mint

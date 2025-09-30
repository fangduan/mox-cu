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
LIQUIDATION_BONUS: public(constant(uint256)) = 10
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
def mint_dsc(amount: uint256):
    self._mint_dsc(amount)

@external
def deposit_and_mint_collateral(token_collateral_address: address, 
                                amount_collateral: uint256,
                                amount_msc: uint256):
    self._deposit_collateral(token_collateral_address, amount_collateral)
    self._mint_dsc(amount_msc)
    
@external
def redeem_collateral(token_collateral_address: address, amount: uint256):
    self._redeem_collateral(token_collateral_address, amount, msg.sender, msg.sender)
    assert self._health_factor(msg.sender) >= MIN_HEALTH_FACTOR, "health factor broken" 
    
@external
def redeem_collateral_for_dsc(
    token_collateral_address: address,
    amount_collateral: uint256,
    amount_dsc_to_burn: uint256,
):
    self._burn_dsc(amount_dsc_to_burn, msg.sender, msg.sender)
    self._redeem_collateral(
        token_collateral_address, amount_collateral, msg.sender, msg.sender
    )
    assert self._health_factor(msg.sender) >= MIN_HEALTH_FACTOR, "health factor broken"

@external
def burn_dsc(amount_dsc_to_burn: uint256):
    self._burn_dsc(amount_dsc_to_burn, msg.sender, msg.sender)
    assert self._health_factor(msg.sender) >= MIN_HEALTH_FACTOR, "health factor broken"

@external
def liquidate(collateral: address, user: address,  debt_to_cover: uint256):
    assert debt_to_cover > 0, "needs more than zero"
    assert self._health_factor(user) < MIN_HEALTH_FACTOR, "health factor ok"

    token_amount_from_debt_covered: uint256 = self._get_token_amount_from_usd(collateral, debt_to_cover)
    bonus_collateral: uint256 = (token_amount_from_debt_covered * LIQUIDATION_BONUS) // LIQUIDATION_PRECISION

    self._redeem_collateral(collateral, 
                            token_amount_from_debt_covered + bonus_collateral,
                            user,
                            msg.sender)
    self._burn_dsc(debt_to_cover, user, msg.sender)
    ending_health_factor: uint256 = self._health_factor(user)
    assert ending_health_factor >= MIN_HEALTH_FACTOR, "not improve health factor"
    assert self._health_factor(msg.sender) >= MIN_HEALTH_FACTOR, "health factor broken"

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
@view
def _get_token_amount_from_usd(token: address, usd_amount_in_wei: uint256) -> uint256:
    price_feed: AggregatorV3Interface = AggregatorV3Interface(self.token_to_price_feed[token])
    price: int256 = staticcall price_feed.latestAnswer()
    return (usd_amount_in_wei * PRECISION) // (convert(price, uint256) * ADDITIONAL_FEED_PRECISION)

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

@internal
def _redeem_collateral(token_collateral_address: address, amount: uint256, _from: address, _to: address):
    self.user_to_token_to_amount_deposited[_from][token_collateral_address] -= amount
    success: bool = extcall IERC20(token_collateral_address).transfer(_to, amount)
    assert success, "collateral redeem failed"    

@internal
def _burn_dsc(amount: uint256, on_behalf_of: address, dsc_from: address):
    self.user_to_dsc_mint[on_behalf_of] -= amount
    extcall DSC.burn_from(dsc_from, amount)    

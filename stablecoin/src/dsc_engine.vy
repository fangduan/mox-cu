# pragma version 0.4.3

from interfaces import i_dsc
from ethereum.ercs import IERC20

# ------------------------------------------------------------------
#                         STATE VARIABLES
# ------------------------------------------------------------------
DSC: public(immutable(i_dsc))
COLLATERAL_TOKENS: public(immutable(address[2]))

# Storage variable
token_to_price_feed: public(HashMap[address, address])
user_to_token_to_amount_deposited: public(HashMap[address, HashMap[address, uint256]])

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
    log CollateralDeposited(msg.sender, amount_collateral)

    # Interactions
    success: bool = extcall IERC20(token_collateral_address).transferFrom(msg.sender, self, amount_collateral)
    assert success, "Transder failed"
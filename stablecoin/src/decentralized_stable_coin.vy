# pragma version 0.4.3

from snekmate.tokens import erc20
from snekmate.auth import ownable as ow
from interfaces import i_dsc

implements: i_dsc
initializes: ow
initializes: erc20[ownable := ow]

exports: (
    erc20.IERC20,
    erc20.burn_from,
    erc20.mint,
    erc20.set_minter,
    erc20.owner,
    erc20.transfer_ownership

)

NAME: constant(String[25]) = "Decentralized Stable Coin"
SYMBOL: constant(String[5]) = "DSC"
DECIMALS: constant(uint8) = 18
EIP_721_VERSION: constant(String[20]) = "1"


@deploy
def __init__():
    ow.__init__()
    erc20.__init__(NAME, SYMBOL, DECIMALS, NAME, EIP_721_VERSION)


    


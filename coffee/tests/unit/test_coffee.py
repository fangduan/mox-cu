import boa
from eth_utils import to_wei
from tests.conftest import SEND_VALUE

RANDOM_USER = boa.env.generate_address("non-owner")

def test_price_feed(coffee, eth_usd):
    assert coffee.PRICE_FEED() == eth_usd.address

def fund_fail(coffee):
    with boa.reverts():
        coffee.fund({"value": 0})

def test_fund(coffee, account):
    # Arrange
    boa.env.set_balance(account.address, SEND_VALUE)
    # Act
    coffee.fund(value=SEND_VALUE, sender=account.address)
    # Assert
    assert coffee.funders(0) == account.address
    assert coffee.funder_to_amount_funded(coffee.funders(0)) == SEND_VALUE

def test_non_owner(coffee_funded):
    # Act / Assert
    with boa.env.prank(RANDOM_USER):
        with boa.reverts():
            coffee_funded.withdraw()

def test_owner(coffee_funded):
    # Arrange
    with boa.env.prank(coffee_funded.OWNER()):
        coffee_funded.withdraw()
    
    # Assert
    assert boa.env.get_balance(coffee_funded.address) == 0

def test_multiple_funders(coffee, account):
    # Arrange
    number_of_funders = 10
    fund_amount = 0
    starting_account_balance = boa.env.get_balance(account.address)
    for i in range(number_of_funders):
        funder_address = boa.env.generate_address("funder" + str(i))
        boa.env.set_balance(funder_address, SEND_VALUE)
        coffee.fund(value=SEND_VALUE, sender=funder_address)
        fund_amount += SEND_VALUE
    
    #Act
    with boa.env.prank(coffee.OWNER()):
        coffee.withdraw()
    
    #Assert
    assert boa.env.get_balance(coffee.address) == 0
    assert boa.env.get_balance(coffee.OWNER()) == starting_account_balance + fund_amount

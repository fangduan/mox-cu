from script.deploy import deploy, INITIAL_SUPPLY
import boa

RANDOM_USER = boa.env.generate_address()

def test_token_supply(deployed_contract):
    assert deployed_contract.totalSupply() == INITIAL_SUPPLY
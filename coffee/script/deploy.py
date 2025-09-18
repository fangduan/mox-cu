from moccasin.config import get_active_network
from src import buy_me_a_coffee
from script.deploy_mocks  import deploy_feed
from moccasin.boa_tools import VyperContract

def deploy_coffee(price_feed: str) -> VyperContract:
    coffee: VyperContract = buy_me_a_coffee.deploy(price_feed)

    actual_network = get_active_network()
    if actual_network.has_explorer():
        result = actual_network.moccasin_verify(coffee)
        result.wait_for_verification()
    return coffee
    
def moccasin_main():
    active_network = get_active_network()    
    price_feed: VyperContract = active_network.manifest_named("price_feed")
    print(f"on the network {active_network.name}, price feed is {price_feed.address}")
    # coffee = buy_me_a_coffee.deploy(price_feed.address)
    # print(coffee.address)
    # print(coffee.get_eth_to_usd_rate(1))
    return deploy_coffee(price_feed)


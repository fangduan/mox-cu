from src import favorites, favorites_factory, add_five
from moccasin.boa_tools import VyperContract
from moccasin.config import get_active_network

def deploy_favorites() -> VyperContract:
    print(f"current network is {get_active_network().name}")
    favorites_contract: VyperContract = favorites.deploy()
    # starting_number: int = favorites_contract.retrieve()
    # print(f"starting number {starting_number}")

    # favorites_contract.store(15)
    # ending_number: int = favorites_contract.retrieve()
    # print(f"ending number {ending_number}")
    return favorites_contract

def deploy_favorites_factory(favorites_contract) -> VyperContract:
    factory_contract: VyperContract = favorites_factory.deploy(favorites_contract.address)
    factory_contract.create_contract()
    factory_contract.store_from_factory(0, 88)
    print(f"New contract stored number with store_from_contract: {factory_contract.retrieve_from_factory(0)}")

    new_contract_address: str = factory_contract.list_of_contracts(0)
    new_contract: VyperContract = favorites.at(new_contract_address)
    new_contract.store(77)
    print(f"New contract stored number: {new_contract.retrieve()}")
    print(f"old contract stored number: {favorites_contract.retrieve()}")

def deploy_add_five():
    five_contract = add_five.deploy()
    five_contract.store(100)
    print("my favorite number is", five_contract.retrieve())

def moccasin_main():
    favorites_contract = deploy_favorites()
    deploy_favorites_factory(favorites_contract)
    deploy_add_five()


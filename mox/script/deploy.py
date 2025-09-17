from src import favorites
from moccasin.boa_tools import VyperContract
from moccasin.config import get_active_network

def deploy_favorites() -> VyperContract:
    favorites_contract: VyperContract = favorites.deploy()
    print(f"current network is {get_active_network().name}")
    starting_number: int = favorites_contract.retrieve()
    print(f"starting number {starting_number}")

    favorites_contract.store(15)
    ending_number: int = favorites_contract.retrieve()
    print(f"ending number {ending_number}")
    return favorites_contract

def moccasin_main():
    deploy_favorites()


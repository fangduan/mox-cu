from src import favorites
from moccasin.boa_tools import VyperContract

def deploy_favorites() -> VyperContract:
    favorites_contract: VyperContract = favorites.deploy()
    starting_number: int = favorites_contract.retrieve()
    print(f"starting number {starting_number}")

    favorites_contract.store(15)
    ending_number: int = favorites_contract.retrieve()
    print(f"ending number {ending_number}")
    return favorites_contract

def moccasin_main():
    deploy_favorites()

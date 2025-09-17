# pragma version 0.4.3

from interface import i_favorites

initial_contract_address: public(address)
list_of_contracts: public(DynArray[i_favorites, 10])

@deploy
def __init__(initial_contract_address: address):
    self.initial_contract_address = initial_contract_address

@external
def create_contract():
    new_contract_address: address = create_copy_of(self.initial_contract_address)
    new_contract: i_favorites = i_favorites(new_contract_address)
    self.list_of_contracts.append(new_contract)

@external
def store_from_factory(index: uint256, favorite_number: uint256):
    extcall self.list_of_contracts[index].store(favorite_number)


@external
def retrieve_from_factory(index: uint256) -> uint256:
    return extcall self.list_of_contracts[index].retrieve()


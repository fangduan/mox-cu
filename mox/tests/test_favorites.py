

def test_starting_values(favorites_contract):
    assert favorites_contract.retrieve() == 15

def test_can_change_favorite_number(favorites_contract):
    favorites_contract.store(42)
    assert favorites_contract.retrieve() == 42

def test_can_add_persion(favorites_contract):
    # arrange
    new_person = "Alice"
    new_number = 42

    # act
    favorites_contract.add_person(new_person, new_number)

    # assert
    assert favorites_contract.list_of_people(0) == (new_number, new_person)
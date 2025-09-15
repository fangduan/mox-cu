import boa


def main():
    print("read in vyper code...")
    favorites_contract = boa.load('favorites.vy')

    starting_favorite_number = favorites_contract.retrieve()
    print(f"starting favorite number: {starting_favorite_number}")

    ending_favorite_number = favorites_contract.store(5)
    print(f"ending favorite number: {ending_favorite_number}")


if __name__ == "__main__":
    main()

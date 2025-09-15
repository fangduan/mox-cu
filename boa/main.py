import boa
from dotenv import load_dotenv
from boa.network import NetworkEnv, EthereumRPC
import os
from eth_account import Account

load_dotenv()

def main():
    rpc = os.getenv("RPC_URL")
    key = os.getenv("ANVIL_KEY")
    env = NetworkEnv(EthereumRPC(rpc))
    boa.set_env(env)
    my_account = Account.from_key(key)
    boa.env.add_account(my_account, force_eoa=True)
    favorites_contract = boa.load('favorites.vy')

    starting_favorite_number = favorites_contract.retrieve()
    print(f"starting favorite number: {starting_favorite_number}")

    favorites_contract.store(5)
    ending_favorite_number = favorites_contract.retrieve()
    print(f"ending favorite number: {ending_favorite_number}")

    print("add person...")
    favorites_contract.add_person("Alice", 42)
    person_data = favorites_contract.list_of_people(0)
    print(f"first person data: {person_data}")

if __name__ == "__main__":
    main()
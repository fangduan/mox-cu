import boa
from boa.network import NetworkEnv, EthereumRPC
import os
from eth_account import Account
from dotenv import load_dotenv

load_dotenv()

MY_CONTRACT = "0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9" # will not exist when new anvil is created

def main():
    rpc = os.getenv("RPC_URL")
    key = os.getenv("ANVIL_KEY")
    env = NetworkEnv(EthereumRPC(rpc))
    boa.set_env(env)
    my_account = Account.from_key(key)
    boa.env.add_account(my_account, force_eoa=True)

    contract_deployer = boa.load_partial('favorites.vy')
    favorites_contract = contract_deployer.at(MY_CONTRACT)

    favoriate_number = favorites_contract.retrieve()
    print(f"favorite number: {favoriate_number}")

if __name__ == "__main__":
    main()
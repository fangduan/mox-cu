from vyper import compile_code
from web3 import Web3
from dotenv import load_dotenv
import os
from encrypt_key import KEYSTORE_PATH
import getpass
import json
from eth_account import Account

load_dotenv()
RPC_URL = os.getenv("RPC_URL")
MY_ADDRESS = os.getenv("MY_ADDRESS")

def main():
    print("read in vyper codes...")
    with open("favorites.vy", "r") as f:
        compliation_details = compile_code(f.read(), output_formats=["bytecode", "abi"])

    w3 = Web3(Web3.HTTPProvider(RPC_URL))
    favorites_contract = w3.eth.contract(bytecode=compliation_details["bytecode"], 
                                         abi=compliation_details["abi"])

    print("building transaction...")
    nouce = w3.eth.get_transaction_count(MY_ADDRESS)
    transaction = favorites_contract.constructor().build_transaction(
        {
            "from": MY_ADDRESS,
            "nonce": nouce,
            "gasPrice": w3.eth.gas_price
        }
    )
        
    private_key = decrypt_key()
    signed_transaction = w3.eth.account.sign_transaction(transaction, private_key)
    tx_hash = w3.eth.send_raw_transaction(signed_transaction.raw_transaction)    
    tx_receipt = w3.eth.wait_for_transaction_receipt(tx_hash)
    print(f"Contract deployed at address: {tx_receipt.contractAddress}")
    
def decrypt_key() -> str:
    with open(KEYSTORE_PATH, "r") as fp:
        encrypted_key = fp.read()
        password = getpass.getpass("Enter your password to decrypt the key: ")
        private_key = Account.decrypt(encrypted_key, password)
        return private_key

if __name__ == "__main__":
    main()

import getpass
from eth_account import Account
from pathlib import Path
import json

KEYSTORE_PATH = Path(".keystore.json")

def main():
    private_key = getpass.getpass("Enter your private key: ")
    account = Account.from_key(private_key)

    password = getpass.getpass("Enter a password to encrypt the key:")
    encrypted = account.encrypt(password)

    print(f"Saving encrypted key to {KEYSTORE_PATH}")
    with open(KEYSTORE_PATH, "w") as f:
        json.dump(encrypted, f)

if __name__ == "__main__":
    main()
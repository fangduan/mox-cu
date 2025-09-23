from src import basic_nft

PUG_URI = "QmW16U98JrY9HBY36rQtUuUtDnm6LdEeNdAAggmrx3thMa"


def deploy_nft():
    contract = basic_nft.deploy()
    contract.mint(PUG_URI)
    token_metadata = contract.tokenURI(0)
    print(token_metadata)
    return contract


def moccasin_main():
    return deploy_nft()

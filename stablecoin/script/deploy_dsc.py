from src import decentralized_stable_coin
from moccasin.boa_tools import VyperContract


def deploy_dsc() -> VyperContract:
    decentralized_stable_coin.deploy()


def moccasin_main():
    return deploy_dsc

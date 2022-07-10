from brownie import DappToken, TokenFarm
from web3 import Web3

from scripts.helpful_scripts import get_account


def deploy_token_farm_and_dapp_token():
    account = get_account()
    dapp_token = DappToken.deploy({"from": account})
    token_farm = TokenFarm.deploy({"from": account})


def main():
    deploy_token_farm_and_dapp_token()

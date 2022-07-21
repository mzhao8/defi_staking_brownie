# if deploying freezes: https://stackoverflow.com/questions/69818605/brownie-doesnt-automatically-attach-to-local-ganache-when-i-have-ganache-open-i

from brownie import DappToken, TokenFarm, config, network
from web3 import Web3

from scripts.helpful_scripts import get_account, get_contract

KEPT_BALANCE = Web3.toWei(100, "ether")


def deploy_token_farm_and_dapp_token():
    account = get_account()
    dapp_token = DappToken.deploy({"from": account})
    token_farm = TokenFarm.deploy(
        dapp_token.address,
        {"from": account},
        publish_source=config["networks"][network.show_active()].get("verify", False),
    )

    tx = dapp_token.transfer(
        token_farm.address, dapp_token.totalSupply() - KEPT_BALANCE, {"from": account}
    )

    # wait for 1 confirmation
    tx.wait(1)

    # create function "add_allowed_tokens" that maps the price feeds
    # deploy own fake weth token
    fau_token = get_contract("fau_token")
    weth_token = get_contract("weth_token")

    # contracts of the price feeds
    dict_of_allowed_tokens = {
        dapp_token: get_contract("dai_usd_price_feed"),
        fau_token: get_contract("dai_usd_price_feed"),
        weth_token: get_contract("eth_usd_price_feed"),
    }

    add_allowed_tokens(token_farm, dict_of_allowed_tokens, account)

    return token_farm, dapp_token


def add_allowed_tokens(token_farm, dict_of_allowed_tokens, account):
    # add allowed tokens: start with 3, DAPP, WETH, FAU/DAI

    # map to the price feed
    for token in dict_of_allowed_tokens:
        add_tx = token_farm.addAllowedTokens(token.address, {"from": account})
        add_tx.wait(1)
        set_tx = token_farm.setPriceFeedContract(
            token.address, dict_of_allowed_tokens[token], {"from": account}
        )
        set_tx.wait(1)


def main():
    deploy_token_farm_and_dapp_token()

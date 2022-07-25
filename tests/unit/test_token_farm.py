# also need to write tests for Dapp token in a full scale production
# every piece of code needs to be tested in some form or another


from scripts.deploy import deploy_token_farm_and_dapp_token
from scripts.helpful_scripts import (
    LOCAL_BLOCKCHAIN_ENVIRONMENTS,
    INITIAL_VALUE,
    get_account,
    get_contract,
)

from brownie import network, exceptions
import pytest
from web3 import Web3


def test_set_price_feed_contract():
    # Arrange
    if network.show_active() not in LOCAL_BLOCKCHAIN_ENVIRONMENTS:
        pytest.skip("Only for local testing!")
    account = get_account()
    non_owner = get_account(index=1)
    token_farm, dapp_token = deploy_token_farm_and_dapp_token()

    # Act
    # the price feed address is set by owner, guess i don't need any approvals since the account owner is automatically doing this
    price_feed_address = get_contract("eth_usd_price_feed")
    token_farm.setPriceFeedContract(
        dapp_token.address, price_feed_address, {"from": account}
    )

    # Assert
    # the price feed mapping should be updated AND the non_owner can't set the price feed contract
    assert token_farm.tokenPriceFeedMapping(dapp_token.address) == price_feed_address
    with pytest.raises(exceptions.VirtualMachineError):
        token_farm.setPriceFeedContract(
            dapp_token.address, price_feed_address, {"from": non_owner}
        )


# brownie test -k test_stake_tokens
def test_stake_tokens(amount_staked):
    # Arrange
    if network.show_active() not in LOCAL_BLOCKCHAIN_ENVIRONMENTS:
        pytest.skip("Only for local testing!")
    account = get_account()
    token_farm, dapp_token = deploy_token_farm_and_dapp_token()

    # Act
    # need an approval first on the dapp_token for the token_farm to take over the contract
    dapp_token.approve(token_farm.address, amount_staked, {"from": account})
    # token_farm.addAllowedTokens(dapp_token.address, {"from": account})
    token_farm.stakeTokens(amount_staked, dapp_token.address, {"from": account})

    # Assert
    assert (
        token_farm.stakingBalance(dapp_token.address, account.address) == amount_staked
    )

    assert token_farm.uniqueTokensStaked(account.address) == 1
    assert token_farm.stakers(0) == account.address
    return token_farm, dapp_token


def test_issue_tokens(amount_staked):
    # Arrange
    if network.show_active() not in LOCAL_BLOCKCHAIN_ENVIRONMENTS:
        pytest.skip("Only for local testing!")
    account = get_account()
    token_farm, dapp_token = test_stake_tokens(amount_staked)
    starting_balance = dapp_token.balanceOf(account.address)

    # Act
    token_farm.issueTokens({"from": account})

    # Assert
    # assert that this account has this many dapp tokens (starting balance + )
    # staking 1 dapp token in the price of usd/eth
    # we assume price of 1 ETH is $2000 according to helpful scripts deploy mock function
    assert dapp_token.balanceOf(account.address) == starting_balance + INITIAL_VALUE
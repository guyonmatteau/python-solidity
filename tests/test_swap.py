"""Tests to demonstrate the Swap functionality from Python perspective."""
import pytest

from blockchain.contract import Contract
from blockchain.utils import get_config

CONFIG = get_config(path="conf/main.toml")


@pytest.mark.dependency()
def test_deploy(provider):
    """Test contract deployment by deploying contract
    and asserting ${ACCOUNT} is the owner."""
    contract_address = provider.deploy(contract="Swap")

    pytest.deployment.contract = swap_contract = Contract(
        address=contract_address, name="Swap"
    )
    owner = swap_contract.functions.owner().call()

    assert (
        owner == pytest.deployment.account
    ), "Owner of deployed Swap contract is not expected owner"


@pytest.mark.dependency(depends=["test_deploy"])
def test_deposit(provider):
    """Assert that the contract is able to receive funds from the owner / deployer."""
    assert provider.w3.eth.get_balance(pytest.deployment.contract.address) == 0

    value = 10  # ETH
    provider.transfer(
        sender=pytest.deployment.account,
        to=pytest.deployment.contract.address,
        amount=value,
    )

    # get_balance returns wei
    assert provider.w3.eth.get_balance(pytest.deployment.contract.address) == int(
        value * 1e18
    )


@pytest.mark.depenency(depends=["test_deposit"])
def test_deposit_eth_to_weth(erc20):
    """Swap ETH to WETH by depositing into WETH."""
    weth_balance_pre_deposit = erc20.weth.functions.balanceOf(
        pytest.deployment.contract.address
    ).call()

    # native ETH first needs to be swapped to WETH by depositing into ERC20 contract of WETH
    contract = pytest.deployment.contract

    value = int(5e18)
    weth_address = CONFIG["tokens"]["weth"]

    # let the swap contract deposit ETH to WETH
    contract.functions.transferETH(
        contract.w3.to_checksum_address(weth_address), value
    ).transact()

    weth_balance_post_deposit = erc20.weth.functions.balanceOf(
        pytest.deployment.contract.address
    ).call()
    assert weth_balance_post_deposit - weth_balance_pre_deposit == value, "Difference in WETH value of Swap contract not equal to deposited value."


@pytest.mark.dependency(depends=["test_deposit_eth_to_weth"])
def test_swap_weth_usdc_uniswap(erc20):
    """Testing the actual contract: swap WETH for USDC on Uni V3."""
    usdc_balance_pre_swap = erc20.usdc.functions.balanceOf(
        pytest.deployment.contract.address
    ).call()

    # perform swap
    pool_fee = 3000
    amount = int(2e18)
    pytest.deployment.contract.swap(
        CONFIG["routers"]["uniswapv3"],
        erc20.weth.address,
        erc20.usdc.address,
        pool_fee,
        amount,
    ).transact()

    usdc_balance_post_swap = erc20.usdc.functions.balanceOf(
        pytest.deployment.contract.address
    ).call()

    assert usdc_balance_post_swap > usdc_balance_pre_swap, "USDC balance not increased"


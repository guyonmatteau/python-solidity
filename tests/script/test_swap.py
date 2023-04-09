"""Tests to demonstrate the Swap functionality from Python perspective."""
import pytest
import os

from blockchain.provider import Provider
from blockchain.contract import Contract


@pytest.fixture()
def provider():
    """Provide a chain provider to interact with chain."""
    p = Provider(chain="main", fork=True, proxy=False)
    pytest.deployment.account = os.environ["ACCOUNT"]
    return p


def test_deploy(provider):
    """Test contract deployment by deploying contract
    and asserting ${ACCOUNT} is the owner."""
    pytest.deployment.contract_address = provider.deploy(contract="Swap")

    swap_contract = Contract(address=pytest.deployment.contract_address, name="Swap")
    owner = swap_contract.functions.owner().call()
    
    assert owner == pytest.deployment.account, \
        "Owner of deployed Swap contract is not expected owner"
    

def test_deposit():
    pass


def test_swap_eth_usdc_univ3():
    pass


def test_swap_usdc_usdt_sushi():
    pass

def test_transfer_output():
    pass



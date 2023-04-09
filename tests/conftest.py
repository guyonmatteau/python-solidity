"""Implementation of fixtures and utilities required for testing."""
import os

import pytest

from blockchain.abi import ERC20 as ABI
from blockchain.contract import Contract
from blockchain.provider import Provider
from blockchain.utils import get_config


class Deployment:
    """Utility class to store information regarding the deployed contract,
    which is needed across multiple tests."""

    address: str
    account: str
    contract: Contract


class ERC20:
    """Utility class to provide convenient access to ERC20s during tests."""

    weth: Contract
    usdc: Contract
    usdt: Contract


def pytest_configure():
    pytest.deployment = Deployment()


@pytest.fixture(scope="session")
def provider():
    """Provide a chain provider to interact with chain."""
    p = Provider(chain="main", fork=True, proxy=False)
    pytest.deployment.account = os.environ.get("ACCOUNT")
    assert (
        os.environ.get("PRIVATE_KEY") is not None
        and pytest.deployment.account is not None
    ), "PRIVATE_KEY and/or ACCOUNT not found"
    return p


@pytest.fixture(scope="session")
def erc20() -> ERC20:
    """Provide ERC20 contract instances of ERC20s, accessible in one object."""
    tokens = get_config("main")["tokens"]
    erc20s = ERC20()
    erc20s.weth = Contract(address=tokens["weth"], abi=ABI)
    erc20s.usdc = Contract(address=tokens["usdc"], abi=ABI)
    erc20s.usdt = Contract(address=tokens["usdt"], abi=ABI)
    return erc20s

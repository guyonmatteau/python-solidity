import logging
import os
import sys
import json
from configparser import ConfigParser

import requests
from dotenv import load_dotenv
from web3 import Web3

logging.basicConfig(stream=sys.stdout, level=logging.INFO)
logger = logging.getLogger(__name__)


class Provider:
    """Class to interact with blockchain."""

    def __init__(self, chain: str, fork: bool = True, proxy: bool = False):
        """Instantiate blockchain provider.

        Args:
            chain str: chain that corresponds to conf/<chain>.ini file.
            fork bool: whether a local fork is used
            proxy str: if run behind proxy.
        """
        self.chain = chain
        self.cert = os.environ["CA_CERT"]
        self.config = ConfigParser()
        config_path = f"conf/{chain}.ini"
        logger.info(f"Reading config from {config_path}")
        self.config.read(config_path)

        secrets = f".env.{chain}"
        logger.info(f"Reading secrets from {secrets}")
        load_dotenv(secrets)

        if fork:
            logger.info(f"Using local fork from {chain}")
            self.rpc_url = self.config.get("url", "localhost")
        else:
            self.rpc_root = self.config.get("url", "rpc")
            rpc_api_key = os.environ["RPC_API_KEY"]
            self.rpc_url = f"{self.rpc_root}{rpc_api_key}"
        logger.info(f"RPC url: {self.rpc_url}")

        # proxy only needed when not using a fork
        if proxy:
            logger.info("Using certificate behind proxy")
            session = requests.Session()
            session.verify = self.cert
            self.w3 = Web3(Web3.HTTPProvider(self.rpc_url, session=session))
        else:
            self.w3 = Web3(Web3.HTTPProvider(self.rpc_url))

        logger.info(f"Connected to chain {self.chain}: {self.w3.is_connected()}")

    def get_balance(self, address: str) -> float:
        """Get balance of the native chain asset (ETH, Goerli ETH) at given address."""
        return self.w3.eth.get_balance(address)


class Contract(Provider):
    """Class to interact with contract on blockchain."""

    def __init__(
        self,
        address: str,
        name: str = None,
        chain: str = "main",
        fork: bool = True,
        proxy: bool = False,
    ):
        """Instantiate contract instance with ABI from Etherscan.
        After instantiation all contracts functions are available under
        the `functions` attribute."""
        super().__init__(chain=chain, fork=fork, proxy=proxy)
        self.address = address
        self.abi = self._abi_local() if name is not None else self._abi_etherscan()
        self.functions = self.w3.eth.contract(
            address=self.w3.to_checksum_address(self.address), abi=self.abi
        ).functions

    def _abi_local(self, name: str = "Swap") -> str:
        """Get contract ABI from locally compiled contract."""
        with open(f"out/{name}.sol/{name}.json", "r") as f:
            abi = json.load(f)["abi"]
        return abi

    def _abi_etherscan(self) -> str:
        """Get contract ABI from block explorer."""
        url = self.config.get("url", "block_explorer")
        api_key = os.environ.get("BLOCK_EXPLORER_API_KEY", None)

        if api_key is None:
            raise ValueError(
                "BLOCK_EXPLORER_API_KEY needs to be set to get ABI from Block explorer"
            )

        data = {
            "module": "contract",
            "action": "getabi",
            "address": self.address,
            "apikey": api_key,
        }
        r = requests.get(url, data=data, verify=False)
        abi = r.json()["result"]

        if abi == "Contract source code not verified":
            raise ValueError(f"Address {self.address} not verified on {url}")

        return abi

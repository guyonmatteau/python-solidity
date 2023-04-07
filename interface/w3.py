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
        """Instantiate blockchain provider. After instantation, all blockchain
        functions are available under Provider.w3.eth., e.g.
        Provider.w3.eth.get_balance(address)

        Args:
            chain str: chain that corresponds to conf/<chain>.ini file.
            fork bool: whether a local fork is used
            proxy str: if run behind proxy.
        """
        self.chain = chain
        self.cert = os.environ.get("CA_CERT")
        self.config = ConfigParser()
        config_path = f"conf/{chain}.ini"
        logger.info(f"Reading config from {config_path}")
        self.config.read(config_path)
        if self.config is None:
            raise ValueError(f"Read empty config from {config_path}.")

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
        if not self.w3.is_connected():
            raise ConnectionError(f"Could not connect to {self.rpc_url}")

    def transfer(self, sender: str, to: str, amount: int):
        """Send ETH from sender to recipient. This required
        the private key of the sender in env var PRIVATE_KEY."""

        private_key = os.environ.get("PRIVATE_KEY")
        if private_key is None:
            raise KeyError("Private key of sender not found in PRIVATE_KEY env var")

        # get the nonce, required to prevents one from sending transaction twice
        nonce = self.w3.eth.get_transaction_count(self.w3.to_checksum_address(sender))
        logger.info(f"Nonce of {sender}: {nonce}")

        tx = {
            "nonce": nonce,
            "to": self.w3.to_checksum_address(to),
            "value": self.w3.to_wei(amount, "ether"),
            'gas': 2000000,
            'gasPrice': self.w3.to_wei('50', 'gwei')
        }

        signed_tx = self.w3.eth.account.sign_transaction(tx, private_key)

        # send transaction
        tx_hash = self.w3.eth.send_raw_transaction(signed_tx.rawTransaction)
        logger.info(self.w3.to_hex(tx_hash))

    def deploy(self, contract: str) -> bool:
        """Deploy contract to blockchain."""
        with open(f"src/{contract}.sol", "r") as file:
            content = f.read()
            




class Contract(Provider):
    """Class to interact with existing contract on blockchain."""

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
        self.abi = (
            self._abi_local()
            if name is not None
            else self._abi_etherscan(address=self.address)
        )
        self.functions = self.w3.eth.contract(
            address=self.w3.to_checksum_address(self.address), abi=self.abi
        ).functions

    def _abi_local(self, name: str = "Swap") -> str:
        """Get contract ABI from locally compiled contract."""
        path = f"out/{name}.sol/{name}.json"
        logger.info(f"Getting contract ABI from source at {path}")
        with open(path, "r") as f:
            abi = json.load(f)["abi"]
        return abi

    def _abi_etherscan(self, address) -> str:
        """Get contract ABI from block explorer."""
        # NB: this does not work for ERC20 that use a proxy (e.g. USDC)
        url = self.config.get("url", "block_explorer")
        api_key = os.environ.get("BLOCK_EXPLORER_API_KEY", None)

        logger.info(f"Getting contract ABI for {address} from {url}")
        if api_key is None:
            raise KeyError(
                "BLOCK_EXPLORER_API_KEY needs to be set to get ABI from Block explorer"
            )

        data = {
            "module": "contract",
            "action": "getabi",
            "address": address,
            "apikey": api_key,
        }
        r = requests.get(url, data=data, verify=False)
        abi = r.json()["result"]

        if abi == "Contract source code not verified":
            raise ValueError(f"Address {address} not verified on {url}")

        return abi

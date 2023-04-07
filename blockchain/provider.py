import logging
import os
import sys
from configparser import ConfigParser

import requests
from dotenv import load_dotenv
from solcx import compile_files, install_solc
from web3 import Web3

logging.basicConfig(stream=sys.stdout, level=logging.INFO)
logger = logging.getLogger(__name__)


class Provider:
    """Class to interact with blockchain."""

    def __init__(
        self, chain: str, fork: bool = True, proxy: bool = False
    ) -> "Provider":
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

    def transfer(self, sender: str, to: str, amount: int) -> None:
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
            "gas": 2000000,
            "gasPrice": self.w3.to_wei("50", "gwei"),
        }

        signed_tx = self.w3.eth.account.sign_transaction(tx, private_key)

        # send transaction
        tx_hash = self.w3.eth.send_raw_transaction(signed_tx.rawTransaction)
        logger.info(self.w3.to_hex(tx_hash))

    def deploy(self, contract: str, deployer: str = None, gas: int = 2000000) -> None:
        """Compile contract and deploy to blockchain."""
        from_ = deployer or os.environ["ACCOUNT"]

        private_key = os.environ.get("PRIVATE_KEY")
        if private_key is None:
            raise KeyError("Private key of sender not found in PRIVATE_KEY env var")

        contract = self._compile_contract(contract=contract)
        nonce = self.w3.eth.get_transaction_count(from_)
        tx_data = {
            "chainId": self.w3.eth.chain_id,
            "gasPrice": self.w3.eth.gas_price,
            "gas": gas,
            "from": from_,
            "nonce": nonce,
        }
        tx = contract.constructor().build_transaction(tx_data)
        signed_tx = self.w3.eth.account.sign_transaction(tx, private_key=private_key)

        # send transaction
        tx_hash = self.w3.eth.send_raw_transaction(signed_tx.rawTransaction)
        tx_receipt = self.w3.eth.wait_for_transaction_receipt(tx_hash)
        contract_address = tx_receipt["contractAddress"]

        logger.info(f"Contract deployed to: {contract_address}")
        logger.info(f"Transaction receipt: {tx_receipt}")

    def _compile_contract(self, contract: str) -> "Web3._utils.datatypes.Contract":
        """Compile contract from source."""
        file_path = f"src/{contract}.sol"

        compiler_version = "0.8.17"
        install_solc(compiler_version)

        # read remappings from file such that we do not need to maintain them in
        # multiple places. Slice off last whiteline
        remappings = open("remappings.txt").read().split("\n")[:-1]

        compiled_contract = compile_files(
            source_files=[file_path],
            output_values=["abi", "bin"],
            import_remappings=remappings,
            solc_version=compiler_version,
        )[f"{file_path}:{contract}"]

        contract = self.w3.eth.contract(
            abi=compiled_contract["abi"], bytecode=compiled_contract["bin"]
        )
        return contract

import logging
import os
import sys
import json

import requests

from blockchain.provider import Provider

logging.basicConfig(stream=sys.stdout, level=logging.INFO)
logger = logging.getLogger(__name__)


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
        """Instantiate contract instance with ABI from Etherscan or
        with ABI from local file system.
        After instantiation all contracts functions are available under
        the `functions` attribute."""
        super().__init__(chain=chain, fork=fork, proxy=proxy)
        self.address = address
        self.abi = self._abi_etherscan(address=self.address) if name is None else self._abi_local()
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

# Technical assessment

## Content

This repository contains the effort for the technical assessment for C11 Labs. Specifically:
- The root of the repository in general is dedicated to the first developer assignment.
- To keep it clean the repository does **not** contain configs or artifacts to run the mainnet fork.
- `challenges/` contains the work for the second (EVM) and third (Solidity) challenge. 

## Developer assignment

### Tools

Hardhat is used to run a mainnet fork in a separate folder and window. [Foundry](https://book.getfoundry.sh/) is used to develop and test the smart contract. Pytest is used to test Python functionality and demonstrate the required functionality of the atomic swap.

### Config
`conf/` contains the config for the Python module to deploy the contract to the chain that corresponds to the name of the config file (i.e. mainnet in case of `conf/main.ini`). File `.env.example` contains an example of a config file to store secrets, where `example` should be replaced by the chain of choice and should correspond to the name of the config in `conf`. Thus, we can (hypothetically) create a secrets file `.env.polygon` and `conf/polygon.ini` to interact (deploy, transfer, test against, etc.) directly with the Polygon chain, either remote or a forked local version. For the assignment we only require the mainnet (i.e. `.env.main` and `conf/main.ini`).

_Note: In the config and code one will find traces of using self signed certificates for usage behind a proxy. I worked on both my personal laptop and work laptop on this assignment, and the latter runs behind a VPN._

### Smart contract

`contracts/` and `test/` contain the smart contract to perform the atomic swap as described in the assignment. The contract uses the Router interface of UniswapV3 to act as router for the UniswapV3 and Sushiswap dex's. The contracts functionalities are tested by `test/Swap.t.sol`. These tests are not really unit tests (integration tests rather), since they have the ERC20 addresses hardcoded, and thus require that one runs the Solidity tests against a mainnet fork:
```
forge test -vvv --fork-url ${RPC_URL}${RPC_API_KEY}
```

### Python module

`blockchain/`, `/tests/`, and `requirements.txt` contain a Python module with the following capabilities:

- `Provider` class to interact with any local or remote chain.
- `Contract` class to interact with any existing contract on local or remote chain.
- CLI tool to interact with above classes from the command line
- tests:
  - unittests to test Python modules
  - scripttests to demonstrate the required functionality (i.e. the atomic swap as described in the assignmen)

## Atomic swap

Here the manual steps are described to demonstrate the functionality of the atomic swap. They are also tested in `tests/unit`. After install dependencies one can run the tests with `make test.py.script`.

1. In a separate window a mainnet fork is running. Account 0 (provided by Hardhat) is used as deployment address.
2. Deploy the contract using the CLI:  
```python blockchain/cli.py deploy --contract Swap```
3. Obtain the address of the contract from the output.
4. Send funds to contract address:  
```python blockchain/cli.py transfer --from ${ACCOUNT0} --to <contract-address> --value 10```
```
5. We then let contract swap ETH for WETH by depositing ETH to the WETH contract address.


1. To let the contract peform the Swap we send funds from Account #0 to the address to which the swap contract was deployed.
2. We swap the ETH from the contract to WETH by transferring x ETH to the address of the WETH ERC20 token.
3. 

### Ideas and potential next steps

- CLI tool to private registry 
- Test and upload to registry such that it's available as package:
```
chain transfer x
```
- In production I would assume contract deployment is done by means of a multi-sig process.


## Notes
https://ethereum.stackexchange.com/questions/19341/address-send-vs-address-transfer-best-practice-usage/38642#38642


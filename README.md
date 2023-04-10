# Technical assessment

## Content

This repository contains the effort for the technical assessment. Specifically:
- The root of the repository in general is dedicated to the first developer assignment.
- To keep it clean the repository does **not** contain configs or artifacts to run the mainnet fork.
- `challenges/` contains the work for the second (EVM) and third (Solidity) challenge. 

## Developer assignment

### Tools

Hardhat is used to run a mainnet fork in a separate folder and window. [Foundry](https://book.getfoundry.sh/) is used to develop and test the smart contract. Pytest is used to test Python functionality and demonstrate the required functionality of the atomic swap.

### Config and secrets
`conf/` contains the config for the Python module to deploy the contract to the chain that corresponds to the name of the config file (i.e. mainnet in case of `conf/main.ini`). 

File `.env.example` contains an example of a config file to store secrets, where `example` should be replaced by the chain of choice and should correspond to the name of the config in `conf`. Thus, we can (hypothetically) create a secrets file `.env.polygon` and `conf/polygon.ini` to interact (deploy, transfer, test against, etc.) directly with the Polygon chain, either remote or a forked local version. For the assignment we only require the mainnet (i.e. `.env.main` and `conf/main.ini`).

_Note: In the config and code one will find traces of using self signed certificates for usage behind a proxy. I worked on both my personal laptop and work laptop on this assignment, and the latter runs behind a VPN._

### Smart contract

`contracts/` and `test/` contain the smart contract to perform the atomic swap as described in the assignment. The contract uses the Router interface of UniswapV3 to act as router for UniswapV3 and UniswapV2 router for Sushiswap. The contracts functionalities are tested with Solidity by `test/Swap.t.sol` (Python tests see below). These tests have the ERC20 addresses hardcoded, and thus require that one runs the Solidity tests against a mainnet fork:
```
forge test -vvv --fork-url ${RPC_URL}${RPC_API_KEY}
```

### Python module

`blockchain/`, `/tests/`, and `requirements.txt` contain a Python module with the following capabilities:

- `Provider` class to interact with any local or remote chain.
- `Contract` class to interact with any existing contract on local or remote chain.
- CLI tool to interact with above classes from the command line
- tests to demonstrate the required functionality (i.e. the atomic swap as described in the assignmen)

## Atomic swap

The functionality is tested with both Solidity (Foundry, providing more insights in EVM at runtime, and therefore more convenient during development) and Python using the pytest framework, both against the mainnet fork. Assuming a Hardhat mainnet fork is running, test functionality with Foundry as described in the [Smart contract section](#smart-contract). After installing requirements (`pip install -r requirements.txt`) test with Python:
```
pytest tests
```

This will perform the following tests in a subsequent and dependent order.
1. Compile and deploy `contracts/Swap.sol`.
2. Transfer ETH from the contract deployer (`ACCOUNT0` provided by Hardhat).
3. Obtain WETH by transferring ETH from the Swap contract to the WETH contract address.
4. Swap WETH to USDC on UniSwapV3. For this the UniSwapV3 Router interface is implemented in the contract.
5. Swap USDC to USDT on SushiSwap, using the UniSwapV2 Router.
6. Send USDT to an EOA.

### Future outline

Ideas and potential next steps for further development:

- Contract
  - Add logging of Events through Emit
  - Add modifiers for balance checks
  - Assess vulnerabilities
  - Currently contract does swap (as per the assignment), but even if the swap results in a loss. In case of arbitrage one would want to revert the transaction if it is not at profit. This check  needs to be added.
  - Gas optimization
- Module
  - Containerization / portability: build, test, and deploy the contract from a container to avoid "yes, but it worked on my machine".
  - Basic CLI tool can be extended and uploaded to private registry for convenient internal usage across devs within company.
  - Add pipeline for testing, linting and deployment
  - Add unit tests for the Python module itself.
- Deployment 
  - Currently the contract deploys from a simple machine, whereas in production I would assume contract deployment is done by means of a multi-sig process.


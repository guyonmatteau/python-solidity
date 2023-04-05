# Technical assignment

## Developer assignment

### Config
- `.env.main` contains secrets to deploy to the mainnet fork that is running on localhost and API keys to etherscan to fetch contract ABI's. `.env.example` shows which keys should be in the `.env` file.
- `conf/main.ini` contains mainnet config.

### Swap

To keep it clean this repo does not contain the mainnet fork that we pulled with Hardhat. 

1. In the mainnet fork folder we run a mainnet fork with hardhat:
```
npx hardhat node --fork ...
```

Then this repo contains the contract and Python code to perform the atomic swap.
2. The swap contract (`src/Swap.sol`) is deployed to the forked mainnet using foundry, which we trigger via a make command in the `Makefile`:
```
make deploy
```
3. To let the contract peform the Swap we send funds from Account #0 to the address to which the swap contract was deployed.
4. We swap the ETH from the contract to WETH by transferring x ETH to the address of the WETH ERC20 token.
5. 




## EVM Challenge





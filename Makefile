.PHONY: deploy test

# GLOBALS
CONTRACT=Swap
PYTHON_MODULE=blockchain
PYTHON_TESTS=tests

# .env.<chain> contains chain specific envvars (i.e. PRIVATE_KEY, API_KEY, RPC_URL)
# then every chain dependent target is run with e.g. `make <target> CHAIN=main`
# if no chain provided it will take polygon
ifndef chain
chain = main
endif
include .env.${chain}
export 

# Solidity / Foundry targets
build.sol:
	forge build -c src

format.sol:
	forge fmt

test.sol:
	forge test -vvvvv

test.sol.fork:
	forge test -vvvv --fork-url ${RPC_URL}${RPC_API_KEY}

deploy.sol:
	forge create \
	--private-key ${PRIVATE_KEY} \
	--rpc-url ${RPC_URL}${RPC_API_KEY} \
	contracts/${CONTRACT}.sol:${CONTRACT}

# Python targets
lint.py:
	isort --recursive --check ${PYTHON_MODULE} ${PYTHON_TESTS}
	black --check ${PYTHON_MODULE} ${PYTHON_TESTS}

format.py:
	isort --recursive ${PYTHON_MODULE} ${PYTHON_TESTS}
	black ${PYTHON_MODULE} ${PYTHON_TESTS}

test.py:
	pytest ${PYTHON_TESTS}


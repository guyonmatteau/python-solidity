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
buildsol:
	forge build -c src

formatsol:
	forge fmt

testsol:
	forge test -vvvvv

testsolfork:
	forge test -vvvv --fork-url ${RPC_URL}${RPC_API_KEY}

deploysol:
	forge create \
	--private-key ${PRIVATE_KEY} \
	--rpc-url ${RPC_URL}${RPC_API_KEY} \
	contracts/${CONTRACT}.sol:${CONTRACT}

# Python targets
lintpy:
	isort --recursive --check ${PYTHON_MODULE} ${PYTHON_TESTS}
	black --check ${PYTHON_MODULE} ${PYTHON_TESTS}

formatpy:
	isort --recursive ${PYTHON_MODULE} ${PYTHON_TESTS}
	black ${PYTHON_MODULE} ${PYTHON_TESTS}

testpy:
	pytest ${PYTHON_TESTS}


.PHONY: deploy test

# .env.<chain> contains chain specific envvars (i.e. PRIVATE_KEY, API_KEY, RPC_URL)
# then every chain dependent target is run with e.g. `make <target> CHAIN=main`
# if no chain provided it will take polygon
ifndef chain
chain = main
endif
include .env.${chain}
export 

# GLOBALS
CONTRACT=Swap

# Foundry targets
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
	src/${CONTRACT}.sol:${CONTRACT}

# Python module targets
lint.py:

format.py

test.py.unit:

test.py.script:

test.py:
	test.py.unit
	test.py.script



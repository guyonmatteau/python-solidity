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

# TARGETS
build:
	forge build -c src

test:
	forge test -vvvvv

testfork:
	forge test -vvvv --fork-url ${RPC_URL}${RPC_API_KEY}

deploy:
	forge create \
	--private-key ${PRIVATE_KEY} \
	--rpc-url ${RPC_URL}${RPC_API_KEY} \
	src/${CONTRACT}.sol:${CONTRACT}


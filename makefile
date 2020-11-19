PATH  := node_modules/.bin:$(PATH)
SHELL := /bin/bash
PROJECT_NAME=$(shell basename "$(PWD)")

.DEFAULT_GOAL := help
SOLC=./node_modules/.bin/solcjs
TSC=./node_modules/.bin/tsc
CONTRACT_SOURCES=$(wildcard contracts/*.sol contracts/registry/*.sol contracts/resolver/*.sol)
ENS_REGISTRY_ARTIFACT_NAME=contracts_registry_ENSRegistry_sol_ENSRegistry
ENS_PUBLIC_RESOLVER_ARTIFACT_NAME=contracts_resolver_PublicResolver_sol_PublicResolver
PROCESS_ARTIFACT_NAME=contracts_processes_sol_Processes
NAMESPACE_ARTIFACT_NAME=contracts_namespaces_sol_Namespaces
STORAGE_PROOF_ARTIFACT_NAME=contracts_storage-proof_sol_Erc20StorageProof

#-----------------------------------------------------------------------
# HELP
#-----------------------------------------------------------------------

## help: Display this message

.PHONY: help
help:
	@echo
	@echo " Available targets on "$(PROJECT_NAME)":"
	@echo
	@sed -n 's/^##//p' Makefile | column -t -s ':' |  sed -e 's/^/ /'
	@echo

#-----------------------------------------------------------------------
# RECIPES
#-----------------------------------------------------------------------

## all: Compile the contract artifacts and generate the TypeScript type definitions

all: node_modules js contract-output

## :

## init: Install the dependencies

init: node_modules

node_modules: package.json package-lock.json
	@echo Updating Node packages
	npm install || true
	if [ -d node_modules/web3-providers/node_modules/websocket ]; then \
	  rm -Rf node_modules/web3-providers/node_modules/websocket/.git ; \
	  rm -Rf node_modules/web3-providers-ws/node_modules/websocket/.git ; \
	fi
	@touch $@
package-lock.json:
	@touch $@

js: build/index.js
contract-output: build/ens-registry.json build/ens-public-resolver.json build/processes.json build/namespaces.json build/storage-proof.json

build:
	@mkdir -p build
	@touch $@

build/index.js: build contract-output lib/index.ts
	@echo "Building JS/TS artifacts"
	cp lib/index.ts build
	$(TSC) --build tsconfig.json

build/ens-registry.json: build/solc/$(ENS_REGISTRY_ARTIFACT_NAME).abi build/solc/$(ENS_REGISTRY_ARTIFACT_NAME).bin
	@echo "Building $@"
	echo "{\"abi\":$$(cat build/solc/$(ENS_REGISTRY_ARTIFACT_NAME).abi),\"bytecode\":\"0x$$(cat build/solc/$(ENS_REGISTRY_ARTIFACT_NAME).bin)\"}" > $@

build/ens-public-resolver.json: build/solc/$(ENS_PUBLIC_RESOLVER_ARTIFACT_NAME).abi build/solc/$(ENS_PUBLIC_RESOLVER_ARTIFACT_NAME).bin
	@echo "Building $@"
	echo "{\"abi\":$$(cat build/solc/$(ENS_PUBLIC_RESOLVER_ARTIFACT_NAME).abi),\"bytecode\":\"0x$$(cat build/solc/$(ENS_PUBLIC_RESOLVER_ARTIFACT_NAME).bin)\"}" > $@

build/processes.json: build/solc/$(PROCESS_ARTIFACT_NAME).abi build/solc/$(PROCESS_ARTIFACT_NAME).bin
	@echo "Building $@"
	echo "{\"abi\":$$(cat build/solc/$(PROCESS_ARTIFACT_NAME).abi),\"bytecode\":\"0x$$(cat build/solc/$(PROCESS_ARTIFACT_NAME).bin)\"}" > $@

build/namespaces.json: build/solc/$(NAMESPACE_ARTIFACT_NAME).abi build/solc/$(NAMESPACE_ARTIFACT_NAME).bin
	@echo "Building $@"
	echo "{\"abi\":$$(cat build/solc/$(NAMESPACE_ARTIFACT_NAME).abi),\"bytecode\":\"0x$$(cat build/solc/$(NAMESPACE_ARTIFACT_NAME).bin)\"}" > $@

build/storage-proof.json: build/solc/$(STORAGE_PROOF_ARTIFACT_NAME).abi build/solc/$(STORAGE_PROOF_ARTIFACT_NAME).bin
	@echo "Building $@"
	echo "{\"abi\":$$(cat build/solc/$(STORAGE_PROOF_ARTIFACT_NAME).abi),\"bytecode\":\"0x$$(cat build/solc/$(STORAGE_PROOF_ARTIFACT_NAME).bin)\"}" > $@

build/solc/$(ENS_REGISTRY_ARTIFACT_NAME).abi: build/solc
build/solc/$(ENS_REGISTRY_ARTIFACT_NAME).bin: build/solc
build/solc/$(ENS_PUBLIC_RESOLVER_ARTIFACT_NAME).abi: build/solc
build/solc/$(ENS_PUBLIC_RESOLVER_ARTIFACT_NAME).bin: build/solc
build/solc/$(PROCESS_ARTIFACT_NAME).abi: build/solc
build/solc/$(PROCESS_ARTIFACT_NAME).bin: build/solc
build/solc/$(NAMESPACE_ARTIFACT_NAME).abi: build/solc
build/solc/$(NAMESPACE_ARTIFACT_NAME).bin: build/solc
build/solc/$(STORAGE_PROOF_ARTIFACT_NAME).abi: build/solc
build/solc/$(STORAGE_PROOF_ARTIFACT_NAME).bin: build/solc

# Get openzeppelin contracts
contracts/openzeppelin: node_modules
	rm -f $@
	ln -s ../node_modules/@openzeppelin/contracts $@

# Get RLP contract
contracts/rlp: node_modules
	rm -f $@
	ln -s ../node_modules/solidity-rlp/contracts $@

# Intermediate solidity compiled artifacts
build/solc: $(CONTRACT_SOURCES) contracts/openzeppelin contracts/rlp
	@echo "Building contracts"
	mkdir -p $@
	$(SOLC) --optimize --bin --abi -o $@ --base-path ${PWD}/contracts $(CONTRACT_SOURCES)
	@touch $@

## test: Compile and test the contracts

test: clean all
	npm run test

## clean: Cleanup the build folder

clean: 
	rm -Rf ./build
	rm -Rf ./contracts/openzeppelin
	rm -Rf ./contracts/rlp

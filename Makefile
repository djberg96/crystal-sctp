.PHONY: help build test clean examples install-deps format lint

help: ## Show this help message
	@echo 'Usage: make [target]'
	@echo ''
	@echo 'Available targets:'
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'

build: ## Build the project
	crystal build src/sctp.cr

test: ## Run all specs
	crystal spec

test-verbose: ## Run specs with verbose output
	crystal spec --verbose

examples: ## Run the hello world example
	crystal run examples/hello_world.cr

example-server: ## Run the echo server example
	crystal run examples/server.cr

example-client: ## Run the client example
	crystal run examples/client.cr

example-multistream: ## Run the multi-stream example
	crystal run examples/multi_stream.cr

format: ## Format code with crystal tool format
	crystal tool format src/ spec/ examples/

lint: ## Check code formatting
	crystal tool format --check src/ spec/ examples/

clean: ## Clean build artifacts
	rm -f sctp
	rm -rf .crystal
	rm -rf lib/

install-deps-mac: ## Install libusrsctp on macOS
	brew install usrsctp

install-deps-linux: ## Install libusrsctp on Linux (Ubuntu/Debian)
	sudo apt-get update
	sudo apt-get install -y libusrsctp-dev

docs: ## Generate documentation
	crystal docs

.DEFAULT_GOAL := help

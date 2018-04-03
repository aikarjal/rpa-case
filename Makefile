COMPOSE_FILES = -f docker-compose.yml
DOCKER_COMPOSE = docker-compose
API_PORT = 1881
ID = 0

.DEFAULT_GOAL := help
.PHONY: help
help: ## Print help
	@echo "-----------------------------------------------------------------------------"
	@echo "RPA case"
	@echo "-----------------------------------------------------------------------------"
	@awk -F ":.*##" '/:.*##/ && ! /\t/ {printf "\033[36m%-25s\033[0m%s\n", $$1, $$2}' $(MAKEFILE_LIST) | sort

.PHONY: docker/build
docker/build: ## Build docker images for all containers
	$(DOCKER_COMPOSE) $(COMPOSE_FILES) build

.PHONY: env/run
env/run: env/stop ## Run case environment
	$(DOCKER_COMPOSE) $(COMPOSE_FILES) up -d

.PHONY: env/stop
env/stop: ## Stop case environment
	$(DOCKER_COMPOSE) $(COMPOSE_FILES) down

.PHONY: message
message: ## Generate new message from current timestamp

	curl -H "Content-Type: application/json" -X POST -d '{"id":$(ID)}' localhost:$(API_PORT)/generate

.PHONY: api/test
api/test:
	curl -H "Content-Type: application/json" -X POST -d '{"id":123,"hash":"a665a45920422f9d417e4867efdc4fb8a04a1f3fff1fa07e998e86f7f7a27ae3"}' localhost:$(API_PORT)/checkMessage # Odd id
	curl -H "Content-Type: application/json" -X POST -d '{"id":124,"hash":"6affdae3b3c1aa6aa7689e9b6a7b3225a636aa1ac0025f490cca1285ceaf1487"}' localhost:$(API_PORT)/checkMessage # Even id
	curl -H "Content-Type: application/json" -X POST -d '{"id":130,"hash":"38d66d9692ac590000a91b03a88da1c88d51fab2b78f63171f553ecc551a0c6f"}' localhost:$(API_PORT)/checkMessage # Id that need combining
	curl -H "Content-Type: application/json" -X POST -d '{"id":123,"hash":"b665a45920422f9d417e4867efdc4fb8a04a1f3fff1fa07e998e86f7f7a27ae3"}' localhost:$(API_PORT)/checkMessage # Invalid hash
	curl -H "Content-Type: application/json" -X POST -d '{"id":124,"hash":"7affdae3b3c1aa6aa7689e9b6a7b3225a636aa1ac0025f490cca1285ceaf1487"}' localhost:$(API_PORT)/checkMessage # Invalid hash
	curl -H "Content-Type: application/json" -X POST -d '{"id":130,"hash":"48d66d9692ac590000a91b03a88da1c88d51fab2b78f63171f553ecc551a0c6f"}' localhost:$(API_PORT)/checkMessage # Invalid hash

	

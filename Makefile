IMAGE := andrewthetechie/auto-annotator
.DEFAULT_GOAL := help

help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-40s\033[0m %s\n", $$1, $$2}'

setup: ## Setup a dev environment for working in this repo. Assumes in a venv or other isolation
	pip install --upgrade pip poetry --constraint constraints.txt
	poetry install

build-docker: ## build docker image
	docker build -t andrewthetechie/auto-annotator .

test: ## Run unit tests
	poetry run pytest

test-ci: setup test

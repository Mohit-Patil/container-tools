# =============================================================================
# AI CLI Tools Container - Makefile
# =============================================================================

.PHONY: build run shell stop clean clean-all logs help dev exec \
        create-volume list-volumes backup-config restore-config

# Configuration
IMAGE_NAME := ai-cli-tools
CONTAINER_NAME := ai-cli-tools
WORKSPACE_DIR ?= $(shell pwd)

# Volumes for persistent auth/config (different tools use different locations)
CONFIG_VOLUME := ai-cli-config
CLAUDE_VOLUME := ai-cli-claude
CODEX_VOLUME := ai-cli-codex
AIDER_VOLUME := ai-cli-aider

# Default target
.DEFAULT_GOAL := help

# =============================================================================
# Build Targets
# =============================================================================

## build: Build the Docker image
build:
	docker build -t $(IMAGE_NAME):latest .

## build-no-cache: Build the Docker image without cache
build-no-cache:
	docker build --no-cache -t $(IMAGE_NAME):latest .

# =============================================================================
# Run Targets
# =============================================================================

## run: Start an interactive shell in a new container
run:
	@docker run -it --rm \
		--name $(CONTAINER_NAME) \
		-v "$(WORKSPACE_DIR)":/workspace \
		-v $(CONFIG_VOLUME):/home/devuser/.config \
		-v $(CLAUDE_VOLUME):/home/devuser/.claude \
		-v $(CODEX_VOLUME):/home/devuser/.codex \
		-v $(AIDER_VOLUME):/home/devuser/.aider \
		-e HOST_PWD="$(WORKSPACE_DIR)" \
		-e TERM=xterm-256color \
		$(IMAGE_NAME):latest

## run-detached: Start container in detached mode
run-detached:
	@docker run -d \
		--name $(CONTAINER_NAME) \
		-v "$(WORKSPACE_DIR)":/workspace \
		-v $(CONFIG_VOLUME):/home/devuser/.config \
		-v $(CLAUDE_VOLUME):/home/devuser/.claude \
		-v $(CODEX_VOLUME):/home/devuser/.codex \
		-v $(AIDER_VOLUME):/home/devuser/.aider \
		-e HOST_PWD="$(WORKSPACE_DIR)" \
		-e TERM=xterm-256color \
		$(IMAGE_NAME):latest \
		tail -f /dev/null

## shell: Attach to running container or start new one
shell:
	@if docker ps -q -f name=$(CONTAINER_NAME) | grep -q .; then \
		docker exec -it $(CONTAINER_NAME) /bin/bash; \
	else \
		$(MAKE) run; \
	fi

## run-with-env: Run with environment file
run-with-env:
	@test -f .env || (echo "Error: .env file not found. Copy .env.example to .env first." && exit 1)
	@docker run -it --rm \
		--name $(CONTAINER_NAME) \
		-v "$(WORKSPACE_DIR)":/workspace \
		-v $(CONFIG_VOLUME):/home/devuser/.config \
		-v $(CLAUDE_VOLUME):/home/devuser/.claude \
		-v $(CODEX_VOLUME):/home/devuser/.codex \
		-v $(AIDER_VOLUME):/home/devuser/.aider \
		--env-file .env \
		-e TERM=xterm-256color \
		$(IMAGE_NAME):latest

## run-host-network: Run with host network (for OAuth callbacks)
run-host-network:
	@docker run -it --rm \
		--name $(CONTAINER_NAME) \
		--network host \
		-v "$(WORKSPACE_DIR)":/workspace \
		-v $(CONFIG_VOLUME):/home/devuser/.config \
		-v $(CLAUDE_VOLUME):/home/devuser/.claude \
		-v $(CODEX_VOLUME):/home/devuser/.codex \
		-v $(AIDER_VOLUME):/home/devuser/.aider \
		-e HOST_PWD="$(WORKSPACE_DIR)" \
		-e TERM=xterm-256color \
		$(IMAGE_NAME):latest

# =============================================================================
# Container Management
# =============================================================================

## stop: Stop the running container
stop:
	@docker stop $(CONTAINER_NAME) 2>/dev/null || true

## logs: Show container logs
logs:
	@docker logs -f $(CONTAINER_NAME)

## status: Show container status
status:
	@docker ps -a -f name=$(CONTAINER_NAME)

# =============================================================================
# Cleanup Targets
# =============================================================================

## clean: Stop and remove container
clean: stop
	@docker rm $(CONTAINER_NAME) 2>/dev/null || true

## clean-image: Remove the Docker image
clean-image:
	@docker rmi $(IMAGE_NAME):latest 2>/dev/null || true

## clean-volume: Remove all config volumes (WARNING: deletes auth data)
clean-volume:
	@echo "WARNING: This will delete all saved authentication data!"
	@read -p "Are you sure? [y/N] " confirm && [ "$$confirm" = "y" ] && \
		(docker volume rm $(CONFIG_VOLUME) $(CLAUDE_VOLUME) $(CODEX_VOLUME) $(AIDER_VOLUME) 2>/dev/null || true) || echo "Aborted"

## clean-all: Remove container, image, and volumes
clean-all: clean clean-image
	@echo "Container and image removed."
	@echo "To also remove config volume (auth data), run: make clean-volume"

# =============================================================================
# Development Targets
# =============================================================================

## dev: Run with current directory mounted and host network
dev:
	@docker run -it --rm \
		--name $(CONTAINER_NAME)-dev \
		--network host \
		-v "$(WORKSPACE_DIR)":/workspace \
		-v $(CONFIG_VOLUME):/home/devuser/.config \
		-e TERM=xterm-256color \
		$(IMAGE_NAME):latest

## exec: Execute a command in the running container (usage: make exec CMD="your command")
exec:
	@docker exec -it $(CONTAINER_NAME) $(CMD)

# =============================================================================
# Volume Management
# =============================================================================

## create-volume: Create the config volume
create-volume:
	@docker volume create $(CONFIG_VOLUME)
	@echo "Volume $(CONFIG_VOLUME) created."

## list-volumes: List all related volumes
list-volumes:
	@docker volume ls -f name=$(CONFIG_VOLUME)

## backup-config: Backup config volume to tar file
backup-config:
	@docker run --rm \
		-v $(CONFIG_VOLUME):/source:ro \
		-v "$(WORKSPACE_DIR)":/backup \
		alpine tar czf /backup/ai-cli-config-backup.tar.gz -C /source .
	@echo "Backup saved to ai-cli-config-backup.tar.gz"

## restore-config: Restore config volume from tar file
restore-config:
	@test -f ai-cli-config-backup.tar.gz || (echo "Error: ai-cli-config-backup.tar.gz not found" && exit 1)
	@docker run --rm \
		-v $(CONFIG_VOLUME):/target \
		-v "$(WORKSPACE_DIR)":/backup:ro \
		alpine sh -c "rm -rf /target/* && tar xzf /backup/ai-cli-config-backup.tar.gz -C /target"
	@echo "Config restored from ai-cli-config-backup.tar.gz"

# =============================================================================
# Compose Targets
# =============================================================================

## compose-up: Start with docker-compose
compose-up:
	docker-compose up -d

## compose-down: Stop with docker-compose
compose-down:
	docker-compose down

## compose-shell: Shell into docker-compose container
compose-shell:
	docker-compose exec ai-tools bash

# =============================================================================
# Help
# =============================================================================

## help: Show this help message
help:
	@echo ""
	@echo "AI CLI Tools Container"
	@echo "======================"
	@echo ""
	@echo "Available targets:"
	@echo ""
	@grep -E '^## ' $(MAKEFILE_LIST) | sed 's/## /  /' | column -t -s ':'
	@echo ""
	@echo "Quick Start:"
	@echo "  make build    # Build the container image"
	@echo "  make run      # Start interactive shell with current dir mounted"
	@echo "  make shell    # Attach to running container or start new"
	@echo ""
	@echo "Environment:"
	@echo "  WORKSPACE_DIR  Current: $(WORKSPACE_DIR)"
	@echo "  CONFIG_VOLUME  Current: $(CONFIG_VOLUME)"
	@echo ""

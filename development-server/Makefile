PROJECT_DIRS := $(wildcard */)
COMPOSE_FILES := $(foreach dir, $(PROJECT_DIRS), $(wildcard $(dir)/docker-compose.*.yml))

COMPOSE=docker compose
FILES=$(foreach file, $(COMPOSE_FILES), -f $(file))

.PHONY: up down restart logs ps project destroy network

up:
	@echo "🚀 Starting all projects..."
	$(COMPOSE) $(FILES) up -d --build

down:
	@echo "🛑 Stopping all projects..."
	$(COMPOSE) $(FILES) down

restart:
	@echo "🔁 Restarting all projects..."
	$(COMPOSE) $(FILES) restart

logs:
	@echo "📋 Tailing logs for all projects..."
	$(COMPOSE) $(FILES) logs -f

ps:
	@echo "📦 Listing running containers..."
	$(COMPOSE) $(FILES) ps

project: network
	@if [ -z "$(NAME)" ]; then \
		echo "❌ NAME is required: make project NAME=projectname [INDEX=0]"; \
		exit 1; \
	fi
	@echo "🔧 Generating project: $(NAME)"
	@./generate-project.sh $(NAME) --index=${INDEX:-0}

destroy:
	@if [ -z "$(NAME)" ]; then \
		echo "❌ NAME is required: make destroy NAME=projectname"; \
		exit 1; \
	fi
	@echo "🗑️  Removing project directory: $(NAME)"
	@rm -rf ./$(NAME)

network:
	@if ! docker network inspect development >/dev/null 2>&1; then \
		echo "🔧 Creating 'development' network..."; \
		docker network create development; \
	else \
		echo "✅ Network 'development' already exists."; \
	fi

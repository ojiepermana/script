COMPOSE=docker compose

.PHONY: up down restart logs ps project destroy

up:
	@echo "🚀 Starting root docker-compose.yml (Traefik or global services)..."
	@if [ -f docker-compose.yml ]; then \
	  $(COMPOSE) up -d --build; \
	else \
	  echo "⚠️  Root docker-compose.yml not found."; \
	fi

	@echo "🚀 Starting all project docker-compose files..."
	@for name in $$(find . -maxdepth 1 -type d -not -path '.' | sed 's|^./||'); do \
	  FILE=$$name/docker-compose.$$name.yml; \
	  if [ -f $$FILE ]; then \
	    echo "▶️  Starting project: $$name"; \
	    $(COMPOSE) -p $$name -f $$FILE up -d --build; \
	  else \
	    echo "⚠️  Compose file not found for $$name at $$FILE"; \
	  fi; \
	done

down:
	@echo "🛑 Stopping all project docker-compose files..."
	@for name in $$(find . -maxdepth 1 -type d -not -path '.' | sed 's|^./||'); do \
	  FILE=$$name/docker-compose.$$name.yml; \
	  if [ -f $$FILE ]; then \
	    echo "⏹️  Stopping project: $$name"; \
	    $(COMPOSE) -p $$name -f $$FILE down; \
	  fi; \
	done

	@echo "🛑 Stopping root docker-compose.yml..."
	@if [ -f docker-compose.yml ]; then \
	  $(COMPOSE) down; \
	else \
	  echo "⚠️  Root docker-compose.yml not found."; \
	fi

restart:
	@echo "🔁 Restarting all containers..."
	@make down && make up

logs:
	@echo "📋 Tailing logs for root or first project..."
	@$(COMPOSE) -f $(firstword $(shell find . -name 'docker-compose.*.yml')) logs -f

ps:
	@echo "📦 Listing running containers..."
	@docker ps

project:
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
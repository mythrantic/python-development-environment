.PHONY: help dev stop clean install check logs docker-up docker-down docker-rebuild

# Colors for output
BLUE := \033[0;34m
GREEN := \033[0;32m
YELLOW := \033[0;33m
NC := \033[0m # No Color

# Local development URLs (override production URLs in .env files)
LOCAL_POCKETBASE_URL := http://localhost:8090

help: ## Show this help message
	@echo "$(BLUE)Receipt OCR Development Commands$(NC)"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "$(GREEN)%-20s$(NC) %s\n", $$1, $$2}'

model_push: ### go to models/ and for each folder, git add, commit, push
	@echo "$(BLUE)Pushing model changes...$(NC)"
	@cd models && for dir in */ ; do \
		echo "$(YELLOW)Processing model directory: $$dir$(NC)"; \
		cd "$$dir" && \
		git add . && \
		git commit -m "Update model files" || echo "No changes to commit in $$dir" && \
		git push || echo "Failed to push changes in $$dir" && \
		cd .. ; \
	done
	@echo "$(GREEN)Model push complete$(NC)"

model_pull: ### go to models/ and for each folder, git pull
	@echo "$(BLUE)Pulling model changes...$(NC)"
	@cd models && for dir in */ ; do \
		echo "$(YELLOW)Processing model directory: $$dir$(NC)"; \
		cd "$$dir" && \
		git pull || echo "Failed to pull changes in $$dir" && \
		cd .. ; \
	done
	@echo "$(GREEN)Model pull complete$(NC)"

dataset_push: ### go to datasets/ and for each folder, git add, commit, push
	@echo "$(BLUE)Pushing dataset changes...$(NC)"
	@cd datasets && for dir in */ ; do \
		echo "$(YELLOW)Processing dataset directory: $$dir$(NC)"; \
		cd "$$dir" && \
		git add . && \
		git commit -m "Update dataset files" || echo "No changes to commit in $$dir" && \
		git push || echo "Failed to push changes in $$dir" && \
		cd .. ; \
	done
	@echo "$(GREEN)Dataset push complete$(NC)"

dataset_pull: ### go to datasets/ and for each folder, git pull
	@echo "$(BLUE)Pulling dataset changes...$(NC)"
	@cd datasets && for dir in */ ; do \
		echo "$(YELLOW)Processing dataset directory: $$dir$(NC)"; \
		cd "$$dir" && \
		git pull || echo "Failed to pull changes in $$dir" && \
		cd .. ; \
	done
	@echo "$(GREEN)Dataset pull complete$(NC)"

dev: ## Start development server (port 8002)
	@echo "$(BLUE)Starting on http://localhost:8002$(NC)" && \
		POCKETBASE_URL=$(LOCAL_POCKETBASE_URL) uv run uvicorn src.main:app --reload --host 0.0.0.0 --port 8002

install: ## Install dependencies (uv)
	@echo "$(BLUE)Installing dependencies...$(NC)"
	@uv sync
	@echo "$(GREEN)Downloading models and datasets...$(NC)"
	@make install_models
	@make install_datasets
	@echo "$(GREEN)Installation complete$(NC)"

install_models: ## go to models and git clone https://huggingface.co/mythrantic/sam3
	@echo "$(BLUE)Cloning model repositories...$(NC)"
	@cd models && \
		git clone https://huggingface.co/mythrantic/sam3;
	@echo "$(GREEN)Model repositories cloned$(NC)"

install_datasets: ## go to datasets and git clone https://huggingface.co/datasets/mythrantic/receipt-ocr-dataset
	@echo "$(BLUE)No dataset repositories to clone currently$(NC)"

check: ## Run tests
	@echo "$(BLUE)Testing...$(NC)"
	@uv run pytest

docker-up: ## Start all services with Docker Compose
	@echo "$(YELLOW)Starting Docker services...$(NC)"
	@docker-compose up -d
	@echo "$(GREEN)Service started:$(NC)"
	@echo "  URL:  http://localhost:5173"

docker-down: ## Stop all Docker services
	@echo "$(YELLOW)Stopping Docker services...$(NC)"
	@docker-compose down

docker-rebuild: ## Rebuild and restart Docker services
	@echo "$(YELLOW)Rebuilding Docker services...$(NC)"
	@docker-compose up -d --build

docker-logs: ## Show Docker logs (follow)
	@docker-compose logs -f

logs:
	@echo "$(YELLOW)Showing service logs...$(NC)"
	@echo "Use Ctrl+C to stop following logs"
	@tail -f logs/*.log 2>/dev/null || echo "No log files found"

clean: ## Clean build artifacts and caches
	@echo "$(YELLOW)Cleaning build artifacts...$(NC)"
	@rm -rf .pytest_cache __pycache__ **/__pycache__ .coverage htmlcov
	@docker compose down -v
	@echo "$(GREEN)Cleanup complete$(NC)"

clean-all: clean ## Clean everything including dependencies
	@echo "$(YELLOW)Removing all dependencies...$(NC)"
	@rm -rf .venv frontend/node_modules frontend/dist __pycache__ __marimo__
	@echo "$(GREEN)Full cleanup complete. Run 'make install' to reinstall.$(NC)"

# Development helpers
tmux-dev: ## Start all services in tmux session (uses window 4)
	@echo "$(YELLOW)Starting services in tmux...$(NC)"
	@if tmux has-session -t receipt_ocr 2>/dev/null; then \
		echo "$(GREEN)Session 'receipt_ocr' already exists. Attaching to window 4...$(NC)"; \
		tmux attach-session -t receipt_ocr:4; \
	else \
		if [ -f ~/.config/tmux/tmux.conf ] && grep -q "set-hook.*session-created" ~/.config/tmux/tmux.conf 2>/dev/null; then \
			echo "$(BLUE)Using custom tmux config (session-created hook detected)...$(NC)"; \
			tmux new-session -d -s receipt_ocr; \
			sleep 1; \
		else \
			echo "$(BLUE)Using standard tmux (no custom config detected)...$(NC)"; \
			tmux new-session -d -s receipt_ocr -n editor; \
			tmux send-keys -t receipt_ocr:1 'nvim .' C-m; \
			tmux new-window -t receipt_ocr:2 -n git; \
			tmux send-keys -t receipt_ocr:2 'lazygit' C-m; \
			tmux new-window -t receipt_ocr:3 -n yazi; \
			tmux send-keys -t receipt_ocr:3 'yazi' C-m; \
			tmux new-window -t receipt_ocr:4 -n terminal; \
			sleep 0.5; \
		fi; \
		tmux select-window -t receipt_ocr:4; \
		tmux send-keys -t receipt_ocr:4 'cd $(PWD) && make dev' C-m; \
		tmux select-layout -t receipt_ocr:4 even-horizontal; \
		tmux attach-session -t receipt_ocr:4; \
	fi

tmux-stop: ## Stop tmux development session
	@tmux kill-session -t receipt_ocr 2>/dev/null || echo "No tmux session found"
	@echo "$(GREEN)Tmux session stopped$(NC)"

tmux-attach: ## Attach to existing tmux session
	@tmux attach-session -t receipt_ocr

# Show current configuration
show-config: ## Show current environment configuration
	@echo "$(BLUE)Current Configuration:$(NC)"
	@echo ""
	@echo "$(YELLOW)Production (from .env files):$(NC)"
	@echo "  Receipt OCR URL:    $$(grep PUBLIC_API_BASE_URL .env | cut -d'=' -f2)"
	@echo ""
	@echo "$(YELLOW)Development (used by 'make dev' commands):$(NC)"
	@echo "  Receipt OCR URL:    $(LOCAL_API_URL)"

# Default target
.DEFAULT_GOAL := help
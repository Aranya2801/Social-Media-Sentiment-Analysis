# ─────────────────────────────────────────────────────────────────────────────
#  Social Media Sentiment Intelligence Platform — Makefile
# ─────────────────────────────────────────────────────────────────────────────

.PHONY: help up down restart logs build clean test lint format \
        db-init db-migrate download-models train-sentiment \
        train-emotion generate-report drift-report jupyter

SHELL := /bin/bash
PYTHON := python
PIP := pip
DOCKER_COMPOSE := docker-compose

# Colors
CYAN   := \033[0;36m
GREEN  := \033[0;32m
YELLOW := \033[0;33m
RED    := \033[0;31m
NC     := \033[0m

# ─── Help ─────────────────────────────────────────────────────────────────────
help:
	@echo ""
	@echo "$(CYAN)╔══════════════════════════════════════════════════════════════════╗$(NC)"
	@echo "$(CYAN)║    Social Media Sentiment Intelligence Platform — Commands        ║$(NC)"
	@echo "$(CYAN)╚══════════════════════════════════════════════════════════════════╝$(NC)"
	@echo ""
	@echo "$(GREEN)Docker Commands:$(NC)"
	@echo "  make up              Start all services"
	@echo "  make down            Stop all services"
	@echo "  make restart         Restart all services"
	@echo "  make logs            Follow all container logs"
	@echo "  make build           Build Docker images"
	@echo "  make clean           Remove containers, volumes, images"
	@echo ""
	@echo "$(GREEN)Database Commands:$(NC)"
	@echo "  make db-init         Initialize database and run migrations"
	@echo "  make db-migrate      Run pending migrations"
	@echo "  make db-reset        Drop and recreate database (DESTRUCTIVE)"
	@echo ""
	@echo "$(GREEN)ML Commands:$(NC)"
	@echo "  make download-models Download pre-trained transformer models"
	@echo "  make train-sentiment Fine-tune sentiment model"
	@echo "  make train-emotion   Fine-tune emotion model"
	@echo "  make evaluate-models Run model evaluation suite"
	@echo "  make drift-report    Generate data/model drift report"
	@echo ""
	@echo "$(GREEN)Development Commands:$(NC)"
	@echo "  make dev-backend     Start backend in dev mode"
	@echo "  make dev-frontend    Start frontend in dev mode"
	@echo "  make test            Run all tests"
	@echo "  make test-unit       Run unit tests only"
	@echo "  make test-cov        Run tests with coverage report"
	@echo "  make lint            Run linting checks"
	@echo "  make format          Auto-format code"
	@echo "  make jupyter         Start Jupyter Lab"
	@echo ""
	@echo "$(GREEN)Operations:$(NC)"
	@echo "  make generate-report Generate sample executive report"
	@echo "  make health-check    Check all service health endpoints"
	@echo "  make backup-db       Backup PostgreSQL database"
	@echo "  make load-sample     Load sample dataset for testing"
	@echo ""

# ─── Docker ───────────────────────────────────────────────────────────────────
up:
	@echo "$(CYAN)▶ Starting all SMSIP services...$(NC)"
	$(DOCKER_COMPOSE) up -d
	@echo "$(GREEN)✅ Services started$(NC)"
	@echo ""
	@echo "  Dashboard:    http://localhost:3000"
	@echo "  API Docs:     http://localhost:8000/docs"
	@echo "  MLflow:       http://localhost:5000"
	@echo "  Grafana:      http://localhost:3001"
	@echo "  Kafka UI:     http://localhost:8080"

down:
	@echo "$(CYAN)▶ Stopping all SMSIP services...$(NC)"
	$(DOCKER_COMPOSE) down
	@echo "$(GREEN)✅ Services stopped$(NC)"

restart:
	$(DOCKER_COMPOSE) restart

logs:
	$(DOCKER_COMPOSE) logs -f --tail=100

logs-backend:
	$(DOCKER_COMPOSE) logs -f backend --tail=200

build:
	@echo "$(CYAN)▶ Building Docker images...$(NC)"
	$(DOCKER_COMPOSE) build --no-cache
	@echo "$(GREEN)✅ Build complete$(NC)"

clean:
	@echo "$(RED)⚠ WARNING: This will remove all containers, volumes, and cached images$(NC)"
	@read -p "Continue? [y/N] " confirm && [ "$$confirm" = "y" ] || exit 1
	$(DOCKER_COMPOSE) down -v --remove-orphans
	docker system prune -f
	@echo "$(GREEN)✅ Cleanup complete$(NC)"

# ─── Database ─────────────────────────────────────────────────────────────────
db-init:
	@echo "$(CYAN)▶ Initializing database...$(NC)"
	$(DOCKER_COMPOSE) exec backend alembic upgrade head
	$(DOCKER_COMPOSE) exec backend python scripts/seed_database.py
	@echo "$(GREEN)✅ Database initialized$(NC)"

db-migrate:
	@echo "$(CYAN)▶ Creating migration...$(NC)"
	$(DOCKER_COMPOSE) exec backend alembic revision --autogenerate -m "auto migration"
	$(DOCKER_COMPOSE) exec backend alembic upgrade head

db-reset:
	@echo "$(RED)⚠ WARNING: This will DROP all data$(NC)"
	@read -p "Continue? [y/N] " confirm && [ "$$confirm" = "y" ] || exit 1
	$(DOCKER_COMPOSE) exec backend alembic downgrade base
	$(DOCKER_COMPOSE) exec backend alembic upgrade head
	@echo "$(GREEN)✅ Database reset$(NC)"

backup-db:
	@echo "$(CYAN)▶ Backing up database...$(NC)"
	@timestamp=$$(date +%Y%m%d_%H%M%S) && \
	$(DOCKER_COMPOSE) exec postgres pg_dump -U smsip smsip_db > backups/db_$$timestamp.sql
	@echo "$(GREEN)✅ Database backed up$(NC)"

# ─── ML Models ────────────────────────────────────────────────────────────────
download-models:
	@echo "$(CYAN)▶ Downloading pre-trained models (~8GB)...$(NC)"
	$(PYTHON) scripts/download_models.py \
		--models sentiment emotion sarcasm toxicity ner embedding
	@echo "$(GREEN)✅ Models downloaded to ./models/$(NC)"

train-sentiment:
	@echo "$(CYAN)▶ Fine-tuning sentiment model...$(NC)"
	$(PYTHON) ml/training/train_sentiment.py \
		--dataset combined \
		--epochs 5 \
		--batch-size 32 \
		--lr 2e-5 \
		--experiment-name "smsip-sentiment-$(shell date +%Y%m%d)"
	@echo "$(GREEN)✅ Training complete$(NC)"

train-emotion:
	@echo "$(CYAN)▶ Fine-tuning emotion model...$(NC)"
	$(PYTHON) ml/training/train_emotion.py \
		--dataset goemotions \
		--epochs 5 \
		--batch-size 32
	@echo "$(GREEN)✅ Emotion model trained$(NC)"

evaluate-models:
	@echo "$(CYAN)▶ Running model evaluation suite...$(NC)"
	$(PYTHON) ml/evaluation/evaluate_all.py \
		--output reports/model_evaluation_$(shell date +%Y%m%d).json
	@echo "$(GREEN)✅ Evaluation complete$(NC)"

drift-report:
	@echo "$(CYAN)▶ Generating drift report...$(NC)"
	$(PYTHON) scripts/detect_drift.py \
		--reference-data datasets/processed/sentiment/train.csv \
		--current-data datasets/processed/sentiment/recent.csv \
		--output reports/drift_$(shell date +%Y%m%d).html
	@echo "$(GREEN)✅ Drift report generated$(NC)"

# ─── Development ──────────────────────────────────────────────────────────────
dev-backend:
	@echo "$(CYAN)▶ Starting backend in dev mode...$(NC)"
	uvicorn backend.main:app --host 0.0.0.0 --port 8000 --reload --log-level debug

dev-frontend:
	@echo "$(CYAN)▶ Starting frontend in dev mode...$(NC)"
	cd frontend && npm run dev

install:
	@echo "$(CYAN)▶ Installing dependencies...$(NC)"
	$(PIP) install -r requirements.txt
	pre-commit install
	cd frontend && npm install
	@echo "$(GREEN)✅ Dependencies installed$(NC)"

# ─── Testing ──────────────────────────────────────────────────────────────────
test:
	@echo "$(CYAN)▶ Running all tests...$(NC)"
	pytest tests/ -v --tb=short -n auto

test-unit:
	pytest tests/unit/ -v --tb=short

test-integration:
	pytest tests/integration/ tests/api/ -v --tb=short

test-cov:
	@echo "$(CYAN)▶ Running tests with coverage...$(NC)"
	pytest tests/ \
		--cov=backend \
		--cov-report=html:htmlcov \
		--cov-report=term-missing \
		--cov-fail-under=80 \
		-n auto
	@echo "$(GREEN)✅ Coverage report: htmlcov/index.html$(NC)"

test-load:
	@echo "$(CYAN)▶ Running load tests...$(NC)"
	locust -f tests/load/locustfile.py \
		--host=http://localhost:8000 \
		--users=100 \
		--spawn-rate=10 \
		--run-time=60s \
		--headless

# ─── Code Quality ─────────────────────────────────────────────────────────────
lint:
	@echo "$(CYAN)▶ Running linters...$(NC)"
	ruff check backend/ ml/ scripts/
	cd frontend && npm run lint
	@echo "$(GREEN)✅ Lint passed$(NC)"

format:
	@echo "$(CYAN)▶ Formatting code...$(NC)"
	black backend/ ml/ scripts/
	ruff check backend/ ml/ scripts/ --fix
	cd frontend && npx prettier --write .
	@echo "$(GREEN)✅ Code formatted$(NC)"

type-check:
	mypy backend/ --ignore-missing-imports
	cd frontend && npm run type-check

security-scan:
	@echo "$(CYAN)▶ Running security scans...$(NC)"
	bandit -r backend/ -ll -ii
	safety check --file requirements.txt

# ─── Operations ───────────────────────────────────────────────────────────────
generate-report:
	@echo "$(CYAN)▶ Generating sample executive report...$(NC)"
	$(PYTHON) scripts/generate_sample_report.py \
		--brand "Sample Brand" \
		--output reports/generated/sample_report.pdf
	@echo "$(GREEN)✅ Report generated$(NC)"

health-check:
	@echo "$(CYAN)▶ Checking service health...$(NC)"
	@curl -sf http://localhost:8000/api/v1/health | python -m json.tool
	@echo "$(GREEN)✅ Backend healthy$(NC)"

load-sample:
	@echo "$(CYAN)▶ Loading sample dataset...$(NC)"
	$(PYTHON) scripts/load_sample_data.py \
		--file datasets/raw/sample/sample_tweets.csv \
		--platform twitter
	@echo "$(GREEN)✅ Sample data loaded$(NC)"

jupyter:
	@echo "$(CYAN)▶ Starting Jupyter Lab...$(NC)"
	jupyter lab --ip=0.0.0.0 --port=8888 --no-browser notebooks/

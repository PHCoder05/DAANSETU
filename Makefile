# DAANSETU Monorepo Makefile

.PHONY: help setup dev-backend dev-mobile test-backend test-mobile deploy infrastructure

help:
	@echo "Usage: make [target]"
	@echo ""
	@echo "Targets:"
	@echo "  setup            Install dependencies for all projects"
	@echo "  dev-backend      Start backend development server"
	@echo "  dev-mobile       Start mobile app"
	@echo "  test-backend     Run backend tests"
	@echo "  test-mobile      Run mobile tests"
	@echo "  docker-up        Start Docker containers (Backend + DB)"
	@echo "  docker-down      Stop Docker containers"
	@echo "  lint             Run linters"

setup:
	@echo "Installing Backend Dependencies..."
	cd backend && npm install
	@echo "Installing Mobile Dependencies..."
	cd mobile && flutter pub get
	@echo "Setup Complete!"

dev-backend:
	cd backend && npm run dev

dev-mobile:
	cd mobile && flutter run

test-backend:
	cd backend && npm test

test-mobile:
	cd mobile && flutter test

docker-up:
	docker-compose up -d

docker-down:
	docker-compose down

lint:
	cd backend && npm run lint
	cd mobile && flutter analyze

clean:
	cd backend && rm -rf node_modules coverage dist
	cd mobile && flutter clean

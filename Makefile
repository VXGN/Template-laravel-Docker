.PHONY: help build up down restart logs install composer artisan migrate seed fresh test bash mysql-cli redis-cli

help: ## Menampilkan bantuan
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

build: ## Build Docker containers
	docker-compose build --no-cache

up: ## Start Docker containers
	docker-compose up -d

down: ## Stop Docker containers
	docker-compose down

restart: ## Restart Docker containers
	docker-compose restart

logs: ## Lihat logs containers
	docker-compose logs -f

install: ## Install Laravel fresh (setelah build)
	docker-compose exec app composer create-project --prefer-dist laravel/laravel temp
	docker-compose exec app bash -c "shopt -s dotglob && mv temp/* temp/.* . 2>/dev/null || true"
	docker-compose exec app rm -rf temp
	docker-compose exec app php artisan key:generate
	docker-compose exec app php artisan storage:link
	docker-compose exec app chmod -R 775 storage bootstrap/cache

composer: ## Jalankan composer (usage: make composer CMD="install")
	docker-compose exec app composer $(CMD)

composer-install: ## Install composer dependencies
	docker-compose exec app composer install
	docker-compose exec app php artisan key:generate
	docker-compose exec app php artisan storage:link
	docker-compose exec app chmod -R 775 storage bootstrap/cache

artisan: ## Jalankan artisan command (usage: make artisan CMD="migrate")
	docker-compose exec app php artisan $(CMD)

migrate: ## Jalankan migrations
	docker-compose exec app php artisan migrate

seed: ## Jalankan database seeder
	docker-compose exec app php artisan db:seed

fresh: ## Fresh migration dengan seed
	docker-compose exec app php artisan migrate:fresh --seed

test: ## Jalankan tests
	docker-compose exec app php artisan test

bash: ## Masuk ke container app
	docker-compose exec app bash

mysql-cli: ## Masuk ke MySQL CLI
	docker-compose exec mysql mysql -u websevis_user -pwebsevis_secret_pass websevis_kampus

redis-cli: ## Masuk ke Redis CLI
	docker-compose exec redis redis-cli -a redis_secret_pass

clear-cache: ## Clear semua cache
	docker-compose exec app php artisan cache:clear
	docker-compose exec app php artisan config:clear
	docker-compose exec app php artisan route:clear
	docker-compose exec app php artisan view:clear

optimize: ## Optimize Laravel
	docker-compose exec app php artisan config:cache
	docker-compose exec app php artisan route:cache
	docker-compose exec app php artisan view:cache

permissions: ## Fix permissions
	docker-compose exec app chmod -R 775 storage bootstrap/cache
	docker-compose exec app chown -R www:www storage bootstrap/cache

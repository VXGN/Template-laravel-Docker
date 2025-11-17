.PHONY: help build up down restart logs install composer artisan migrate seed fresh test bash mysql-cli redis-cli model model-migration controller controller-resource migration resource view factory seeder request policy

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

# MVC Commands
model: ## Buat model (usage: make model NAME=Product)
	@if [ -z "$(NAME)" ]; then \
		echo "Error: NAME is required. Usage: make model NAME=Product"; \
		exit 1; \
	fi
	docker-compose exec app php artisan make:model $(NAME)

model-migration: ## Buat model dengan migration (usage: make model-migration NAME=Product)
	@if [ -z "$(NAME)" ]; then \
		echo "Error: NAME is required. Usage: make model-migration NAME=Product"; \
		exit 1; \
	fi
	docker-compose exec app php artisan make:model $(NAME) -m

controller: ## Buat controller (usage: make controller NAME=ProductController)
	@if [ -z "$(NAME)" ]; then \
		echo "Error: NAME is required. Usage: make controller NAME=ProductController"; \
		exit 1; \
	fi
	docker-compose exec app php artisan make:controller $(NAME)

controller-resource: ## Buat resource controller (usage: make controller-resource NAME=ProductController)
	@if [ -z "$(NAME)" ]; then \
		echo "Error: NAME is required. Usage: make controller-resource NAME=ProductController"; \
		exit 1; \
	fi
	docker-compose exec app php artisan make:controller $(NAME) --resource

migration: ## Buat migration (usage: make migration NAME=create_products_table)
	@if [ -z "$(NAME)" ]; then \
		echo "Error: NAME is required. Usage: make migration NAME=create_products_table"; \
		exit 1; \
	fi
	docker-compose exec app php artisan make:migration $(NAME)

resource: ## Buat full MVC resource dengan semua HTTP methods (usage: make resource NAME=Product)
	@if [ -z "$(NAME)" ]; then \
		echo "Error: NAME is required. Usage: make resource NAME=Product"; \
		exit 1; \
	fi
	@if [ -f "../Template-laravel-Docker/create-mvc-resource.sh" ]; then \
		bash ../Template-laravel-Docker/create-mvc-resource.sh $(NAME) .; \
	elif [ -f "./create-mvc-resource.sh" ]; then \
		bash ./create-mvc-resource.sh $(NAME) .; \
	else \
		echo "Error: create-mvc-resource.sh not found"; \
		exit 1; \
	fi

view: ## Buat view blade file (usage: make view NAME=products.index)
	@if [ -z "$(NAME)" ]; then \
		echo "Error: NAME is required. Usage: make view NAME=products.index"; \
		exit 1; \
	fi
	docker-compose exec app bash -c "mkdir -p resources/views/$$(dirname $(NAME)) && touch resources/views/$(NAME).blade.php"
	@echo "View created: resources/views/$(NAME).blade.php"

factory: ## Buat factory (usage: make factory NAME=ProductFactory MODEL=Product)
	@if [ -z "$(NAME)" ]; then \
		echo "Error: NAME is required. Usage: make factory NAME=ProductFactory MODEL=Product"; \
		exit 1; \
	fi
	@if [ -z "$(MODEL)" ]; then \
		docker-compose exec app php artisan make:factory $(NAME); \
	else \
		docker-compose exec app php artisan make:factory $(NAME) --model=$(MODEL); \
	fi

seeder: ## Buat seeder (usage: make seeder NAME=ProductSeeder)
	@if [ -z "$(NAME)" ]; then \
		echo "Error: NAME is required. Usage: make seeder NAME=ProductSeeder"; \
		exit 1; \
	fi
	docker-compose exec app php artisan make:seeder $(NAME)

request: ## Buat form request (usage: make request NAME=StoreProductRequest)
	@if [ -z "$(NAME)" ]; then \
		echo "Error: NAME is required. Usage: make request NAME=StoreProductRequest"; \
		exit 1; \
	fi
	docker-compose exec app php artisan make:request $(NAME)

policy: ## Buat policy (usage: make policy NAME=ProductPolicy)
	@if [ -z "$(NAME)" ]; then \
		echo "Error: NAME is required. Usage: make policy NAME=ProductPolicy"; \
		exit 1; \
	fi
	docker-compose exec app php artisan make:policy $(NAME)

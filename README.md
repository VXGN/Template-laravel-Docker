# Laravel Docker Template

Template untuk membuat project Laravel dengan Docker setup yang siap pakai.

## 🎯 Fitur

- **Laravel 10.x** dengan PHP 8.2
- **MySQL 8.0** dengan volume terpisah
- **Redis** untuk caching dan session
- **Nginx** sebagai web server
- **Volume terpisah** untuk setiap project (tidak tercampur)
- **Setup otomatis** dengan script
- **Siap untuk multiple projects**

## 📋 Persyaratan

- Docker
- Docker Compose
- Bash (untuk script otomatis)

## � Cara Membuat Project Baru

### Menggunakan Script (Recommended)

```bash
./create-laravel-project.sh nama-project-anda
```

**Contoh:**
```bash
./create-laravel-project.sh my-shop
./create-laravel-project.sh cms-website
./create-laravel-project.sh api-backend
```

Script akan otomatis:
1. ✅ Membuat folder project baru
2. ✅ Copy semua template files
3. ✅ Generate konfigurasi unik untuk project
4. ✅ Build Docker containers
5. ✅ Install Laravel
6. ✅ Setup database & migrations
7. ✅ Generate random passwords
8. ✅ Fix permissions

### Manual Setup

Jika ingin setup manual:

```bash
# 1. Copy folder ini dengan nama project baru
cp -r websevis-kampus my-new-project
cd my-new-project

# 2. Edit docker-compose.yml - ganti semua 'websevis_kampus' dengan nama project Anda

# 3. Edit .env - update DB_DATABASE, DB_USERNAME, passwords

# 4. Build & start
docker-compose build
docker-compose up -d

# 5. Install Laravel
docker-compose exec app composer create-project --prefer-dist laravel/laravel temp
docker-compose exec app bash -c "shopt -s dotglob && mv temp/* . 2>/dev/null; mv temp/.* . 2>/dev/null; rm -rf temp"
docker-compose exec app php artisan key:generate
docker-compose exec app php artisan storage:link
docker-compose exec app chmod -R 775 storage bootstrap/cache
docker-compose exec app php artisan migrate
```

## 📦 Struktur

```
websevis-kampus/                    # Template folder (ini)
├── create-laravel-project.sh       # Script untuk membuat project baru
├── docker-compose.yml              # Template Docker Compose
├── Dockerfile                      # Template Dockerfile
├── Makefile                        # Helper commands
└── docker/                         # Docker configs

../my-new-project/                  # Project baru hasil generate
├── docker-compose.yml              # Dengan nama volume unik
├── app/                            # Laravel application
└── ...
```

## 🎯 Contoh Multiple Projects

```bash
# Project 1: E-commerce
./create-laravel-project.sh ecommerce-shop

# Project 2: Blog  
./create-laravel-project.sh personal-blog

# Project 3: API
./create-laravel-project.sh rest-api
```

Setiap project memiliki volume Docker terpisah dan tidak tercampur!

## 🌐 Akses Aplikasi

- **Web Application**: http://localhost:8080
- **MySQL**: localhost:3307
- **Redis**: localhost:6380

### Kredensial Database

- **Host**: mysql (dari dalam container) atau localhost (dari host)
- **Port**: 3306 (dari dalam container) atau 3307 (dari host)
- **Database**: websevis_kampus
- **Username**: websevis_user
- **Password**: websevis_secret_pass

### Redis

- **Host**: redis (dari dalam container) atau localhost (dari host)
- **Port**: 6379 (dari dalam container) atau 6380 (dari host)
- **Password**: redis_secret_pass

## 📦 Volume yang Digunakan

Volume berikut dibuat dengan nama unik untuk project ini:

- `websevis_kampus_mysql_data` - Data MySQL
- `websevis_kampus_redis_data` - Data Redis
- `websevis_kampus_vendor` - Dependencies Composer

## 🛠️ Perintah Berguna

### Menggunakan Make

```bash
make help              # Menampilkan semua perintah
make up                # Start containers
make down              # Stop containers
make restart           # Restart containers
make logs              # Lihat logs
make bash              # Masuk ke container app
make mysql-cli         # Masuk ke MySQL CLI
make redis-cli         # Masuk ke Redis CLI
make migrate           # Jalankan migrations
make fresh             # Fresh migrations dengan seed
make clear-cache       # Clear semua cache
make optimize          # Optimize Laravel
```

### Menggunakan Docker Compose

```bash
# Start containers
docker-compose up -d

# Stop containers
docker-compose down

# Lihat logs
docker-compose logs -f

# Masuk ke container
docker-compose exec app bash

# Jalankan artisan commands
docker-compose exec app php artisan migrate
docker-compose exec app php artisan tinker

# Jalankan composer
docker-compose exec app composer install
docker-compose exec app composer update

# MySQL CLI
docker-compose exec mysql mysql -u websevis_user -pwebsevis_secret_pass websevis_kampus

# Redis CLI
docker-compose exec redis redis-cli -a redis_secret_pass
```

## 🧹 Membersihkan

### Stop dan hapus containers

```bash
docker-compose down
```

### Hapus containers dan volumes

```bash
docker-compose down -v
```

### Hapus semua (termasuk images)

```bash
docker-compose down -v --rmi all
```

## 🔍 Troubleshooting

### Permission Issues

Jika ada masalah permission:

```bash
docker-compose exec app chmod -R 775 storage bootstrap/cache
docker-compose exec app chown -R www:www storage bootstrap/cache
```

atau:

```bash
make permissions
```

### Clear Cache

```bash
docker-compose exec app php artisan cache:clear
docker-compose exec app php artisan config:clear
docker-compose exec app php artisan route:clear
docker-compose exec app php artisan view:clear
```

atau:

```bash
make clear-cache
```

### Rebuild Containers

```bash
docker-compose down
docker-compose build --no-cache
docker-compose up -d
```

## 🚀 Membuat MVC Resource dengan Semua HTTP Methods

Setelah project dibuat, Anda bisa menggunakan script `create-mvc-resource.sh` untuk membuat MVC resource lengkap dengan semua HTTP methods (GET, POST, PUT, PATCH, DELETE) dan SQLite untuk testing.

### Usage

```bash
# Dari dalam project directory
./create-mvc-resource.sh [ModelName] [project-path]

# Atau dari template directory
./create-mvc-resource.sh Product ../my-shop
./create-mvc-resource.sh User ../my-shop
```

**Contoh:**
```bash
cd ../my-shop
../Template-laravel-Docker/create-mvc-resource.sh Product
../Template-laravel-Docker/create-mvc-resource.sh Order
```

### Apa yang Dibuat Script?

Script ini akan otomatis membuat:

1. ✅ **Model** dengan fillable attributes
2. ✅ **Migration** dengan schema dasar (id, name, description, timestamps)
3. ✅ **Controller** dengan semua HTTP methods:
   - `index()` - GET /api/{resources} - List all dengan pagination & search
   - `store()` - POST /api/{resources} - Create new
   - `show()` - GET /api/{resources}/{id} - Show one
   - `update()` - PUT /api/{resources}/{id} - Update full
   - `patch()` - PATCH /api/{resources}/{id} - Update partial
   - `destroy()` - DELETE /api/{resources}/{id} - Delete
4. ✅ **Routes** di `routes/api.php` untuk semua methods
5. ✅ **Factory** dan **Seeder** untuk testing
6. ✅ **Test file** lengkap dengan semua test cases
7. ✅ **SQLite database** untuk testing (`database/database.sqlite`)

### Fitur Controller

- ✅ **Validation** dengan error handling
- ✅ **JSON Response** format yang konsisten
- ✅ **Search functionality** di index method
- ✅ **Pagination** di index method
- ✅ **Error handling** untuk not found
- ✅ **Partial update** dengan PATCH method

### API Endpoints yang Dibuat

Untuk model `Product`, script akan membuat:

```
GET    /api/products              - List all products (dengan pagination & search)
POST   /api/products              - Create new product
GET    /api/products/{id}         - Show one product
PUT    /api/products/{id}         - Update full product
PATCH  /api/products/{id}         - Update partial product
DELETE /api/products/{id}         - Delete product
```

### Testing dengan SQLite

Script otomatis:
- ✅ Membuat `database/database.sqlite`
- ✅ Mengkonfigurasi SQLite untuk testing
- ✅ Menjalankan migration dengan SQLite
- ✅ Membuat test file dengan SQLite in-memory database

### Contoh Response

**Success Response:**
```json
{
  "success": true,
  "data": { ... },
  "message": "Product created successfully"
}
```

**Error Response:**
```json
{
  "success": false,
  "errors": { ... },
  "message": "Product not found"
}
```

### Next Steps Setelah Script

1. **Edit Migration** - Tambahkan kolom sesuai kebutuhan:
   ```bash
   # Edit file migration di database/migrations/
   ```

2. **Edit Model** - Tambahkan relationships, casts, dll:
   ```php
   // app/Models/Product.php
   protected $fillable = ['name', 'description', 'price', 'stock'];
   ```

3. **Edit Controller** - Sesuaikan business logic:
   ```php
   // app/Http/Controllers/ProductController.php
   ```

4. **Jalankan Migration:**
   ```bash
   php artisan migrate:fresh --seed
   # atau dengan Docker:
   docker-compose exec app php artisan migrate:fresh --seed
   ```

5. **Jalankan Tests:**
   ```bash
   php artisan test --filter ProductTest
   # atau dengan Docker:
   docker-compose exec app php artisan test --filter ProductTest
   ```

## 📝 Catatan

- Port 8080 digunakan untuk web server (bisa diubah di docker-compose.yml)
- Port 3307 untuk MySQL (bisa diubah di docker-compose.yml)
- Port 6380 untuk Redis (bisa diubah di docker-compose.yml)
- Semua volume menggunakan prefix `websevis_kampus_` untuk menghindari konflik
- Password default ada di file `.env`, sebaiknya diganti untuk production

## 📄 Lisensi

Open-sourced software licensed under the [MIT license](https://opensource.org/licenses/MIT).

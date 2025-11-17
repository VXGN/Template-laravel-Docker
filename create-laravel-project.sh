#!/bin/bash

# Script untuk membuat project Laravel baru dengan Docker
# Usage: ./create-laravel-project.sh [nama-project]

# Warna untuk output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Fungsi untuk print dengan warna
print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

# Cek apakah nama project diberikan
if [ -z "$1" ]; then
    print_error "Nama project harus diberikan!"
    echo "Usage: ./create-laravel-project.sh [nama-project]"
    echo "Contoh: ./create-laravel-project.sh my-app"
    exit 1
fi

PROJECT_NAME=$1
PROJECT_DIR="../$PROJECT_NAME"
TEMPLATE_DIR="$(pwd)"

# Validasi nama project
if [[ ! $PROJECT_NAME =~ ^[a-zA-Z0-9_-]+$ ]]; then
    print_error "Nama project hanya boleh mengandung huruf, angka, underscore, dan dash!"
    exit 1
fi

# Cek apakah directory sudah ada
if [ -d "$PROJECT_DIR" ]; then
    print_error "Directory '$PROJECT_NAME' sudah ada!"
    exit 1
fi

print_info "Membuat project Laravel baru: $PROJECT_NAME"
echo ""

# Buat directory project
print_info "Membuat directory project..."
mkdir -p "$PROJECT_DIR"
cd "$PROJECT_DIR" || exit

# Copy template files
print_info "Menyalin template files..."
cp -r "$TEMPLATE_DIR/docker" .
cp "$TEMPLATE_DIR/Dockerfile" .
cp "$TEMPLATE_DIR/docker-compose.yml" .
cp "$TEMPLATE_DIR/.env.example" .
cp "$TEMPLATE_DIR/.gitignore" .
cp "$TEMPLATE_DIR/.dockerignore" .
cp "$TEMPLATE_DIR/Makefile" .

# Buat .env file
print_info "Membuat .env file..."
cp .env.example .env

# Update docker-compose.yml dengan nama project yang unik
print_info "Mengkonfigurasi Docker Compose untuk project '$PROJECT_NAME'..."
SAFE_PROJECT_NAME=$(echo "$PROJECT_NAME" | tr '-' '_')

sed -i "s/websevis_kampus/$SAFE_PROJECT_NAME/g" docker-compose.yml
sed -i "s/websevis_kampus/$SAFE_PROJECT_NAME/g" .env
sed -i "s/websevis_user/${SAFE_PROJECT_NAME}_user/g" .env
sed -i "s/DB_DATABASE=.*/DB_DATABASE=$SAFE_PROJECT_NAME/g" .env
sed -i "s/DB_USERNAME=.*/DB_USERNAME=${SAFE_PROJECT_NAME}_user/g" .env

# Generate random passwords
MYSQL_PASSWORD=$(openssl rand -base64 16 | tr -dc 'a-zA-Z0-9' | head -c 16)
REDIS_PASSWORD=$(openssl rand -base64 16 | tr -dc 'a-zA-Z0-9' | head -c 16)

sed -i "s/DB_PASSWORD=.*/DB_PASSWORD=$MYSQL_PASSWORD/g" .env
sed -i "s/REDIS_PASSWORD=.*/REDIS_PASSWORD=$REDIS_PASSWORD/g" .env
sed -i "s/APP_NAME=.*/APP_NAME=\"$PROJECT_NAME\"/g" .env

print_success "Konfigurasi selesai!"
echo ""

# Build Docker containers
print_info "Building Docker containers..."
docker-compose build --no-cache

if [ $? -ne 0 ]; then
    print_error "Build Docker gagal!"
    exit 1
fi

print_success "Docker containers berhasil di-build!"
echo ""

# Start containers
print_info "Starting Docker containers..."
docker-compose up -d

if [ $? -ne 0 ]; then
    print_error "Gagal menjalankan containers!"
    exit 1
fi

print_success "Docker containers berhasil dijalankan!"
echo ""

# Install Laravel
print_info "Menginstall Laravel..."
docker-compose exec -T app composer create-project --prefer-dist laravel/laravel temp

if [ $? -ne 0 ]; then
    print_error "Gagal menginstall Laravel!"
    docker-compose down
    exit 1
fi

docker-compose exec -T app bash -c "shopt -s dotglob && mv temp/* . 2>/dev/null && mv temp/.* . 2>/dev/null; rm -rf temp"

print_success "Laravel berhasil diinstall!"
echo ""

# Setup Laravel
print_info "Mengkonfigurasi Laravel..."

# Update .env Laravel dengan konfigurasi Docker
docker-compose exec -T app bash -c "cat > .env << 'EOF'
APP_NAME=\"$PROJECT_NAME\"
APP_ENV=local
APP_KEY=
APP_DEBUG=true
APP_URL=http://localhost:8080

LOG_CHANNEL=stack
LOG_DEPRECATIONS_CHANNEL=null
LOG_LEVEL=debug

DB_CONNECTION=mysql
DB_HOST=mysql
DB_PORT=3306
DB_DATABASE=$SAFE_PROJECT_NAME
DB_USERNAME=${SAFE_PROJECT_NAME}_user
DB_PASSWORD=$MYSQL_PASSWORD

BROADCAST_DRIVER=log
CACHE_DRIVER=redis
FILESYSTEM_DISK=local
QUEUE_CONNECTION=redis
SESSION_DRIVER=redis
SESSION_LIFETIME=120

REDIS_HOST=redis
REDIS_PASSWORD=$REDIS_PASSWORD
REDIS_PORT=6379

MAIL_MAILER=log
MAIL_HOST=127.0.0.1
MAIL_PORT=2525
MAIL_USERNAME=null
MAIL_PASSWORD=null
MAIL_ENCRYPTION=null
MAIL_FROM_ADDRESS=\"hello@example.com\"
MAIL_FROM_NAME=\"\${APP_NAME}\"
EOF
"

# Generate APP_KEY
print_info "Generate APP_KEY..."
docker-compose exec -T app php artisan key:generate

# Setup storage link
print_info "Setup storage link..."
docker-compose exec -T app php artisan storage:link

# Fix permissions
print_info "Fix permissions..."
docker-compose exec -T app chmod -R 775 storage bootstrap/cache
docker-compose exec -T app chown -R www:www storage bootstrap/cache

print_success "Laravel berhasil dikonfigurasi!"
echo ""

# Run migrations
print_info "Menjalankan migrations..."
docker-compose exec -T app php artisan migrate --force

print_success "Migrations berhasil dijalankan!"
echo ""

# Final message
echo "════════════════════════════════════════════════════════════"
print_success "Project '$PROJECT_NAME' berhasil dibuat!"
echo "════════════════════════════════════════════════════════════"
echo ""
echo "📁 Location: $PROJECT_DIR"
echo "🌐 URL: http://localhost:8080"
echo "🗄️  MySQL Port: 3307"
echo "🔴 Redis Port: 6380"
echo ""
echo "Database Credentials:"
echo "  - Database: $SAFE_PROJECT_NAME"
echo "  - Username: ${SAFE_PROJECT_NAME}_user"
echo "  - Password: $MYSQL_PASSWORD"
echo ""
echo "Redis Password: $REDIS_PASSWORD"
echo ""
echo "Perintah berguna:"
echo "  cd $PROJECT_DIR"
echo "  make help           # Lihat semua perintah"
echo "  make logs           # Lihat logs"
echo "  make bash           # Masuk ke container"
echo "  docker-compose down # Stop containers"
echo ""
print_success "Selamat coding! 🚀"

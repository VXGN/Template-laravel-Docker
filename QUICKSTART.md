# 🚀 QUICK START

## Membuat Project Laravel Baru

```bash
./create-laravel-project.sh nama-project
```

atau gunakan interactive mode:

```bash
./quick-start.sh
```

## Contoh

```bash
# Buat project e-commerce
./create-laravel-project.sh toko-online

# Buat project blog
./create-laravel-project.sh blog-saya

# Buat project API
./create-laravel-project.sh api-backend
```

## Setelah Project Dibuat

```bash
# Masuk ke project
cd ../nama-project

# Lihat status
docker-compose ps

# Lihat logs
make logs

# Masuk ke container
make bash

# Jalankan migrations
make migrate

# Stop containers
docker-compose down
```

## Multiple Projects Bersamaan

Untuk menjalankan beberapa project sekaligus, edit `docker-compose.yml` di setiap project dan ubah portnya:

**Project 1:**
```yaml
nginx:
  ports:
    - "8080:80"
```

**Project 2:**
```yaml
nginx:
  ports:
    - "8081:80"
```

**Project 3:**
```yaml
nginx:
  ports:
    - "8082:80"
```

Lakukan hal yang sama untuk MySQL (3307→3308→3309) dan Redis (6380→6381→6382).

## Menghapus Project

```bash
cd ../nama-project
docker-compose down -v
cd ..
rm -rf nama-project
```

## Lihat README.md untuk dokumentasi lengkap

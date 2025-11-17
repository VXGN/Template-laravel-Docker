# MVC Resource Generator Guide

Script `create-mvc-resource.sh` untuk membuat MVC resource lengkap dengan semua HTTP methods dan SQLite untuk testing.

## Quick Start

```bash
# Dari dalam project directory
./create-mvc-resource.sh Product

# Atau dari template directory
./create-mvc-resource.sh Product ../my-shop
```

## Apa yang Dibuat?

### 1. Model
- File: `app/Models/{ModelName}.php`
- Dengan `$fillable` attributes (name, description)
- Siap untuk ditambahkan relationships

### 2. Migration
- File: `database/migrations/xxxx_create_{table}_table.php`
- Schema dasar: id, name, description, timestamps
- **Edit manual** untuk menambahkan kolom sesuai kebutuhan

### 3. Controller (Resource Controller)
- File: `app/Http/Controllers/{ModelName}Controller.php`
- Semua HTTP methods:
  - `index()` - GET /api/{resources} - List dengan pagination & search
  - `store()` - POST /api/{resources} - Create
  - `show()` - GET /api/{resources}/{id} - Show one
  - `update()` - PUT /api/{resources}/{id} - Full update
  - `patch()` - PATCH /api/{resources}/{id} - Partial update
  - `destroy()` - DELETE /api/{resources}/{id} - Delete

### 4. Routes
- Ditambahkan ke `routes/api.php`
- Semua routes untuk CRUD operations

### 5. Factory & Seeder
- Factory: `database/factories/{ModelName}Factory.php`
- Seeder: `database/seeders/{ModelName}Seeder.php`

### 6. Test File
- File: `tests/Feature/{ModelName}Test.php`
- Test cases untuk semua HTTP methods
- Menggunakan SQLite in-memory untuk testing

### 7. SQLite Database
- File: `database/database.sqlite`
- Dikonfigurasi untuk testing
- Migration dijalankan otomatis

## API Endpoints

Setelah script dijalankan untuk model `Product`:

```
GET    /api/products              - List all (dengan ?search=keyword&per_page=15)
POST   /api/products              - Create new
GET    /api/products/{id}         - Show one
PUT    /api/products/{id}         - Update full
PATCH  /api/products/{id}         - Update partial
DELETE /api/products/{id}         - Delete
```

## Request/Response Examples

### Create Product
```bash
POST /api/products
Content-Type: application/json

{
  "name": "Laptop",
  "description": "Gaming laptop"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Product created successfully",
  "data": {
    "id": 1,
    "name": "Laptop",
    "description": "Gaming laptop",
    "created_at": "2024-01-01T00:00:00.000000Z",
    "updated_at": "2024-01-01T00:00:00.000000Z"
  }
}
```

### List Products (dengan search & pagination)
```bash
GET /api/products?search=laptop&per_page=10
```

**Response:**
```json
{
  "success": true,
  "data": {
    "current_page": 1,
    "data": [
      {
        "id": 1,
        "name": "Laptop",
        "description": "Gaming laptop",
        ...
      }
    ],
    "per_page": 10,
    "total": 1
  }
}
```

### Update Product (PUT - Full Update)
```bash
PUT /api/products/1
Content-Type: application/json

{
  "name": "Updated Laptop",
  "description": "Updated description"
}
```

### Partial Update (PATCH)
```bash
PATCH /api/products/1
Content-Type: application/json

{
  "name": "New Name Only"
}
```

### Delete Product
```bash
DELETE /api/products/1
```

## Customization

### 1. Edit Migration
Tambahkan kolom sesuai kebutuhan:
```php
// database/migrations/xxxx_create_products_table.php
Schema::create('products', function (Blueprint $table) {
    $table->id();
    $table->string('name');
    $table->text('description')->nullable();
    $table->decimal('price', 10, 2);  // Tambahkan ini
    $table->integer('stock');          // Tambahkan ini
    $table->timestamps();
});
```

### 2. Update Model Fillable
```php
// app/Models/Product.php
protected $fillable = [
    'name',
    'description',
    'price',    // Tambahkan
    'stock',    // Tambahkan
];
```

### 3. Update Controller Validation
```php
// app/Http/Controllers/ProductController.php
$validator = Validator::make($request->all(), [
    'name' => 'required|string|max:255',
    'description' => 'nullable|string',
    'price' => 'required|numeric|min:0',  // Tambahkan
    'stock' => 'required|integer|min:0',   // Tambahkan
]);
```

### 4. Add Relationships
```php
// app/Models/Product.php
public function category()
{
    return $this->belongsTo(Category::class);
}

// app/Models/Category.php
public function products()
{
    return $this->hasMany(Product::class);
}
```

## Testing

### Run All Tests
```bash
php artisan test
# atau dengan Docker:
docker-compose exec app php artisan test
```

### Run Specific Test
```bash
php artisan test --filter ProductTest
# atau dengan Docker:
docker-compose exec app php artisan test --filter ProductTest
```

### Test dengan SQLite
Tests otomatis menggunakan SQLite in-memory database, jadi tidak perlu setup database terpisah.

## Troubleshooting

### Migration Gagal
Jika migration gagal, pastikan:
1. SQLite database sudah dibuat: `database/database.sqlite`
2. File permission benar: `chmod 664 database/database.sqlite`
3. Jalankan manual: `php artisan migrate --force`

### Python Tidak Tersedia
Jika Python tidak tersedia untuk edit migration otomatis, script akan memberikan instruksi untuk edit manual. Migration file tetap dibuat, hanya perlu edit manual kolom-kolomnya.

### Route Tidak Ditemukan
Pastikan:
1. Routes sudah ditambahkan ke `routes/api.php`
2. API routes sudah diaktifkan di `RouteServiceProvider`
3. Clear route cache: `php artisan route:clear`

## Tips

1. **Gunakan Resource Classes** untuk response formatting yang konsisten
2. **Tambahkan Authorization** dengan Policies atau Gates
3. **Gunakan Form Requests** untuk validation yang lebih kompleks
4. **Tambahkan API Resources** untuk transform response
5. **Gunakan Events & Listeners** untuk business logic yang kompleks

## Next Steps

Setelah resource dibuat:
1. ✅ Edit migration untuk menambahkan kolom
2. ✅ Update model fillable
3. ✅ Customize controller logic
4. ✅ Add relationships
5. ✅ Add validation rules
6. ✅ Add authorization
7. ✅ Write additional tests
8. ✅ Add API documentation

Happy Coding! 🚀


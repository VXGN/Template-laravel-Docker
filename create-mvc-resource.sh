#!/bin/bash

# Script untuk membuat MVC resource lengkap dengan semua HTTP methods
# Usage: ./create-mvc-resource.sh [model-name] [project-path]
# Example: ./create-mvc-resource.sh Product ../my-shop

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

# Cek apakah nama model diberikan
if [ -z "$1" ]; then
    print_error "Nama model harus diberikan!"
    echo "Usage: ./create-mvc-resource.sh [model-name] [project-path]"
    echo "Contoh: ./create-mvc-resource.sh Product ../my-shop"
    echo "        ./create-mvc-resource.sh User ../my-shop"
    exit 1
fi

MODEL_NAME=$1
PROJECT_PATH=${2:-"../$(basename $(pwd))"}

# Validasi nama model
if [[ ! $MODEL_NAME =~ ^[A-Z][a-zA-Z0-9]*$ ]]; then
    print_error "Nama model harus PascalCase dan dimulai dengan huruf besar!"
    echo "Contoh: Product, User, OrderItem"
    exit 1
fi

# Convert model name ke berbagai format
MODEL_LOWER=$(echo "$MODEL_NAME" | tr '[:upper:]' '[:lower:]')
MODEL_PLURAL="${MODEL_LOWER}s"
CONTROLLER_NAME="${MODEL_NAME}Controller"
TABLE_NAME="${MODEL_PLURAL}"

# Cek apakah project directory ada
if [ ! -d "$PROJECT_PATH" ]; then
    print_error "Project directory tidak ditemukan: $PROJECT_PATH"
    echo "Pastikan path project benar atau jalankan script dari dalam project directory"
    exit 1
fi

# Cek apakah ini project Laravel
if [ ! -f "$PROJECT_PATH/artisan" ]; then
    print_error "Directory '$PROJECT_PATH' bukan project Laravel!"
    exit 1
fi

print_info "Membuat MVC resource untuk: $MODEL_NAME"
print_info "Project path: $PROJECT_PATH"
echo ""

cd "$PROJECT_PATH" || exit

# Cek apakah menggunakan Docker
USE_DOCKER=false
if [ -f "docker-compose.yml" ]; then
    USE_DOCKER=true
    print_info "Mendeteksi Docker setup, menggunakan docker-compose exec"
fi

# Fungsi untuk menjalankan artisan command
run_artisan() {
    if [ "$USE_DOCKER" = true ]; then
        docker-compose exec -T app php artisan "$@"
    else
        php artisan "$@"
    fi
}

# Fungsi untuk menjalankan command di container
run_in_container() {
    if [ "$USE_DOCKER" = true ]; then
        docker-compose exec -T app "$@"
    else
        "$@"
    fi
}

# 1. Setup SQLite untuk testing
print_info "Mengkonfigurasi SQLite untuk testing..."

# Backup .env jika belum ada backup
if [ ! -f ".env.backup" ]; then
    cp .env .env.backup
    print_info "Backup .env dibuat"
fi

# Update .env untuk menggunakan SQLite (temporary untuk migration)
# Simpan DB_CONNECTION asli
if [ "$USE_DOCKER" = true ]; then
    ORIGINAL_DB=$(docker-compose exec -T app grep "^DB_CONNECTION=" .env | cut -d'=' -f2)
else
    ORIGINAL_DB=$(grep "^DB_CONNECTION=" .env | cut -d'=' -f2)
fi

# Tambahkan konfigurasi SQLite untuk testing (jika belum ada)
if ! grep -q "DB_CONNECTION_TESTING" .env 2>/dev/null; then
    if [ "$USE_DOCKER" = true ]; then
        docker-compose exec -T app bash -c "echo '' >> .env && echo '# SQLite for Testing' >> .env && echo 'DB_CONNECTION_TESTING=sqlite' >> .env && echo 'DB_DATABASE_TESTING=/var/www/html/database/database.sqlite' >> .env"
    else
        echo "" >> .env
        echo "# SQLite for Testing" >> .env
        echo "DB_CONNECTION_TESTING=sqlite" >> .env
        echo "DB_DATABASE_TESTING=database/database.sqlite" >> .env
    fi
fi

# Buat database.sqlite jika belum ada
DB_PATH="database/database.sqlite"
if [ "$USE_DOCKER" = true ]; then
    docker-compose exec -T app touch "$DB_PATH"
    docker-compose exec -T app chmod 664 "$DB_PATH"
else
    touch "$DB_PATH"
    chmod 664 "$DB_PATH"
fi

print_success "SQLite database dibuat: $DB_PATH"

# 2. Buat Migration
print_info "Membuat migration untuk $TABLE_NAME..."
run_artisan make:migration "create_${TABLE_NAME}_table" --create="$TABLE_NAME"

if [ $? -ne 0 ]; then
    print_error "Gagal membuat migration!"
    exit 1
fi

# Dapatkan nama file migration terbaru
MIGRATION_FILE=$(run_in_container find database/migrations -name "*_create_${TABLE_NAME}_table.php" | sort | tail -1)

if [ -z "$MIGRATION_FILE" ]; then
    print_error "Migration file tidak ditemukan!"
    exit 1
fi

print_success "Migration dibuat: $MIGRATION_FILE"

# 3. Edit Migration file untuk menambahkan kolom dasar
print_info "Menambahkan kolom dasar ke migration..."

# Buat schema template dengan here-document
SCHEMA_CONTENT="            \$table->id();
            \$table->string('name');
            \$table->text('description')->nullable();
            \$table->timestamps();"

# Update migration file dengan schema menggunakan Python untuk reliability
PYTHON_SCRIPT="
import re
import sys

file_path = sys.argv[1]
schema = '''$SCHEMA_CONTENT'''

with open(file_path, 'r') as f:
    content = f.read()

# Replace the Schema::create block
pattern = r'(Schema::create\([^)]+\)[^{]*\{)([^}]*)(\s*\}\);)'
replacement = r'\1\n' + schema + r'\n\3'

new_content = re.sub(pattern, replacement, content, flags=re.DOTALL)

with open(file_path, 'w') as f:
    f.write(new_content)
"

if [ "$USE_DOCKER" = true ]; then
    echo "$PYTHON_SCRIPT" | docker-compose exec -T app python3 - "$MIGRATION_FILE" 2>/dev/null || {
        print_warning "Gagal mengedit migration secara otomatis. Silakan edit manual: $MIGRATION_FILE"
        print_info "Tambahkan kolom berikut di dalam Schema::create:"
        echo "  \$table->id();"
        echo "  \$table->string('name');"
        echo "  \$table->text('description')->nullable();"
        echo "  \$table->timestamps();"
    }
else
    echo "$PYTHON_SCRIPT" | python3 - "$MIGRATION_FILE" 2>/dev/null || {
        print_warning "Gagal mengedit migration secara otomatis. Silakan edit manual: $MIGRATION_FILE"
        print_info "Tambahkan kolom berikut di dalam Schema::create:"
        echo "  \$table->id();"
        echo "  \$table->string('name');"
        echo "  \$table->text('description')->nullable();"
        echo "  \$table->timestamps();"
    }
fi

print_success "Schema migration diupdate (atau perlu edit manual)"

# 4. Buat Model
print_info "Membuat model $MODEL_NAME..."
run_artisan make:model "$MODEL_NAME"

if [ $? -ne 0 ]; then
    print_error "Gagal membuat model!"
    exit 1
fi

MODEL_FILE="app/Models/$MODEL_NAME.php"
if [ ! -f "$MODEL_FILE" ]; then
    MODEL_FILE="app/$MODEL_NAME.php"
fi

print_success "Model dibuat: $MODEL_FILE"

# Update Model dengan fillable dan relationships
print_info "Mengupdate model dengan fillable attributes..."

MODEL_CONTENT=$(run_in_container cat "$MODEL_FILE")

# Tambahkan fillable jika belum ada
if ! echo "$MODEL_CONTENT" | grep -q "protected \$fillable"; then
    if [ "$USE_DOCKER" = true ]; then
        docker-compose exec -T app bash -c "sed -i '/protected \$table/a\\
    protected \$fillable = [\\
        '\''name'\'',\\
        '\''description'\'',\\
    ];' \"$MODEL_FILE\""
    else
        if [[ "$OSTYPE" == "darwin"* ]]; then
            sed -i '' '/protected \$table/a\
    protected $fillable = [
        '\''name'\'',
        '\''description'\'',
    ];' "$MODEL_FILE"
        else
            sed -i '/protected \$table/a\
    protected $fillable = [
        '\''name'\'',
        '\''description'\'',
    ];' "$MODEL_FILE"
        fi
    fi
fi

print_success "Model diupdate dengan fillable attributes"

# 5. Buat Controller dengan semua HTTP methods
print_info "Membuat controller $CONTROLLER_NAME dengan semua HTTP methods..."
run_artisan make:controller "$CONTROLLER_NAME" --resource

if [ $? -ne 0 ]; then
    print_error "Gagal membuat controller!"
    exit 1
fi

CONTROLLER_FILE="app/Http/Controllers/$CONTROLLER_NAME.php"
print_success "Controller dibuat: $CONTROLLER_FILE"

# Update Controller dengan implementasi lengkap
print_info "Mengupdate controller dengan implementasi CRUD lengkap..."

# Baca controller file
CONTROLLER_CONTENT=$(run_in_container cat "$CONTROLLER_FILE")

# Buat controller content baru dengan semua methods
NEW_CONTROLLER_CONTENT="<?php

namespace App\Http\Controllers;

use App\Models\\$MODEL_NAME;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Validator;

class ${CONTROLLER_NAME} extends Controller
{
    /**
     * Display a listing of the resource.
     */
    public function index(Request \$request): JsonResponse
    {
        \$query = ${MODEL_NAME}::query();

        // Search functionality
        if (\$request->has('search')) {
            \$search = \$request->get('search');
            \$query->where('name', 'like', \"%{\$search}%\")
                  ->orWhere('description', 'like', \"%{\$search}%\");
        }

        // Pagination
        \$perPage = \$request->get('per_page', 15);
        \$${MODEL_PLURAL} = \$query->paginate(\$perPage);

        return response()->json([
            'success' => true,
            'data' => \$${MODEL_PLURAL}
        ]);
    }

    /**
     * Store a newly created resource in storage.
     */
    public function store(Request \$request): JsonResponse
    {
        \$validator = Validator::make(\$request->all(), [
            'name' => 'required|string|max:255',
            'description' => 'nullable|string',
        ]);

        if (\$validator->fails()) {
            return response()->json([
                'success' => false,
                'errors' => \$validator->errors()
            ], 422);
        }

        \$${MODEL_LOWER} = ${MODEL_NAME}::create(\$request->all());

        return response()->json([
            'success' => true,
            'message' => '${MODEL_NAME} created successfully',
            'data' => \$${MODEL_LOWER}
        ], 201);
    }

    /**
     * Display the specified resource.
     */
    public function show(string \$id): JsonResponse
    {
        \$${MODEL_LOWER} = ${MODEL_NAME}::find(\$id);

        if (!\$${MODEL_LOWER}) {
            return response()->json([
                'success' => false,
                'message' => '${MODEL_NAME} not found'
            ], 404);
        }

        return response()->json([
            'success' => true,
            'data' => \$${MODEL_LOWER}
        ]);
    }

    /**
     * Update the specified resource in storage.
     */
    public function update(Request \$request, string \$id): JsonResponse
    {
        \$${MODEL_LOWER} = ${MODEL_NAME}::find(\$id);

        if (!\$${MODEL_LOWER}) {
            return response()->json([
                'success' => false,
                'message' => '${MODEL_NAME} not found'
            ], 404);
        }

        \$validator = Validator::make(\$request->all(), [
            'name' => 'sometimes|required|string|max:255',
            'description' => 'nullable|string',
        ]);

        if (\$validator->fails()) {
            return response()->json([
                'success' => false,
                'errors' => \$validator->errors()
            ], 422);
        }

        \$${MODEL_LOWER}->update(\$request->all());

        return response()->json([
            'success' => true,
            'message' => '${MODEL_NAME} updated successfully',
            'data' => \$${MODEL_LOWER}
        ]);
    }

    /**
     * Remove the specified resource from storage.
     */
    public function destroy(string \$id): JsonResponse
    {
        \$${MODEL_LOWER} = ${MODEL_NAME}::find(\$id);

        if (!\$${MODEL_LOWER}) {
            return response()->json([
                'success' => false,
                'message' => '${MODEL_NAME} not found'
            ], 404);
        }

        \$${MODEL_LOWER}->delete();

        return response()->json([
            'success' => true,
            'message' => '${MODEL_NAME} deleted successfully'
        ]);
    }

    /**
     * Partial update (PATCH method).
     */
    public function patch(Request \$request, string \$id): JsonResponse
    {
        \$${MODEL_LOWER} = ${MODEL_NAME}::find(\$id);

        if (!\$${MODEL_LOWER}) {
            return response()->json([
                'success' => false,
                'message' => '${MODEL_NAME} not found'
            ], 404);
        }

        \$validator = Validator::make(\$request->all(), [
            'name' => 'sometimes|string|max:255',
            'description' => 'nullable|string',
        ]);

        if (\$validator->fails()) {
            return response()->json([
                'success' => false,
                'errors' => \$validator->errors()
            ], 422);
        }

        \$${MODEL_LOWER}->update(\$request->only(['name', 'description']));

        return response()->json([
            'success' => true,
            'message' => '${MODEL_NAME} partially updated successfully',
            'data' => \$${MODEL_LOWER}
        ]);
    }
}
"

# Write new controller content
if [ "$USE_DOCKER" = true ]; then
    echo "$NEW_CONTROLLER_CONTENT" | docker-compose exec -T app tee "$CONTROLLER_FILE" > /dev/null
else
    echo "$NEW_CONTROLLER_CONTENT" > "$CONTROLLER_FILE"
fi

print_success "Controller diupdate dengan semua HTTP methods"

# 6. Buat Routes
print_info "Menambahkan routes ke api.php..."

API_ROUTES_FILE="routes/api.php"

# Cek apakah route sudah ada
if run_in_container grep -q "${MODEL_PLURAL}" "$API_ROUTES_FILE"; then
    print_warning "Route untuk ${MODEL_PLURAL} sudah ada, melewati..."
else
    # Tambahkan routes
    ROUTES_TO_ADD="
// ${MODEL_NAME} Routes
Route::get('${MODEL_PLURAL}', [App\Http\Controllers\\${CONTROLLER_NAME}::class, 'index']);
Route::post('${MODEL_PLURAL}', [App\Http\Controllers\\${CONTROLLER_NAME}::class, 'store']);
Route::get('${MODEL_PLURAL}/{id}', [App\Http\Controllers\\${CONTROLLER_NAME}::class, 'show']);
Route::put('${MODEL_PLURAL}/{id}', [App\Http\Controllers\\${CONTROLLER_NAME}::class, 'update']);
Route::patch('${MODEL_PLURAL}/{id}', [App\Http\Controllers\\${CONTROLLER_NAME}::class, 'patch']);
Route::delete('${MODEL_PLURAL}/{id}', [App\Http\Controllers\\${CONTROLLER_NAME}::class, 'destroy']);"

    if [ "$USE_DOCKER" = true ]; then
        docker-compose exec -T app bash -c "echo '$ROUTES_TO_ADD' >> $API_ROUTES_FILE"
    else
        echo "$ROUTES_TO_ADD" >> "$API_ROUTES_FILE"
    fi

    print_success "Routes ditambahkan ke $API_ROUTES_FILE"
fi

# 7. Buat Factory dan Seeder (optional)
print_info "Membuat factory dan seeder untuk testing..."

run_artisan make:factory "${MODEL_NAME}Factory" --model="$MODEL_NAME" 2>/dev/null
run_artisan make:seeder "${MODEL_NAME}Seeder" 2>/dev/null

if [ $? -eq 0 ]; then
    print_success "Factory dan Seeder dibuat"
fi

# 8. Run Migration dengan SQLite
print_info "Menjalankan migration dengan SQLite..."

# Update .env sementara untuk menggunakan SQLite
if [ "$USE_DOCKER" = true ]; then
    docker-compose exec -T app bash -c "sed -i 's/^DB_CONNECTION=.*/DB_CONNECTION=sqlite/' .env"
    docker-compose exec -T app bash -c "sed -i 's|^DB_DATABASE=.*|DB_DATABASE=/var/www/html/database/database.sqlite|' .env"
else
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' 's/^DB_CONNECTION=.*/DB_CONNECTION=sqlite/' .env
        sed -i '' 's|^DB_DATABASE=.*|DB_DATABASE=database/database.sqlite|' .env
    else
        sed -i 's/^DB_CONNECTION=.*/DB_CONNECTION=sqlite/' .env
        sed -i 's|^DB_DATABASE=.*|DB_DATABASE=database/database.sqlite|' .env
    fi
fi

run_artisan migrate --force

MIGRATION_STATUS=$?

# Restore .env ke konfigurasi asli
if [ -n "$ORIGINAL_DB" ]; then
    if [ "$USE_DOCKER" = true ]; then
        docker-compose exec -T app bash -c "sed -i 's/^DB_CONNECTION=.*/DB_CONNECTION=$ORIGINAL_DB/' .env"
    else
        if [[ "$OSTYPE" == "darwin"* ]]; then
            sed -i '' "s/^DB_CONNECTION=.*/DB_CONNECTION=$ORIGINAL_DB/" .env
        else
            sed -i "s/^DB_CONNECTION=.*/DB_CONNECTION=$ORIGINAL_DB/" .env
        fi
    fi
fi

if [ $MIGRATION_STATUS -ne 0 ]; then
    print_warning "Migration gagal, pastikan database.sqlite sudah dibuat"
    print_info "Anda bisa menjalankan manual: php artisan migrate --force"
else
    print_success "Migration berhasil dijalankan dengan SQLite"
fi

# 9. Buat test file
print_info "Membuat test file..."

TEST_FILE="tests/Feature/${MODEL_NAME}Test.php"

TEST_CONTENT="<?php

namespace Tests\Feature;

use App\Models\\$MODEL_NAME;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class ${MODEL_NAME}Test extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        // Use SQLite for testing
        \$this->app['config']->set('database.default', 'sqlite');
        \$this->app['config']->set('database.connections.sqlite.database', ':memory:');
    }

    /** @test */
    public function it_can_list_all_${MODEL_PLURAL}()
    {
        ${MODEL_NAME}::factory()->count(3)->create();

        \$response = \$this->getJson('/api/${MODEL_PLURAL}');

        \$response->assertStatus(200)
                 ->assertJsonStructure([
                     'success',
                     'data' => [
                         'data' => [
                             '*' => ['id', 'name', 'description', 'created_at', 'updated_at']
                         ]
                     ]
                 ]);
    }

    /** @test */
    public function it_can_create_a_${MODEL_LOWER}()
    {
        \$data = [
            'name' => 'Test ${MODEL_NAME}',
            'description' => 'Test Description'
        ];

        \$response = \$this->postJson('/api/${MODEL_PLURAL}', \$data);

        \$response->assertStatus(201)
                 ->assertJson([
                     'success' => true,
                     'message' => '${MODEL_NAME} created successfully'
                 ]);

        \$this->assertDatabaseHas('${TABLE_NAME}', [
            'name' => 'Test ${MODEL_NAME}'
        ]);
    }

    /** @test */
    public function it_can_show_a_${MODEL_LOWER}()
    {
        \$${MODEL_LOWER} = ${MODEL_NAME}::factory()->create();

        \$response = \$this->getJson(\"/api/${MODEL_PLURAL}/{\$${MODEL_LOWER}->id}\");

        \$response->assertStatus(200)
                 ->assertJson([
                     'success' => true,
                     'data' => [
                         'id' => \$${MODEL_LOWER}->id,
                         'name' => \$${MODEL_LOWER}->name
                     ]
                 ]);
    }

    /** @test */
    public function it_can_update_a_${MODEL_LOWER}()
    {
        \$${MODEL_LOWER} = ${MODEL_NAME}::factory()->create();

        \$data = [
            'name' => 'Updated Name',
            'description' => 'Updated Description'
        ];

        \$response = \$this->putJson(\"/api/${MODEL_PLURAL}/{\$${MODEL_LOWER}->id}\", \$data);

        \$response->assertStatus(200)
                 ->assertJson([
                     'success' => true,
                     'message' => '${MODEL_NAME} updated successfully'
                 ]);

        \$this->assertDatabaseHas('${TABLE_NAME}', [
            'id' => \$${MODEL_LOWER}->id,
            'name' => 'Updated Name'
        ]);
    }

    /** @test */
    public function it_can_partially_update_a_${MODEL_LOWER}()
    {
        \$${MODEL_LOWER} = ${MODEL_NAME}::factory()->create(['name' => 'Original Name']);

        \$data = ['name' => 'Patched Name'];

        \$response = \$this->patchJson(\"/api/${MODEL_PLURAL}/{\$${MODEL_LOWER}->id}\", \$data);

        \$response->assertStatus(200)
                 ->assertJson([
                     'success' => true,
                     'message' => '${MODEL_NAME} partially updated successfully'
                 ]);

        \$this->assertDatabaseHas('${TABLE_NAME}', [
            'id' => \$${MODEL_LOWER}->id,
            'name' => 'Patched Name'
        ]);
    }

    /** @test */
    public function it_can_delete_a_${MODEL_LOWER}()
    {
        \$${MODEL_LOWER} = ${MODEL_NAME}::factory()->create();

        \$response = \$this->deleteJson(\"/api/${MODEL_PLURAL}/{\$${MODEL_LOWER}->id}\");

        \$response->assertStatus(200)
                 ->assertJson([
                     'success' => true,
                     'message' => '${MODEL_NAME} deleted successfully'
                 ]);

        \$this->assertDatabaseMissing('${TABLE_NAME}', [
            'id' => \$${MODEL_LOWER}->id
        ]);
    }

    /** @test */
    public function it_validates_required_fields_on_create()
    {
        \$response = \$this->postJson('/api/${MODEL_PLURAL}', []);

        \$response->assertStatus(422)
                 ->assertJsonValidationErrors(['name']);
    }
}
"

if [ "$USE_DOCKER" = true ]; then
    echo "$TEST_CONTENT" | docker-compose exec -T app tee "$TEST_FILE" > /dev/null
else
    echo "$TEST_CONTENT" > "$TEST_FILE"
fi

print_success "Test file dibuat: $TEST_FILE"

# Final message
echo ""
echo "════════════════════════════════════════════════════════════"
print_success "MVC Resource '$MODEL_NAME' berhasil dibuat!"
echo "════════════════════════════════════════════════════════════"
echo ""
echo "📁 Files yang dibuat:"
echo "  - Model: app/Models/$MODEL_NAME.php"
echo "  - Controller: app/Http/Controllers/$CONTROLLER_NAME.php"
echo "  - Migration: $MIGRATION_FILE"
echo "  - Routes: routes/api.php"
echo "  - Test: $TEST_FILE"
echo "  - Factory: database/factories/${MODEL_NAME}Factory.php"
echo "  - Seeder: database/seeders/${MODEL_NAME}Seeder.php"
echo ""
echo "🌐 API Endpoints:"
echo "  GET    /api/${MODEL_PLURAL}              - List all"
echo "  POST   /api/${MODEL_PLURAL}              - Create new"
echo "  GET    /api/${MODEL_PLURAL}/{id}         - Show one"
echo "  PUT    /api/${MODEL_PLURAL}/{id}         - Update full"
echo "  PATCH  /api/${MODEL_PLURAL}/{id}         - Update partial"
echo "  DELETE /api/${MODEL_PLURAL}/{id}         - Delete"
echo ""
echo "🗄️  Database:"
echo "  - SQLite: database/database.sqlite"
echo "  - Table: ${TABLE_NAME}"
echo ""
echo "🧪 Testing:"
echo "  php artisan test --filter ${MODEL_NAME}Test"
if [ "$USE_DOCKER" = true ]; then
    echo "  atau: docker-compose exec app php artisan test --filter ${MODEL_NAME}Test"
fi
echo ""
echo "📝 Next Steps:"
echo "  1. Edit migration file untuk menambahkan kolom sesuai kebutuhan"
echo "  2. Edit model untuk menambahkan relationships jika perlu"
echo "  3. Edit controller untuk menyesuaikan business logic"
echo "  4. Jalankan: php artisan migrate:fresh --seed"
echo ""
print_success "Selamat coding! 🚀"


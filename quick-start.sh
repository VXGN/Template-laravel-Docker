#!/bin/bash

# Quick Start Guide - Hapus file ini setelah dibaca

echo "════════════════════════════════════════════════════════════"
echo "🚀 LARAVEL DOCKER TEMPLATE - QUICK START"
echo "════════════════════════════════════════════════════════════"
echo ""
echo "Folder ini adalah TEMPLATE untuk membuat banyak project Laravel."
echo ""
echo "📝 CARA MEMBUAT PROJECT BARU:"
echo ""
echo "   ./create-laravel-project.sh nama-project"
echo ""
echo "📚 CONTOH:"
echo ""
echo "   ./create-laravel-project.sh toko-online"
echo "   ./create-laravel-project.sh blog-pribadi"
echo "   ./create-laravel-project.sh api-backend"
echo ""
echo "✨ SCRIPT AKAN OTOMATIS:"
echo "   ✅ Membuat folder project baru"
echo "   ✅ Setup Docker dengan volume terpisah"
echo "   ✅ Install Laravel"
echo "   ✅ Setup database & migrations"
echo "   ✅ Generate passwords random"
echo ""
echo "📁 HASIL:"
echo "   ../nama-project/ dengan Laravel siap pakai!"
echo ""
echo "🔗 AKSES:"
echo "   Web: http://localhost:8080"
echo "   MySQL: localhost:3307"
echo "   Redis: localhost:6380"
echo ""
echo "════════════════════════════════════════════════════════════"
echo ""
read -p "Tekan ENTER untuk melanjutkan atau Ctrl+C untuk batal..."
echo ""

# Tanya nama project
read -p "Masukkan nama project: " project_name

if [ -z "$project_name" ]; then
    echo "❌ Nama project tidak boleh kosong!"
    exit 1
fi

# Jalankan script utama
./create-laravel-project.sh "$project_name"

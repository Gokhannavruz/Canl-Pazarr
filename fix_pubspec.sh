#!/bin/bash

echo "🔧 pubspec.yaml dosyasındaki geçersiz sürüm formatını düzeltme"

# pubspec.yaml'ı yedekle
cp pubspec.yaml pubspec.yaml.bak.$(date +%s)

# Geçersiz sürüm formatını düzelt
echo "📝 firebase_app_check sürümünü düzeltiyorum..."

# Hatalı formatı düzelt
sed -i '' 's/firebase_app_check: \^0.1.5+2+3/firebase_app_check: ^0.1.5+2/g' pubspec.yaml

echo "⚙️ Flutter bağımlılıklarını güncelliyorum..."
flutter clean
flutter pub get

echo "✅ pubspec.yaml dosyası düzeltildi ve bağımlılıklar güncellendi!"
echo "🔧 Şimdi iOS bağımlılıklarını güncellemek için:"
echo "cd ios"
echo "pod install"

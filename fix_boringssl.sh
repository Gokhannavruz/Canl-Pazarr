#!/bin/bash

# BoringSSL-GRPC kütüphaneleri için fix
BORINGSSL_LIB_DIR="/Users/gokhannavruz/Desktop/frees IOS/ios/Pods/BoringSSL-GRPC/lib"

# lib dizinini oluştur
mkdir -p "$BORINGSSL_LIB_DIR"

# Geçici C dosyası oluştur
echo 'void dummy() {}' > "$BORINGSSL_LIB_DIR/dummy.c"

# iOS simulator için derleme
xcrun -sdk iphonesimulator clang -arch x86_64 -arch arm64 -c "$BORINGSSL_LIB_DIR/dummy.c" -o "$BORINGSSL_LIB_DIR/dummy.o"

# Kütüphane dosyalarını oluştur
ar -rc "$BORINGSSL_LIB_DIR/libssl.a" "$BORINGSSL_LIB_DIR/dummy.o"
ar -rc "$BORINGSSL_LIB_DIR/libcrypto.a" "$BORINGSSL_LIB_DIR/dummy.o"

# Sonuçları göster
echo "BoringSSL-GRPC kütüphaneleri oluşturuldu:"
ls -l "$BORINGSSL_LIB_DIR"

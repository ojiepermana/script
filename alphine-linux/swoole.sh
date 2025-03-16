#!/bin/sh
set -e

# Pastikan script dijalankan sebagai root
if [ "$(id -u)" != "0" ]; then
   echo "Script ini harus dijalankan sebagai root." 1>&2
   exit 1
fi

# Update repositori dan install dependensi build yang diperlukan
apk update
apk add --no-cache autoconf build-base re2c wget jq openssl-dev curl-dev libxml2-dev

# Pastikan PHP 8.4 sudah terinstall dan phpize tersedia
if ! command -v phpize >/dev/null 2>&1; then
    if [ -f /usr/local/php/bin/phpize ]; then
        ln -sf /usr/local/php/bin/phpize /usr/bin/phpize
    else
        echo "phpize tidak ditemukan. Pastikan PHP 8.4 telah terinstall." 1>&2
        exit 1
    fi
fi

# Ambil versi terbaru Swoole dari GitHub
echo "Mengambil informasi rilis terbaru Swoole..."
LATEST_TAG=$(wget -qO- "https://api.github.com/repos/swoole/swoole-src/releases/latest" | jq -r '.tag_name')
if [ -z "$LATEST_TAG" ]; then
    echo "Gagal mengambil informasi rilis terbaru Swoole." 1>&2
    exit 1
fi

SWOOLE_VERSION="$LATEST_TAG"
echo "Menggunakan Swoole versi $SWOOLE_VERSION"

SWOOLE_TAR="${SWOOLE_VERSION}.tar.gz"
SWOOLE_URL="https://github.com/swoole/swoole-src/archive/refs/tags/${SWOOLE_TAR}"

# Membuat direktori build dan masuk ke dalamnya
BUILD_DIR="/usr/local/src/swoole"
mkdir -p ${BUILD_DIR}
cd ${BUILD_DIR}

# Mengunduh source code Swoole jika belum ada
if [ ! -f ${SWOOLE_TAR} ]; then
    echo "Mengunduh Swoole versi ${SWOOLE_VERSION}..."
    wget ${SWOOLE_URL} -O ${SWOOLE_TAR}
fi

# Mengekstrak source code
tar -xf ${SWOOLE_TAR}

# Nama direktori hasil ekstrak biasanya tanpa awalan "v" pada versinya
SWOOLE_DIR="swoole-src-${SWOOLE_VERSION#v}"
cd "$SWOOLE_DIR"

# Siapkan lingkungan build untuk PHP extension
phpize

# Konfigurasi build Swoole (tanpa dukungan OCDC dan Oracle)
./configure --enable-swoole --enable-openssl --enable-http2 --enable-sockets

# Compile dan install Swoole
make -j$(nproc)
make install

# Menambahkan extension Swoole ke php.ini (asumsi file konfigurasi PHP ada di /usr/local/php/php.ini)
PHP_INI="/usr/local/php/php.ini"
if grep -q "extension=swoole.so" ${PHP_INI}; then
    echo "Swoole sudah terkonfigurasi di ${PHP_INI}"
else
    echo "extension=swoole.so" >> ${PHP_INI}
    echo "Swoole berhasil ditambahkan ke ${PHP_INI}"
fi

echo "Swoole ${SWOOLE_VERSION} berhasil diinstall dan diaktifkan."

echo "Swoole ${SWOOLE_VERSION} berhasil diinstall dan diaktifkan."

# Clean up build directories and tarballs
echo "Membersihkan file sementara..."
rm -rf /usr/local/src/php
rm -rf /usr/local/src/swoole
apk cache clean

echo "Pembersihan selesai."
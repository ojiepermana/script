#!/bin/sh
set -e

# Pastikan script dijalankan sebagai root
if [ "$(id -u)" != "0" ]; then
   echo "Script ini harus dijalankan sebagai root." 1>&2
   exit 1
fi

echo "Memulai proses instalasi Swoole dan pembersihan file build..."

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

# Masuk ke direktori hasil ekstrak
# Nama direktori biasanya tanpa awalan "v" (misal: swoole-src-6.0.1)
SWOOLE_DIR="swoole-src-${SWOOLE_VERSION#v}"
cd "$SWOOLE_DIR"

# Siapkan lingkungan build untuk PHP extension
phpize

# Konfigurasi build Swoole (tanpa dukungan OCDC dan Oracle)
./configure --enable-swoole --enable-openssl --enable-http2 --enable-sockets

# Compile dan install Swoole
make -j$(nproc)
make install

# Tambahkan konfigurasi extension ke php.ini (asumsi file konfigurasi PHP ada di /usr/local/php/php.ini)
PHP_INI="/usr/local/php/php.ini"
if grep -q "extension=swoole.so" ${PHP_INI}; then
    echo "Swoole sudah terkonfigurasi di ${PHP_INI}"
else
    echo "extension=swoole.so" >> ${PHP_INI}
    echo "Swoole berhasil ditambahkan ke ${PHP_INI}"
fi

echo "Swoole ${SWOOLE_VERSION} berhasil diinstall dan diaktifkan."

# Proses pembersihan file build yang tidak diperlukan
echo "Memulai proses pembersihan file build..."

# Hapus direktori build Swoole
SWOOLE_BUILD_DIR="/usr/local/src/swoole"
if [ -d "$SWOOLE_BUILD_DIR" ]; then
    echo "Menghapus direktori build Swoole: $SWOOLE_BUILD_DIR"
    rm -rf "$SWOOLE_BUILD_DIR"
else
    echo "Direktori build Swoole tidak ditemukan."
fi

# Hapus direktori build PHP (jika ada, misalnya saat PHP dikompilasi dari source)
PHP_BUILD_DIR="/usr/local/src/php"
if [ -d "$PHP_BUILD_DIR" ]; then
    echo "Menghapus direktori build PHP: $PHP_BUILD_DIR"
    rm -rf "$PHP_BUILD_DIR"
else
    echo "Direktori build PHP tidak ditemukan."
fi

echo "Proses pembersihan selesai."
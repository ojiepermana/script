#!/bin/sh
set -e

# Pastikan script dijalankan sebagai root
if [ "$(id -u)" != "0" ]; then
   echo "Script ini harus dijalankan sebagai root." 1>&2
   exit 1
fi

# Update repositori dan install dependensi build beserta jq untuk parsing JSON
apk update
apk add --no-cache autoconf build-base bison re2c libxml2-dev openssl-dev curl-dev \
    libpng-dev libjpeg-turbo-dev libzip-dev oniguruma-dev jq sqlite sqlite-dev \
    postgresql-dev linux-headers libsodium-dev

# Jika variabel PHP_VERSION belum diset, ambil versi terbaru PHP 8.4 dari php.net
if [ -z "$PHP_VERSION" ]; then
    echo "Mengambil versi terbaru PHP 8.3..."
    PHP_VERSION=$(wget -qO- "https://www.php.net/releases/index.php?json&version=8.3&max=1" | jq -r 'keys[0]')
    if [ -z "$PHP_VERSION" ]; then
        echo "Gagal mengambil versi terbaru, menggunakan versi default 8.4.0"
        PHP_VERSION="8.3.0"
    fi
fi

echo "Menggunakan PHP versi $PHP_VERSION"

PHP_SRC="php-${PHP_VERSION}"
PHP_TAR="${PHP_SRC}.tar.gz"
DOWNLOAD_URL="https://www.php.net/distributions/${PHP_TAR}"

# Membuat direktori build dan masuk ke dalamnya
BUILD_DIR="/usr/local/src/php"
mkdir -p ${BUILD_DIR}
cd ${BUILD_DIR}

# Mengunduh source code PHP jika belum ada
if [ ! -f ${PHP_TAR} ]; then
    echo "Mengunduh PHP ${PHP_VERSION} source..."
    wget ${DOWNLOAD_URL} -O ${PHP_TAR}
fi

# Mengekstrak source code
tar -xf ${PHP_TAR}
cd ${PHP_SRC}

# Konfigurasi build dengan opsi yang diinginkan, termasuk dukungan untuk PostgreSQL, sockets, dan sodium
./configure --prefix=/usr/local/php \
    --with-config-file-path=/usr/local/php \
    --enable-mbstring \
    --with-curl \
    --with-openssl \
    --with-zlib \
    --with-xml \
    --enable-fpm \
    --with-mysqli \
    --with-pdo-mysql \
    --with-sqlite3 \
    --with-pgsql \
    --with-pdo-pgsql \
    --enable-sockets \
    --enable-sodium

# Compile dan install
make -j$(nproc)
make install

# Salin konfigurasi default php.ini
cp php.ini-development /usr/local/php/php.ini

# Membuat symbolic link agar perintah php dapat dijalankan langsung
ln -sf /usr/local/php/bin/php /usr/bin/php

echo "PHP ${PHP_VERSION} berhasil diinstall di /usr/local/php dan sudah tersedia di PATH"

# Hapus file-file build yang tidak digunakan lagi
cd /
rm -rf ${BUILD_DIR}
echo "Direktori build ${BUILD_DIR} telah dihapus."

# Install Composer
echo "Menginstal Composer..."
curl -sS https://getcomposer.org/installer -o composer-setup.php
/usr/local/php/bin/php composer-setup.php --install-dir=/usr/local/bin --filename=composer
rm -f composer-setup.php
echo "Composer telah diinstal dan tersedia sebagai 'composer'"
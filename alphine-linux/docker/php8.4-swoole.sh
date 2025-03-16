# Stage 1: Builder
FROM php:8.4-cli-alpine AS builder

# Instal build dependencies dan library yang dibutuhkan
RUN apk add --no-cache \
    git \
    autoconf \
    gcc \
    g++ \
    make \
    libc-dev \
    openssl-dev \
    linux-headers \
    libzip-dev \
    postgresql-dev \
    libpng-dev \
    libjpeg-turbo-dev \
    freetype-dev \
    pkgconf \
    zlib-dev \
    oniguruma-dev \
    nghttp2-dev \
    liburing-dev \
    c-ares-dev \
    hiredis-dev

# Instal ekstensi PHP standar agar header (misal: sockets) tersedia
RUN docker-php-ext-install sockets

# Instal ekstensi yang umum digunakan oleh Laravel:
# pdo_mysql, pdo_pgsql, zip, dan mbstring
RUN docker-php-ext-install pdo_mysql pdo_pgsql zip mbstring

# Pisahkan perintah untuk instalasi ekstensi gd (dengan dukungan freetype & jpeg)
RUN docker-php-ext-configure gd --with-freetype --with-jpeg && \
    docker-php-ext-install gd

# Install ekstensi Redis dan MongoDB via PECL, dan aktifkan keduanya
RUN pecl install redis mongodb && docker-php-ext-enable redis mongodb && \
    cp $(php-config --extension-dir)/redis.so /tmp/redis.so && \
    cp $(php-config --extension-dir)/mongodb.so /tmp/mongodb.so

# Build Swoole dari source dengan opsi konfigurasi yang diinginkan
WORKDIR /tmp
RUN git clone --depth=1 https://github.com/swoole/swoole-src.git

WORKDIR /tmp/swoole-src
RUN phpize && \
    ./configure --enable-openssl --enable-http2 --enable-sockets \
                --enable-swoole-mysql --enable-swoole-async-redis \
                --enable-liburing --enable-cares --with-postgres && \
    make -j$(nproc) && \
    make install

# Salin file ekstensi Swoole yang telah dikompilasi ke direktori sementara
RUN cp $(php-config --extension-dir)/swoole.so /tmp/swoole.so

# Stage 2: Minimal runtime image
FROM php:8.4-cli-alpine

# Instal library runtime yang diperlukan oleh ekstensi
RUN apk add --no-cache \
    openssl \
    libpng \
    libjpeg-turbo \
    freetype \
    libzip

# Salin ekstensi dari stage builder ke lokasi sementara di image runtime
COPY --from=builder /tmp/swoole.so /tmp/swoole.so
COPY --from=builder /tmp/redis.so /tmp/redis.so
COPY --from=builder /tmp/mongodb.so /tmp/mongodb.so

# Pindahkan ekstensi ke direktori ekstensi PHP (evaluasi shell command)
RUN mv /tmp/swoole.so $(php-config --extension-dir)/swoole.so && \
    mv /tmp/redis.so $(php-config --extension-dir)/redis.so && \
    mv /tmp/mongodb.so $(php-config --extension-dir)/mongodb.so

# Aktifkan ekstensi dengan membuat file konfigurasi di direktori conf.d
RUN echo "extension=swoole.so" > /usr/local/etc/php/conf.d/swoole.ini && \
    echo "extension=pdo_mysql.so" > /usr/local/etc/php/conf.d/pdo_mysql.ini && \
    echo "extension=pdo_pgsql.so" > /usr/local/etc/php/conf.d/pdo_pgsql.ini && \
    echo "extension=zip.so" > /usr/local/etc/php/conf.d/zip.ini && \
    echo "extension=mbstring.so" > /usr/local/etc/php/conf.d/mbstring.ini && \
    echo "extension=gd.so" > /usr/local/etc/php/conf.d/gd.ini && \
    echo "extension=sockets.so" > /usr/local/etc/php/conf.d/sockets.ini && \
    echo "extension=redis.so" > /usr/local/etc/php/conf.d/redis.ini && \
    echo "extension=mongodb.so" > /usr/local/etc/php/conf.d/mongodb.ini

WORKDIR /app
CMD ["php", "-a"]
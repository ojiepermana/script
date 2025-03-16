# Install dependencies untuk build ekstensi
FROM php:8.4-cli-alpine AS builder

RUN apk update && apk add --no-cache \
    autoconf gcc g++ make libzip-dev libpng-dev freetype-dev libjpeg-turbo-dev \
    openssl-dev nghttp2-dev postgresql-dev liburing-dev c-ares-dev oniguruma-dev linux-headers

# Install ekstensi PHP (termasuk sockets)
RUN docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) pdo_mysql pdo_pgsql zip mbstring gd sockets

# Download dan install openswoole dari source
RUN pecl download openswoole \
    && tar xvf openswoole-*.tgz \
    && cd openswoole-* \
    && phpize \
    && ./configure \
        --enable-openssl \
        --enable-http2 \
        --enable-sockets \
        --enable-swoole-mysql \
        --enable-swoole-async-redis \
        --enable-liburing \
        --with-postgres \
    && make -j$(nproc) \
    && make install \
    && docker-php-ext-enable openswoole

# Tahap final (image minimal)
FROM php:8.4-cli-alpine

# Install runtime dependency saja
RUN apk add --no-cache libzip libpng freetype libjpeg-turbo openssl nghttp2-libs postgresql-libs liburing c-ares oniguruma

# Copy ekstensi dari builder
COPY --from=builder /usr/local/lib/php/extensions/ /usr/local/lib/php/extensions/
COPY --from=builder /usr/local/etc/php/conf.d/ /usr/local/etc/php/conf.d/

# Bersihkan file yang tidak diperlukan
RUN rm -rf /var/cache/apk/*

# CMD default
CMD ["php", "-a"]
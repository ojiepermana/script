apk update && apk upgrade
apk add git wget nano curl zip unzip bash build-base autoconf
apk add autoconf gcc g++ make libzip-dev libpng-dev freetype-dev libjpeg-turbo-dev openssl-dev nghttp2-dev postgresql-dev liburing-dev c-ares-dev oniguruma-dev linux-headers curl-dev
apk add php php-cli  php-common  php-session  php-xml  php-sodium  php-tokenizer  php-fileinfo  php-dom  php-simplexml  php-xmlwriter  php-mysqli  php-pdo_mysql  php-json  php-openssl  php-curl  php-ctype  php-zlib  php-phar  php-session  php-mbstring  php-gd php-sockets php83-dev  php-pear
apk add composer 
pecl install -D 'enable-sockets="yes" enable-openssl="yes" enable-http2="yes" enable-mysqlnd="yes" enable-hook-curl="yes" enable-cares="yes" enable-liburing="yes" with-postgres="yes"' openswoole
sudo sh -c 'echo "extension=openswoole.so" > /etc/php83/conf.d/01_openswoole.ini'
dnf update -y
dnf install -y epel-release dnf-plugins-core
dnf install ncurses wget nano curl

dnf module reset php -y
dnf install -y https://rpms.remirepo.net/enterprise/remi-release-9.rpm
dnf module enable -y php:remi-8.3
dnf install -y php php-cli php-mbstring php-pdo php-json php-common php-devel php-opcache php-process php-intl php-pecl-swoole php-pecl-zip php-pecl-json-post php-curl php-bcmath php-mysqlnd unzip git curl

curl -sS https://getcomposer.org/installer | php
mv composer.phar /usr/local/bin/composer

dnf install -y php-xdebug php-gd php-xml php-pecl-redis

dnf install -y supervisor
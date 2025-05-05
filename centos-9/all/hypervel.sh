#!/bin/bash

# =========================================
# Hypervel Setup Script for CentOS Stream 9
# PHP 8.3 + Swoole, Redis, MySQL 8.4, PostgreSQL 17, Node.js 22 + Firewall
# =========================================

echo "📦 Updating System..."
dnf update -y
dnf install -y epel-release dnf-utils yum-utils curl unzip git

# -----------------------------------------
# 🐘 PHP 8.3 + Extensions + Swoole + Redis
# -----------------------------------------
echo "🔧 Installing PHP 8.3 from Remi Repo..."
dnf install -y https://rpms.remirepo.net/enterprise/remi-release-9.rpm
dnf module reset php -y
dnf module enable php:remi-8.3 -y

dnf install -y php php-cli php-common  php-mysqlnd php-pdo php-xml php-mbstring \
php-curl php-bcmath php-opcache php-soap php-gd php-intl php-pecl-zip php-devel php-pear

echo "📦 Installing php-pecl-swoole..."
dnf install -y php-pecl-swoole

echo "📦 Installing php-redis extension..."
dnf install -y php-pecl-redis


# -----------------------------------------
# 🧠 Redis
# -----------------------------------------
echo "🧠 Installing Redis Server..."
dnf install -y redis
systemctl enable redis --now

# -----------------------------------------
# 🐬 MySQL 8.4 (from MySQL Official Repo)
# -----------------------------------------
echo "🗄️ Installing MySQL 8.4..."
rpm -Uvh https://dev.mysql.com/get/mysql84-community-release-el9-1.noarch.rpm
dnf module disable -y mysql
dnf install -y mysql-community-server
systemctl enable mysqld --now

# Optional: show temporary MySQL root password
echo "🔐 MySQL root password (temporary):"
grep 'temporary password' /var/log/mysqld.log || echo "(check log manually)"

# -----------------------------------------
# 🐘 PostgreSQL 17 (Resmi dari pgdg)
# -----------------------------------------
echo "🗃️ Installing PostgreSQL 17..."
dnf install -y https://download.postgresql.org/pub/repos/yum/reporpms/EL-9-x86_64/pgdg-redhat-repo-latest.noarch.rpm
dnf -qy module disable postgresql
dnf install -y postgresql17-server postgresql17

/usr/pgsql-17/bin/postgresql-17-setup initdb
systemctl enable postgresql-17 --now

# -----------------------------------------
# 🧰 Node.js 22 (Latest LTS)
# -----------------------------------------
echo "📦 Installing Node.js 22..."
curl -fsSL https://rpm.nodesource.com/setup_22.x | bash -
dnf install -y nodejs

# -----------------------------------------
# 📦 Composer (PHP dependency manager)
# -----------------------------------------
echo "📦 Installing Composer..."
php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
php composer-setup.php --install-dir=/usr/local/bin --filename=composer
rm -f composer-setup.php
composer -V

# -----------------------------------------
# 🔥 Firewall Setup
# -----------------------------------------
echo "🔥 Configuring Firewalld..."
dnf install -y firewalld
systemctl enable firewalld --now

# Open Laravel Octane/Swoole port
firewall-cmd --permanent --add-port=9501/tcp

# Optional ports: Redis, MySQL, PostgreSQL
firewall-cmd --permanent --add-port=3306/tcp   # MySQL
firewall-cmd --permanent --add-port=5432/tcp   # PostgreSQL
firewall-cmd --permanent --add-port=6379/tcp   # Redis

firewall-cmd --reload

# -----------------------------------------
# ✅ Done
# -----------------------------------------
echo ""
echo "✅ Hypervel Environment Installed Successfully!"
echo "- PHP: $(php -v | head -n 1)"
echo "- MySQL: $(mysql --version)"
echo "- PostgreSQL: $(/usr/pgsql-17/bin/psql --version)"
echo "- Redis: $(redis-server --version)"
echo "- Composer: $(composer -V)"
echo "- Node.js: $(node -v)"
echo "- Open Ports: $(firewall-cmd --list-ports)"
#!/bin/bash

# Fungsi untuk menampilkan informasi dengan warna hijau
info() {
  echo -e "\033[1;32m$1\033[0m"
}

info "⏫ Updating system..."
sudo dnf update -y

info "📦 Installing basic tools: wget, nano, curl, htop, git, zip, unzip, ncurses..."
sudo dnf install wget nano curl htop git zip unzip ncurses -y

info "🔁 Installing EPEL and Remi repositories..."
sudo dnf install epel-release -y
sudo dnf install remi-release -y
sudo dnf install https://rpms.remirepo.net/enterprise/remi-release-9.rpm -y

info "📦 Listing available PHP modules..."
sudo dnf module list php

info "🔁 Enabling PHP 8.3 module from Remi..."
sudo dnf module enable php:remi-8.3 -y

info "📦 Installing PHP 8.3 with extensions..."
sudo dnf install php php-fpm php-cli php-pgsql php-mysql php-pecl-swoole php-mbstring php-xml php-zip php-curl php-json php-gd php-opcache php-intl php-bcmath -y

info "🎼 Installing Composer..."
wget https://getcomposer.org/installer -O composer-installer.php
sudo php composer-installer.php --filename=composer --install-dir=/usr/local/bin

info "🧬 Installing Nginx..."
sudo dnf install nginx -y
sudo systemctl enable nginx
sudo systemctl start nginx

info "🔥 Installing and configuring Firewalld..."
sudo dnf install firewalld -y
sudo systemctl enable firewalld
sudo systemctl start firewalld
sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --permanent --add-service=https
sudo firewall-cmd --permanent --list-all
sudo firewall-cmd --permanent --zone=public --add-port=81-89/tcp
sudo firewall-cmd --reload

info "🟢 Installing Node.js 22.x..."
curl -sL https://rpm.nodesource.com/setup_22.x | sudo bash -
sudo dnf install -y nodejs

info "✅ All steps completed!"
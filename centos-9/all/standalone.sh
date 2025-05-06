#!/bin/bash

# ========================
# ✅ DEFINISI ENV (Template)
# ========================
ENV_FILE="/etc/profile.d/env-server.sh"

sudo tee /etc/profile.d/env-server.sh > /dev/null <<EOF
# Auto-export ENV for PostgreSQL and n8n
export POSTGRES_DB="app_db"
export POSTGRES_USER="app_user"
export POSTGRES_PASSWORD="secret123"
export POSTGRES_PORT=5432

export N8N_PORT=5678
export N8N_USER="admin@example.com"
export N8N_PASSWORD="n8npassword"
export N8N_BASIC_AUTH=true
export N8N_BASIC_AUTH_USER="n8n"
export N8N_BASIC_AUTH_PASSWORD="n8nadmin"
export N8N_DB_NAME="n8n"
export N8N_DB_USER="n8n_user"
export N8N_DB_PASSWORD="n8n_pass"
export N8N_HOST="0.0.0.0"
EOF

# Apply now (tanpa harus login ulang)
source $ENV_FILE

# Pastikan bisa digunakan di skrip ini
export $(cat $ENV_FILE | grep -v '^#' | xargs)

# ========================
# 🖍️ WARNA & FORMAT
# ========================
RED='\033[1;31m'
WHITE='\033[1;37m'
BOLD='\033[1m'
RESET='\033[0m'
STEP=1
info() {
  echo -e "\n${RED}${BOLD}========== [${STEP}] ${WHITE}$1 ==========${RESET}"
  STEP=$((STEP + 1))
}
status_ok() {
  echo -e "${BOLD}[✓]${RESET} ${WHITE}$1${RESET}"
}

# =======================================
# MULAI PROSES INSTALASI
# =======================================
info "Updating system"
sudo dnf update -y && status_ok "System updated"

info "Installing basic tools: wget, nano, curl, htop, git, zip, unzip, ncurses"
sudo dnf install -y wget nano curl htop git zip unzip ncurses && status_ok "Basic tools installed"

info "Installing EPEL and Remi repositories"
sudo dnf install -y epel-release remi-release && status_ok "EPEL and Remi base installed"
sudo dnf install -y https://rpms.remirepo.net/enterprise/remi-release-9.rpm && status_ok "Remi latest release added"

info "Listing available PHP modules"
sudo dnf module list php

info "Enabling PHP 8.3 module from Remi"
sudo dnf module enable -y php:remi-8.3 && status_ok "PHP 8.3 module enabled"

info "Installing PHP 8.3 and extensions"
sudo dnf install -y php php-fpm php-cli php-pgsql php-mysql php-pecl-swoole \
php-mbstring php-xml php-zip php-curl php-json php-gd php-opcache php-intl php-bcmath && status_ok "PHP 8.3 installed"

info "Installing Composer"
wget https://getcomposer.org/installer -O composer-installer.php && \
sudo php composer-installer.php --filename=composer --install-dir=/usr/local/bin && \
status_ok "Composer installed"

info "Installing and starting Nginx"
sudo dnf install -y nginx && \
sudo systemctl enable nginx && \
sudo systemctl start nginx && \
status_ok "Nginx installed and running"

info "Installing PostgreSQL 17"
sudo dnf install -y https://download.postgresql.org/pub/repos/yum/reporpms/EL-9-x86_64/pgdg-redhat-repo-latest.noarch.rpm && \
sudo dnf -qy module disable postgresql && \
sudo dnf install -y postgresql17-server && \
/usr/pgsql-17/bin/postgresql-17-setup initdb && \
sudo systemctl enable postgresql-17 && \
sudo systemctl start postgresql-17 && \
status_ok "PostgreSQL 17 installed and running"

info "Installing and configuring Firewalld"
sudo dnf install -y firewalld && \
sudo systemctl enable firewalld && \
sudo systemctl start firewalld && \
sudo firewall-cmd --permanent --add-service=http && \
sudo firewall-cmd --permanent --add-service=https && \
sudo firewall-cmd --permanent --zone=public --add-port=5678/tcp && \
sudo firewall-cmd --permanent --zone=public --add-port=5432/tcp && \
sudo firewall-cmd --reload && \
status_ok "Firewall configured"

info "Installing Node.js 22.x"
curl -sL https://rpm.nodesource.com/setup_22.x | sudo bash - && \
sudo dnf install -y nodejs && \
status_ok "Node.js 22 installed"

# =======================================
# TAMPILKAN VERSI APLIKASI
# =======================================
info "Menampilkan versi aplikasi terpasang"

echo -e "${WHITE}${BOLD}PHP version:${RESET} $(php -v | head -n 1)"
echo -e "${WHITE}${BOLD}Composer version:${RESET} $(composer --version)"
echo -e "${WHITE}${BOLD}Nginx version:${RESET} $(nginx -v 2>&1)"
echo -e "${WHITE}${BOLD}PostgreSQL version:${RESET} $(psql --version)"
echo -e "${WHITE}${BOLD}Node.js version:${RESET} $(node -v)"
echo -e "${WHITE}${BOLD}npm version:${RESET} $(npm -v)"
echo -e "${WHITE}${BOLD}Git version:${RESET} $(git --version)"
echo -e "${WHITE}${BOLD}Curl version:${RESET} $(curl --version | head -n 1)"
echo -e "${WHITE}${BOLD}OS Release:${RESET} $(cat /etc/os-release | grep PRETTY_NAME | cut -d= -f2)"

echo -e "\n${RED}${BOLD}✅ SELESAI: Semua langkah berhasil dijalankan!${RESET}"
#!/bin/bash

# ========================
# ✅ DEFINISI ENV
# ========================
ENV_FILE="/etc/profile.d/env-server.sh"

sudo tee $ENV_FILE > /dev/null <<EOF
export POSTGRES_DB="app_db"
export POSTGRES_USER="etos"
export POSTGRES_PASSWORD="OldRadix9"
export POSTGRES_PORT=5432

export N8N_PORT=5678
export N8N_USER="it@etos.co.id"
export N8N_PASSWORD="OldRadix9"
export N8N_BASIC_AUTH=true
export N8N_BASIC_AUTH_USER="etos"
export N8N_BASIC_AUTH_PASSWORD="OldRadix9"
export N8N_DB_NAME="n8n"
export N8N_DB_USER="etos"
export N8N_DB_PASSWORD="OldRadix9"
export N8N_HOST="0.0.0.0"
EOF

source $ENV_FILE
export $(grep -v '^#' $ENV_FILE | xargs)

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

# ========================
# SETUP DASAR
# ========================
info "Setting timezone to Asia/Jakarta"
sudo timedatectl set-timezone Asia/Jakarta && \
status_ok "Timezone set to Asia/Jakarta"

info "Updating system"
sudo dnf update -y && status_ok "System updated"

info "Installing basic tools"
sudo dnf install -y wget nano curl htop git zip unzip ncurses && status_ok "Tools installed"

info "Installing EPEL and Remi repo"
sudo dnf install -y epel-release
sudo dnf install -y https://rpms.remirepo.net/enterprise/remi-release-9.rpm && status_ok "Remi added"

info "Enable PHP 8.4"
sudo dnf module reset -y php
sudo dnf module enable -y php:remi-8.4 && status_ok "PHP 8.4 enabled"

info "Installing PHP 8.4 + Extensions"
sudo dnf install -y php php-fpm php-cli php-pgsql php-mysql php-pecl-swoole \
php-mbstring php-xml php-zip php-curl php-json php-gd php-opcache php-intl php-bcmath && status_ok "PHP installed"

info "Installing Composer"
wget https://getcomposer.org/installer -O composer-installer.php && \
sudo php composer-installer.php --filename=composer --install-dir=/usr/local/bin && \
status_ok "Composer installed"

info "Installing Nginx"
sudo dnf install -y nginx && \
sudo systemctl enable nginx && \
sudo systemctl start nginx && \
status_ok "Nginx running"

info "Installing PostgreSQL 17"
sudo dnf install -y https://download.postgresql.org/pub/repos/yum/reporpms/EL-9-x86_64/pgdg-redhat-repo-latest.noarch.rpm && \
sudo dnf -qy module disable postgresql && \
sudo dnf install -y postgresql17-server && \
/usr/pgsql-17/bin/postgresql-17-setup initdb && \
sudo systemctl enable postgresql-17 && \
sudo systemctl start postgresql-17 && \
status_ok "PostgreSQL running"

info "Installing Firewalld"
sudo dnf install -y firewalld && \
sudo systemctl enable firewalld && \
sudo systemctl start firewalld && \
sudo firewall-cmd --permanent --add-service=http && \
sudo firewall-cmd --permanent --add-service=https && \
sudo firewall-cmd --permanent --zone=public --add-port=5678/tcp && \
sudo firewall-cmd --permanent --zone=public --add-port=5432/tcp && \
sudo firewall-cmd --permanent --zone=public --add-port=9100/tcp && \
sudo firewall-cmd --permanent --zone=public --add-port=9187/tcp && \
sudo firewall-cmd --reload && \
status_ok "Firewall configured"

# ========================
# SUPERVISOR SETUP
# ========================
info "Installing Supervisor"
sudo dnf install -y supervisor && \
sudo systemctl enable supervisord && \
sudo systemctl start supervisord && \
status_ok "Supervisor running"

info "Creating Supervisor config for n8n"
sudo tee /etc/supervisord.d/n8n.ini > /dev/null <<EOF
[program:n8n]
command=/usr/bin/env bash -c 'source /etc/profile.d/env-server.sh && n8n start'
autostart=true
autorestart=true
stderr_logfile=/var/log/n8n.err.log
stdout_logfile=/var/log/n8n.out.log
user=root
environment=HOME="/root",USER="root"
EOF

info "Creating Supervisor config for Laravel queue worker"
sudo tee /etc/supervisord.d/laravel-worker.ini > /dev/null <<EOF
[program:laravel-worker]
command=/usr/bin/env bash -c 'cd /var/www/html && php artisan queue:work --sleep=3 --tries=3 --timeout=90'
process_name=%(program_name)s_%(process_num)02d
numprocs=1
autostart=true
autorestart=true
stopasgroup=true
killasgroup=true
stderr_logfile=/var/log/laravel-worker.err.log
stdout_logfile=/var/log/laravel-worker.out.log
user=nginx
environment=HOME="/home/nginx",USER="nginx"
EOF

sudo systemctl restart supervisord && status_ok "Supervisor jobs configured"

# ========================
# NODEJS
# ========================
info "Installing Node.js 24"
curl -sL https://rpm.nodesource.com/setup_24.x | sudo bash - && \
sudo dnf install -y nodejs && \
status_ok "Node.js 24 installed"

# ========================
# NODE EXPORTER
# ========================
info "Installing Node Exporter"
NODE_EXPORTER_VERSION="1.8.1"
cd /opt
curl -LO https://github.com/prometheus/node_exporter/releases/download/v$NODE_EXPORTER_VERSION/node_exporter-$NODE_EXPORTER_VERSION.linux-amd64.tar.gz
tar -xzf node_exporter-$NODE_EXPORTER_VERSION.linux-amd64.tar.gz
sudo mv node_exporter-$NODE_EXPORTER_VERSION.linux-amd64/node_exporter /usr/local/bin/
rm -rf node_exporter*

sudo tee /etc/systemd/system/node_exporter.service > /dev/null <<EOF
[Unit]
Description=Node Exporter
After=network.target

[Service]
User=nobody
ExecStart=/usr/local/bin/node_exporter
Restart=always

[Install]
WantedBy=default.target
EOF

sudo systemctl daemon-reexec
sudo systemctl daemon-reload
sudo systemctl enable node_exporter
sudo systemctl start node_exporter && status_ok "Node Exporter installed"

# ========================
# POSTGRES EXPORTER
# ========================
info "Installing PostgreSQL Exporter"
PG_EXPORTER_VERSION="0.15.0"
cd /opt
curl -LO https://github.com/prometheus-community/postgres_exporter/releases/download/v$PG_EXPORTER_VERSION/postgres_exporter-$PG_EXPORTER_VERSION.linux-amd64.tar.gz
tar -xzf postgres_exporter-$PG_EXPORTER_VERSION.linux-amd64.tar.gz
sudo mv postgres_exporter-$PG_EXPORTER_VERSION.linux-amd64/postgres_exporter /usr/local/bin/
rm -rf postgres_exporter*

sudo tee /etc/systemd/system/postgres_exporter.service > /dev/null <<EOF
[Unit]
Description=Prometheus PostgreSQL Exporter
After=network.target

[Service]
User=postgres
Environment=DATA_SOURCE_NAME=postgresql://etos:OldRadix9@localhost:5432/app_db?sslmode=disable
ExecStart=/usr/local/bin/postgres_exporter
Restart=always

[Install]
WantedBy=default.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable postgres_exporter
sudo systemctl start postgres_exporter && \
status_ok "Postgres Exporter installed"

# ========================
# VERSI AKHIR
# ========================
info "Menampilkan versi aplikasi terpasang"
echo -e "${WHITE}${BOLD}PHP:${RESET} $(php -v | head -n 1)"
echo -e "${WHITE}${BOLD}Composer:${RESET} $(composer --version)"
echo -e "${WHITE}${BOLD}Nginx:${RESET} $(nginx -v 2>&1)"
echo -e "${WHITE}${BOLD}PostgreSQL:${RESET} $(psql --version)"
echo -e "${WHITE}${BOLD}Node.js:${RESET} $(node -v)"
echo -e "${WHITE}${BOLD}npm:${RESET} $(npm -v)"
echo -e "${WHITE}${BOLD}Timezone:${RESET} $(timedatectl | grep "Time zone")"
echo -e "${WHITE}${BOLD}OS:${RESET} $(cat /etc/os-release | grep PRETTY_NAME | cut -d= -f2)"

echo -e "\n${RED}${BOLD}✅ SELESAI: Semua layanan berhasil dipasang dan dikonfigurasi!${RESET}"
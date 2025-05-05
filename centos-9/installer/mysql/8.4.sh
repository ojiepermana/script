#!/bin/bash

# ------------------------------
# Variabel konfigurasi
# ------------------------------
MYSQL_ROOT_PASSWORD="OldRadix9!@#"
MYSQL_USER="app"
MYSQL_USER_PASSWORD="OldRadix9!@#"

PINK='\e[95m'
RESET='\e[0m'

# ------------------------------
# Pastikan dijalankan sebagai root
# ------------------------------
if [ "$(id -u)" -ne 0 ]; then
    echo -e "${PINK}Script ini harus dijalankan sebagai root!${RESET}"
    exit 1
fi

echo -e "${PINK}Update sistem...${RESET}"
dnf update -y

# ------------------------------
# Install MySQL 8.4 dari repo resmi
# ------------------------------
echo -e "${PINK}Install repo resmi MySQL 8.4...${RESET}"
rpm -Uvh https://dev.mysql.com/get/mysql84-community-release-el9-1.noarch.rpm
dnf module disable -y mysql
dnf install -y mysql-community-server

echo -e "${PINK}Aktifkan dan jalankan MySQL...${RESET}"
systemctl enable --now mysqld

# ------------------------------
# Firewall setup
# ------------------------------
echo -e "${PINK}Install dan aktifkan firewalld...${RESET}"
dnf install -y firewalld
systemctl enable --now firewalld

echo -e "${PINK}Konfigurasi firewall hanya untuk 192.168.1.0/24...${RESET}"
firewall-cmd --permanent --new-zone=mysqldb
firewall-cmd --permanent --zone=mysqldb --add-source=192.168.1.0/24
firewall-cmd --permanent --zone=mysqldb --add-port=3306/tcp
firewall-cmd --reload

# ------------------------------
# Konfigurasi file /etc/my.cnf
# ------------------------------
echo -e "${PINK}Mengatur konfigurasi optimasi MySQL...${RESET}"
cp /etc/my.cnf /etc/my.cnf.bak

cat > /etc/my.cnf <<EOF
[mysqld]
user = mysql
port = 3306
bind-address = 0.0.0.0

datadir = /var/lib/mysql
socket = /var/lib/mysql/mysql.sock
log-error = /var/log/mysqld.log
pid-file = /var/run/mysqld/mysqld.pid

# Memory and performance tuning (8 vCPU, 16GB RAM)
innodb_buffer_pool_size = 12G
innodb_buffer_pool_instances = 8
innodb_log_file_size = 1G
innodb_log_buffer_size = 256M
innodb_flush_log_at_trx_commit = 2
innodb_io_capacity = 1000
innodb_io_capacity_max = 2000

innodb_read_io_threads = 8
innodb_write_io_threads = 8
innodb_thread_concurrency = 16

tmp_table_size = 512M
max_heap_table_size = 512M
join_buffer_size = 4M
sort_buffer_size = 4M

max_connections = 500
max_connect_errors = 1000000
wait_timeout = 1800
interactive_timeout = 1800

slow_query_log = 1
slow_query_log_file = /var/log/mysql/slow.log
long_query_time = 1

log_bin = /var/log/mysql/mysql-bin.log
server-id = 1
binlog_format = ROW
expire_logs_days = 7
sync_binlog = 1

open_files_limit = 65535
table_open_cache = 4096
table_definition_cache = 4096

character-set-server = utf8mb4
collation-server = utf8mb4_unicode_ci
EOF

# ------------------------------
# Buat direktori log untuk MySQL
# ------------------------------
echo -e "${PINK}Membuat direktori log untuk MySQL...${RESET}"
mkdir -p /var/log/mysql
touch /var/log/mysql/slow.log
touch /var/log/mysql/mysql-bin.log
chown -R mysql:mysql /var/log/mysql

# ------------------------------
# Skip grant tables sementara
# ------------------------------
echo -e "${PINK}Override systemd untuk skip grant tables sementara...${RESET}"
mkdir -p /etc/systemd/system/mysqld.service.d
cat > /etc/systemd/system/mysqld.service.d/override.conf <<EOF
[Service]
ExecStart=
ExecStart=/usr/sbin/mysqld --skip-grant-tables --skip-networking=0 --socket=/var/lib/mysql/mysql.sock
EOF

systemctl daemon-reexec
systemctl daemon-reload
systemctl restart mysqld
sleep 5

# ------------------------------
# Set password dan buat user
# ------------------------------
echo -e "${PINK}Menetapkan password root dan membuat user ${MYSQL_USER}...${RESET}"
mysql <<EOF
FLUSH PRIVILEGES;
ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'192.168.1.%' IDENTIFIED BY '${MYSQL_USER_PASSWORD}';
GRANT ALL PRIVILEGES ON *.* TO '${MYSQL_USER}'@'192.168.1.%' WITH GRANT OPTION;
FLUSH PRIVILEGES;
EOF

# ------------------------------
# Kembalikan konfigurasi normal
# ------------------------------
echo -e "${PINK}Menghapus override skip grant dan restart MySQL...${RESET}"
rm -f /etc/systemd/system/mysqld.service.d/override.conf
systemctl daemon-reexec
systemctl daemon-reload
systemctl restart mysqld

# ------------------------------
# Output akhir
# ------------------------------
echo -e "${PINK}SELESAI!${RESET}"
echo -e "${PINK}Root password   : ${MYSQL_ROOT_PASSWORD}${RESET}"
echo -e "${PINK}User '${MYSQL_USER}'     : hanya bisa akses dari 192.168.1.0/24${RESET}"
echo -e "${PINK}MySQL port 3306 hanya bisa diakses dari 192.168.1.0/24${RESET}"
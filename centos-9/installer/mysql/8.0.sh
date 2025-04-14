#!/bin/bash

# ========================
# Konfigurasi Password
# ========================
MYSQL_ROOT_PASSWORD="OldRadix9"
MYSQL_ETOS_PASSWORD="OldRadix9"

# Warna pink
PINK='\e[95m'
RESET='\e[0m'

# ========================
# Cek root user
# ========================
if [ "$(id -u)" -ne 0 ]; then
    echo -e "${PINK}Script ini harus dijalankan sebagai root!${RESET}"
    exit 1
fi

echo -e "${PINK}=========================="
echo "Update sistem..."
echo -e "==========================${RESET}"
dnf update -y

echo -e "${PINK}=========================="
echo "Enable modul dan install MySQL 8..."
echo -e "==========================${RESET}"
dnf module reset -y mysql
dnf module enable -y mysql:8.0
dnf install -y mysql-server

echo -e "${PINK}=========================="
echo "Start dan enable MySQL..."
echo -e "==========================${RESET}"
systemctl enable --now mysqld

echo -e "${PINK}=========================="
echo "Install dan aktifkan firewalld..."
echo -e "==========================${RESET}"
dnf install -y firewalld
systemctl enable --now firewalld

echo -e "${PINK}=========================="
echo "Konfigurasi firewalld untuk MySQL..."
echo "Hanya izinkan subnet 192.168.1.0/24 ke port 3306"
echo -e "==========================${RESET}"
firewall-cmd --permanent --new-zone=mysqldb
firewall-cmd --permanent --zone=mysqldb --add-source=192.168.1.0/24
firewall-cmd --permanent --zone=mysqldb --add-port=3306/tcp
firewall-cmd --reload

echo -e "${PINK}=========================="
echo "Status zona mysqldb:"
echo -e "==========================${RESET}"
firewall-cmd --zone=mysqldb --list-all

echo -e "${PINK}=========================="
echo "Konfigurasi bind-address MySQL..."
echo -e "==========================${RESET}"
cp /etc/my.cnf /etc/my.cnf.bak

if ! grep -q "bind-address" /etc/my.cnf; then
    echo -e "\n[mysqld]" >> /etc/my.cnf
    echo "bind-address = 0.0.0.0" >> /etc/my.cnf
else
    sed -i 's/^bind-address.*/bind-address = 0.0.0.0/' /etc/my.cnf
fi

systemctl restart mysqld

echo -e "${PINK}=========================="
echo "Reset password root dan buat user 'etos'..."
echo -e "==========================${RESET}"

# Stop MySQL
systemctl stop mysqld
pkill mysqld
sleep 3

echo -e "${PINK}Menjalankan MySQL tanpa autentikasi (skip-grant-tables)...${RESET}"
nohup /usr/libexec/mysqld \
  --user=mysql \
  --skip-grant-tables \
  --skip-networking=0 \
  --socket=/tmp/mysql.sock \
  --datadir=/var/lib/mysql > /dev/null 2>&1 &

sleep 8

# Jalankan perintah SQL melalui socket custom
mysql --socket=/tmp/mysql.sock <<EOF
FLUSH PRIVILEGES;
ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';
CREATE USER IF NOT EXISTS 'etos'@'192.168.0.%' IDENTIFIED BY '${MYSQL_ETOS_PASSWORD}';
GRANT ALL PRIVILEGES ON *.* TO 'etos'@'192.168.0.%' WITH GRANT OPTION;
FLUSH PRIVILEGES;
EOF

# Kill proses MySQL manual
pkill -f --skip-grant-tables
sleep 3

# Start kembali MySQL normal
systemctl start mysqld

echo -e "${PINK}=========================="
echo "SELESAI!"
echo "MySQL 8 telah diinstall dan dikonfigurasi."
echo "Root password   : ${MYSQL_ROOT_PASSWORD}"
echo "User 'etos'     : hanya bisa akses dari 192.168.0.0/24"
echo "MySQL port 3306 hanya bisa diakses dari 192.168.1.0/24"
echo -e "==========================${RESET}"
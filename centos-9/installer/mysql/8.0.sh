#!/bin/bash

MYSQL_ROOT_PASSWORD="OldRadix9"
MYSQL_ETOS_PASSWORD="OldRadix9"
PINK='\e[95m'
RESET='\e[0m'

if [ "$(id -u)" -ne 0 ]; then
    echo -e "${PINK}Script ini harus dijalankan sebagai root!${RESET}"
    exit 1
fi

echo -e "${PINK}Update sistem...${RESET}"
dnf update -y

echo -e "${PINK}Install MySQL 8...${RESET}"
dnf module reset -y mysql
dnf module enable -y mysql:8.0
dnf install -y mysql-server

systemctl enable --now mysqld

echo -e "${PINK}Install dan aktifkan firewalld...${RESET}"
dnf install -y firewalld
systemctl enable --now firewalld

echo -e "${PINK}Konfigurasi firewall hanya untuk 192.168.1.0/24...${RESET}"
firewall-cmd --permanent --new-zone=mysqldb
firewall-cmd --permanent --zone=mysqldb --add-source=192.168.1.0/24
firewall-cmd --permanent --zone=mysqldb --add-port=3306/tcp
firewall-cmd --reload

echo -e "${PINK}Set bind-address agar bisa diakses dari jaringan lokal...${RESET}"
cp /etc/my.cnf /etc/my.cnf.bak
grep -q "bind-address" /etc/my.cnf || echo -e "\n[mysqld]" >> /etc/my.cnf
sed -i '/bind-address/d' /etc/my.cnf
echo "bind-address = 0.0.0.0" >> /etc/my.cnf
systemctl restart mysqld

echo -e "${PINK}Override systemd untuk skip grant tables sementara...${RESET}"
mkdir -p /etc/systemd/system/mysqld.service.d
cat > /etc/systemd/system/mysqld.service.d/override.conf <<EOF
[Service]
ExecStart=
ExecStart=/usr/libexec/mysqld --skip-grant-tables --skip-networking=0 --socket=/var/lib/mysql/mysql.sock
EOF

systemctl daemon-reexec
systemctl daemon-reload
systemctl restart mysqld
sleep 5

echo -e "${PINK}Menetapkan password root dan membuat user etos...${RESET}"
mysql <<EOF
FLUSH PRIVILEGES;
ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';
CREATE USER IF NOT EXISTS 'etos'@'192.168.1.%' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';
GRANT ALL PRIVILEGES ON *.* TO 'etos'@'192.168.1.%' WITH GRANT OPTION;
FLUSH PRIVILEGES;
EOF

echo -e "${PINK}Kembalikan konfigurasi normal MySQL...${RESET}"
rm -f /etc/systemd/system/mysqld.service.d/override.conf
systemctl daemon-reexec
systemctl daemon-reload
systemctl restart mysqld

echo -e "${PINK}SELESAI!${RESET}"
echo -e "${PINK}Root password   : ${MYSQL_ROOT_PASSWORD}${RESET}"
echo -e "${PINK}User 'etos'     : hanya bisa akses dari 192.168.0.0/24${RESET}"
echo -e "${PINK}MySQL port 3306 hanya bisa diakses dari 192.168.1.0/24${RESET}"
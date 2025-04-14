#!/bin/bash

MYSQL_ROOT_PASSWORD="Oldradix9"
MYSQL_ETOS_PASSWORD="Oldradix9"

echo "=========================="
echo "Pastikan dijalankan sebagai root"
echo "=========================="
if [ "$(id -u)" -ne 0 ]; then
    echo "Script harus dijalankan sebagai root."
    exit 1
fi

echo "=========================="
echo "Update sistem..."
echo "=========================="
dnf update -y

echo "=========================="
echo "Enable modul dan install MySQL 8..."
echo "=========================="
dnf module reset -y mysql
dnf module enable -y mysql:8.0
dnf install -y mysql-server

echo "=========================="
echo "Start dan enable mysqld..."
echo "=========================="
systemctl enable --now mysqld

echo "=========================="
echo "Install dan aktifkan firewalld..."
echo "=========================="
dnf install -y firewalld
systemctl enable --now firewalld

echo "=========================="
echo "Konfigurasi firewalld: izinkan 192.168.1.0/24 ke port 3306..."
echo "=========================="
firewall-cmd --permanent --new-zone=mysqldb
firewall-cmd --permanent --zone=mysqldb --add-source=192.168.1.0/24
firewall-cmd --permanent --zone=mysqldb --add-port=3306/tcp
firewall-cmd --reload
firewall-cmd --zone=mysqldb --list-all

echo "=========================="
echo "Konfigurasi bind-address agar bisa remote..."
echo "=========================="
cp /etc/my.cnf /etc/my.cnf.bak

if ! grep -q "bind-address" /etc/my.cnf; then
    echo -e "\n[mysqld]" >> /etc/my.cnf
    echo "bind-address = 0.0.0.0" >> /etc/my.cnf
else
    sed -i 's/^bind-address.*/bind-address = 0.0.0.0/' /etc/my.cnf
fi

systemctl restart mysqld

echo "=========================="
echo "Konfigurasi password root dan user etos..."
echo "=========================="
# Ambil temporary password dari log
TEMP_PASS=$(grep 'temporary password' /var/log/mysqld.log | awk '{print $NF}')

# Jalankan perintah MySQL untuk setup root & user etos
mysql --connect-expired-password -uroot -p"${TEMP_PASS}" <<EOF
ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';
CREATE USER 'etos'@'192.168.0.%' IDENTIFIED BY '${MYSQL_ETOS_PASSWORD}';
GRANT ALL PRIVILEGES ON *.* TO 'etos'@'192.168.0.%' WITH GRANT OPTION;
FLUSH PRIVILEGES;
EOF

echo "=========================="
echo "Selesai!"
echo "Root dan user 'etos' telah dibuat dengan password: ${MYSQL_ROOT_PASSWORD}"
echo "MySQL sekarang bisa diakses dari subnet 192.168.1.0/24 (port 3306)."
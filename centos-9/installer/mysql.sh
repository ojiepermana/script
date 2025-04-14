#!/bin/bash

# Jalankan sebagai root
NEW_ROOT_PASSWORD="OldRadix9!"        # Ganti sesuai keinginan
REMOTE_USER="etos"
REMOTE_PASS="OldRadix9!"          # Ganti sesuai keinginan
REMOTE_HOST="192.168.1.%"

echo "=== Mulai instalasi MySQL 8 ==="

echo "=== Update sistem ==="
dnf update -y



echo "=== Install MySQL  ==="
dnf install -y mysql

echo "=== Install firewalld ==="
dnf install -y firewalld
systemctl enable --now firewalld

echo "=== Buka port MySQL di firewall ==="
firewall-cmd --permanent --add-port=3306/tcp
firewall-cmd --reload

echo "=== Aktifkan dan mulai MySQL ==="
systemctl enable --now mysqld

# Ambil password root sementara
TEMP_PASS=$(grep 'temporary password' /var/log/mysqld.log | awk '{print $NF}')
echo "Password sementara root: $TEMP_PASS"

# Ganti konfigurasi bind-address
sed -i 's/^bind-address\s*=.*/bind-address = 0.0.0.0/' /etc/my.cnf.d/mysqld.cnf
systemctl restart mysqld

echo "=== Install expect ==="
dnf install -y expect

echo "=== Jalankan mysql_secure_installation otomatis ==="
expect <<EOF
spawn mysql_secure_installation

expect "Enter password for user root:"
send "$TEMP_PASS\r"

expect "New password:"
send "$NEW_ROOT_PASSWORD\r"

expect "Re-enter new password:"
send "$NEW_ROOT_PASSWORD\r"

expect "Change the password for root ?"
send "n\r"

expect "Remove anonymous users?"
send "y\r"

expect "Disallow root login remotely?"
send "n\r"

expect "Remove test database and access to it?"
send "y\r"

expect "Reload privilege tables now?"
send "y\r"

expect eof
EOF

echo "=== Buat user remote ==="
mysql -u root -p"$NEW_ROOT_PASSWORD" <<SQL
CREATE USER IF NOT EXISTS '$REMOTE_USER'@'$REMOTE_HOST' IDENTIFIED BY '$REMOTE_PASS';
GRANT ALL PRIVILEGES ON *.* TO '$REMOTE_USER'@'$REMOTE_HOST' WITH GRANT OPTION;
FLUSH PRIVILEGES;
SQL

echo "=== Selesai! MySQL siap digunakan. ==="
sudo dnf update -y
sudo dnf install ncurses git nano wget curl unzip -y

sudo dnf install firewalld -y
sudo systemctl enable firewalld
sudo systemctl start firewalld
sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --permanent --add-service=https
sudo firewall-cmd --permanent --list-all
sudo firewall-cmd --reload


sudo dnf install epel-release -y
sudo dnf install remi-release -y
sudo dnf install https://rpms.remirepo.net/enterprise/remi-release-9.rpm -y
sudo dnf module list php
sudo dnf module enable php:remi-8.3 -y
sudo dnf install php php-fpm php-cli php-mbstring php-xml php-zip php-curl php-json php-gd php-opcache php-intl php-bcmath -y
sudo php -v

sudo dnf install https://dev.mysql.com/get/mysql84-community-release-el9-1.noarch.rpm -y
sudo dnf config-manager --disable mysql80-community
sudo dnf config-manager --enable mysql-8.4-lts-community
sudo yum install mysql-community-server -y
sudo grep 'temporary password' /var/log/mysqld.log


sudo dnf install epel-release -y
sudo dnf install remi-release -y
sudo dnf install https://rpms.remirepo.net/enterprise/remi-release-9.rpm -y
sudo dnf module list php
sudo dnf module enable php:remi-8.3 -y
sudo dnf install php -y

wget https://getcomposer.org/installer -O composer-installer.php
sudo php composer-installer.php --filename=composer --install-dir=/usr/local/bin
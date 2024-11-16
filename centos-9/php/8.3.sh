sudo yum install epel-release && sudo yum install remi-release -y
sudo dnf install https://rpms.remirepo.net/enterprise/remi-release-9.rpm -y
sudo dnf module list php
sudo dnf module enable php:remi-8.3 -y
sudo dnf install php -y 

sudo dnf update -y
sudo dnf install wget nano curl htop git zip unzip ncurses -y

curl -s "https://raw.githubusercontent.com/ojiepermana/script/refs/heads/main/centos-9/php/8.3.sh" | sh
curl -s "https://raw.githubusercontent.com/ojiepermana/script/refs/heads/main/centos-9/firewall/script.sh" | sh
curl -s "https://raw.githubusercontent.com/ojiepermana/script/refs/heads/main/centos-9/nginx/nginx.sh" | sh
curl -s "https://raw.githubusercontent.com/ojiepermana/script/refs/heads/main/centos-9/nodejs/22.sh" | sh


dnf install  php-pgsql php-mysql php-pecl-swoole -y


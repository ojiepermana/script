sudo dnf update -y
sudo dnf install wget nano curl htop -y

curl -s "https://raw.githubusercontent.com/ojiepermana/script/refs/heads/main/centos-9/php/8.4.sh" | sh
curl -s "https://raw.githubusercontent.com/ojiepermana/script/refs/heads/main/centos-9/firewall/script.sh" | sh
curl -s "https://raw.githubusercontent.com/ojiepermana/script/refs/heads/main/centos-9/nodejs/22.sh" | sh
curl -s "https://raw.githubusercontent.com/ojiepermana/script/refs/heads/main/centos-9/puppeter/install.sh" | sh

npm install n8n -g
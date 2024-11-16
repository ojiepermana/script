sudo dnf install nginx -y
sudo systemctl enable nginx
sudo systemctl start nginx

sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --permanent --add-service=https
sudo firewall-cmd --permanent --zone=public --add-port=81-99/tcp
sudo firewall-cmd --permanent --list-all

sudo firewall-cmd --reload
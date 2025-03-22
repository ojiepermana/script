sudo dnf install firewalld -y
sudo systemctl enable firewalld
sudo systemctl start firewalld
sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --permanent --add-service=https
sudo firewall-cmd --permanent --list-all
sudo firewall-cmd --permanent --zone=public --add-port=81-89/tcp
sudo firewall-cmd --reload
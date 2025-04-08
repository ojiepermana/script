dnf install -y https://download.postgresql.org/pub/repos/yum/reporpms/EL-9-x86_64/pgdg-redhat-repo-latest.noarch.rpm
dnf -qy module disable postgresql
dnf install -y postgresql17-server
/usr/pgsql-17/bin/postgresql-17-setup initdb
systemctl enable postgresql-17
systemctl start postgresql-17
systemctl restart postgresql-17

sudo dnf install firewalld -y
sudo systemctl enable firewalld
sudo systemctl start firewalld

firewall-cmd --permanent --add-port=5432/tcp
firewall-cmd --reload
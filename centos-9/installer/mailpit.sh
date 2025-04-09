#!/bin/bash

set -e

MAILPIT_VERSION="latest"
INSTALL_PATH="/usr/local/bin"
SERVICE_PATH="/etc/systemd/system/mailpit.service"
MAILPIT_BIN="mailpit"

echo "📦 Downloading Mailpit..."
curl -L -o "$MAILPIT_BIN" "https://github.com/axllent/mailpit/releases/latest/download/mailpit-linux-amd64"

echo "🔐 Setting permissions and moving binary..."
chmod +x "$MAILPIT_BIN"
sudo mv "$MAILPIT_BIN" "$INSTALL_PATH/"

echo "✅ Mailpit installed to $INSTALL_PATH/$MAILPIT_BIN"

echo "🔁 Creating systemd service..."
sudo bash -c "cat > $SERVICE_PATH" <<EOF
[Unit]
Description=Mailpit email testing server
After=network.target

[Service]
ExecStart=$INSTALL_PATH/$MAILPIT_BIN --smtp 0.0.0.0:1025 --web 0.0.0.0:8025
Restart=always
User=nobody
Group=nogroup

[Install]
WantedBy=multi-user.target
EOF

echo "🔃 Reloading systemd and starting Mailpit..."
sudo systemctl daemon-reexec
sudo systemctl daemon-reload
sudo systemctl enable --now mailpit

echo "🔥 Installing and configuring firewalld..."
sudo dnf install -y firewalld
sudo systemctl enable --now firewalld

echo "🔓 Opening Mailpit ports (1025, 8025)..."
sudo firewall-cmd --permanent --add-port=1025/tcp
sudo firewall-cmd --permanent --add-port=8025/tcp
sudo firewall-cmd --reload

echo "✅ Mailpit setup complete!"
echo "📡 Access Mailpit Web UI at: http://<IP-address>:8025"
echo "📨 Laravel SMTP host: 127.0.0.1:1025"
#!/bin/bash

set -e

MAILPIT_VERSION="v1.24.0"
MAILPIT_URL="https://github.com/axllent/mailpit/releases/download/${MAILPIT_VERSION}/mailpit-linux-amd64.tar.gz"
INSTALL_PATH="/usr/local/bin"
SERVICE_PATH="/etc/systemd/system/mailpit.service"

echo "🚀 Mailpit Installer - Version $MAILPIT_VERSION"
echo ""

# === STEP 0: UPDATE SYSTEM & INSTALL DEPENDENCIES ===
echo "📦 Updating system & installing dependencies..."
sudo dnf update -y
sudo dnf install -y curl tar firewalld

# === STEP 1: REMOVE OLD INSTALLATION ===
if systemctl list-units --type=service | grep -q mailpit.service; then
    echo "🛑 Stopping existing Mailpit service..."
    sudo systemctl stop mailpit || true
    sudo systemctl disable mailpit || true
fi

if [ -f "$SERVICE_PATH" ]; then
    sudo rm -f "$SERVICE_PATH"
    echo "🧹 Removed old systemd service."
fi

if [ -f "$INSTALL_PATH/mailpit" ]; then
    sudo rm -f "$INSTALL_PATH/mailpit"
    echo "🗑️ Removed old Mailpit binary."
fi

# === STEP 2: DOWNLOAD & INSTALL MAILPIT ===
echo "📥 Downloading Mailpit from GitHub..."
curl -L -o mailpit-linux-amd64.tar.gz "$MAILPIT_URL"

echo "📦 Extracting Mailpit binary..."
tar -xzf mailpit-linux-amd64.tar.gz
chmod +x mailpit
sudo mv mailpit "$INSTALL_PATH/"
sudo chmod 755 "$INSTALL_PATH/mailpit"
rm -f mailpit-linux-amd64.tar.gz

echo "✅ Mailpit binary installed at $INSTALL_PATH/mailpit"

# === STEP 3: CREATE SYSTEMD SERVICE ===
echo "⚙️ Setting up systemd service..."
sudo bash -c "cat > $SERVICE_PATH" <<EOF
[Unit]
Description=Mailpit Email Testing Server
After=network.target

[Service]
ExecStart=$INSTALL_PATH/mailpit --smtp 0.0.0.0:1025 --listen 0.0.0.0:8025
Restart=always
WorkingDirectory=/tmp
User=nobody
Group=nobody

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reexec
sudo systemctl daemon-reload
sudo systemctl enable --now mailpit

echo "✅ Mailpit service started and enabled."

# === STEP 4: CONFIGURE FIREWALL ===
echo "🔐 Configuring firewall..."
sudo systemctl enable --now firewalld
sudo firewall-cmd --permanent --add-port=1025/tcp
sudo firewall-cmd --permanent --add-port=8025/tcp
sudo firewall-cmd --reload

# === DONE ===
echo ""
echo "🎉 Mailpit installation complete!"
echo "📨 SMTP  : 0.0.0.0:1025"
echo "🌐 Web UI: http://<your-server-ip>:8025"
echo ""
echo "💡 TIP: Use Nginx/Traefik to reverse proxy the Web UI for public/SSL access."
#!/bin/bash

set -e

# Versi stabil terbaru per Juni 2025
NODE_EXPORTER_VERSION="1.8.1"
USER="node_exporter"
BIN_DIR="/usr/local/bin"

echo "🔧 Menyiapkan user node_exporter..."
sudo useradd --no-create-home --shell /bin/false $USER || true

echo "⬇️ Mengunduh Node Exporter v$NODE_EXPORTER_VERSION..."
cd /tmp
curl -sLO https://github.com/prometheus/node_exporter/releases/download/v$NODE_EXPORTER_VERSION/node_exporter-$NODE_EXPORTER_VERSION.linux-amd64.tar.gz

echo "📦 Mengekstrak dan memindahkan binary..."
tar xvf node_exporter-$NODE_EXPORTER_VERSION.linux-amd64.tar.gz
cd node_exporter-$NODE_EXPORTER_VERSION.linux-amd64
sudo cp node_exporter $BIN_DIR/
sudo chown $USER:$USER $BIN_DIR/node_exporter

echo "📝 Membuat systemd service..."
sudo tee /etc/systemd/system/node_exporter.service > /dev/null <<EOF
[Unit]
Description=Prometheus Node Exporter
Wants=network-online.target
After=network-online.target

[Service]
User=$USER
Group=$USER
Type=simple
ExecStart=$BIN_DIR/node_exporter

[Install]
WantedBy=multi-user.target
EOF

echo "🚀 Mengaktifkan dan menjalankan service..."
sudo systemctl daemon-reexec
sudo systemctl daemon-reload
sudo systemctl enable --now node_exporter

echo "🚀 Mengaktifkan firewall.."
sudo apt install -y firewalld
sudo firewall-cmd --permanent --add-port=9100/tcp
sudo firewall-cmd --reload

echo "✅ Node Exporter berhasil diinstal dan berjalan di port 9100"
echo "🌐 Akses via: http://$(hostname -I | awk '{print $1}'):9100/metrics"

# (Opsional) Tambahkan aturan firewall jika firewalld aktif
if systemctl is-active --quiet firewalld; then
  echo "🔥 Membuka firewall port 9100..."
  sudo firewall-cmd --permanent --add-port=9100/tcp
  sudo firewall-cmd --reload
fi
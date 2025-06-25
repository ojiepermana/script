#!/bin/bash

set -e

PROM_VERSION="2.52.0"
EXPORTER_VERSION="1.8.1"
USER="prometheus"
INSTALL_DIR="/usr/local/bin"
CONFIG_DIR="/etc/prometheus"
DATA_DIR="/var/lib/prometheus"


echo  "Update & Basic Setup"
sudo dnf update -y && dnf install bash nano wget tar ncurses zip unzip  -y && \
echo "Berhasil menginstal alat dasar"


echo "🔧 Menyiapkan user & direktori Prometheus..."
sudo useradd --no-create-home --shell /bin/false $USER || true
sudo mkdir -p $CONFIG_DIR $DATA_DIR
sudo chown -R $USER:$USER $CONFIG_DIR $DATA_DIR

echo "⬇️ Mengunduh Prometheus $PROM_VERSION..."
cd /tmp
curl -sLO https://github.com/prometheus/prometheus/releases/download/v$PROM_VERSION/prometheus-$PROM_VERSION.linux-amd64.tar.gz
tar xvf prometheus-$PROM_VERSION.linux-amd64.tar.gz
cd prometheus-$PROM_VERSION.linux-amd64
sudo cp prometheus promtool $INSTALL_DIR
sudo cp -r consoles console_libraries $CONFIG_DIR/
sudo cp prometheus.yml $CONFIG_DIR/
sudo chown -R $USER:$USER $INSTALL_DIR/prometheus $INSTALL_DIR/promtool $CONFIG_DIR

echo "🛠 Mengatur konfigurasi Prometheus.yml..."
sudo tee $CONFIG_DIR/prometheus.yml > /dev/null <<EOF
global:
  scrape_interval: 30s

scrape_configs:
  - job_name: 'node'
    static_configs:
      - targets: ['localhost:9100']
EOF

echo "📝 Membuat systemd service untuk Prometheus..."
sudo tee /etc/systemd/system/prometheus.service > /dev/null <<EOF
[Unit]
Description=Prometheus Monitoring
Wants=network-online.target
After=network-online.target

[Service]
User=prometheus
Group=prometheus
Type=simple
ExecStart=$INSTALL_DIR/prometheus \\
  --config.file=$CONFIG_DIR/prometheus.yml \\
  --storage.tsdb.path=$DATA_DIR \\
  --web.console.templates=$CONFIG_DIR/consoles \\
  --web.console.libraries=$CONFIG_DIR/console_libraries \\
  --storage.tsdb.retention.time=7d \\
  --storage.tsdb.retention.size=512MB \\
  --web.listen-address=:9090
MemoryMax=300M
CPUQuota=50%

[Install]
WantedBy=multi-user.target
EOF

echo "⬇️ Mengunduh node_exporter $EXPORTER_VERSION..."
cd /tmp
curl -sLO https://github.com/prometheus/node_exporter/releases/download/v$EXPORTER_VERSION/node_exporter-$EXPORTER_VERSION.linux-amd64.tar.gz
tar xvf node_exporter-$EXPORTER_VERSION.linux-amd64.tar.gz
cd node_exporter-$EXPORTER_VERSION.linux-amd64
sudo cp node_exporter $INSTALL_DIR
sudo chown $USER:$USER $INSTALL_DIR/node_exporter

echo "📝 Membuat systemd service untuk node_exporter..."
sudo tee /etc/systemd/system/node_exporter.service > /dev/null <<EOF
[Unit]
Description=Node Exporter
Wants=network-online.target
After=network-online.target

[Service]
User=prometheus
Group=prometheus
Type=simple
ExecStart=$INSTALL_DIR/node_exporter
MemoryMax=100M
CPUQuota=25%

[Install]
WantedBy=multi-user.target
EOF

echo "🚀 Mengaktifkan semua service..."
sudo systemctl daemon-reexec
sudo systemctl daemon-reload
sudo systemctl enable --now prometheus node_exporter

echo "Installing and configuring Firewalld"
sudo dnf install -y firewalld && \
sudo systemctl enable firewalld && \
sudo systemctl start firewalld && \

echo "🔒 Mengecek dan membuka firewall port..."
if rpm -q firewalld &>/dev/null && systemctl is-active --quiet firewalld; then
  sudo firewall-cmd --permanent --add-port=9090/tcp
  sudo firewall-cmd --permanent --add-port=9100/tcp
  sudo firewall-cmd --reload
else
  echo "⚠️ Firewalld tidak aktif. Pastikan port 9090 dan 9100 terbuka untuk jaringan pusat."
fi


echo "Setting timezone to Asia/Jakarta"
sudo timedatectl set-timezone Asia/Jakarta && \
status_ok "Timezone set to Asia/Jakarta"

echo "✅ Instalasi selesai. Prometheus dan node_exporter aktif di:"
echo "   🔸 http://$(hostname -I | awk '{print $1}'):9090 (Prometheus)"
echo "   🔸 http://$(hostname -I | awk '{print $1}'):9100 (node_exporter)"



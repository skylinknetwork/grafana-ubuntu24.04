#!/usr/bin/env bash
# Installer Prometheus + SNMP Exporter + Grafana di Ubuntu 24.04
# Skenario: Monitoring Mikrotik via SNMP Exporter

set -euo pipefail

echo "=== [1/9] Update & install paket dasar ==="
sudo apt update
sudo apt upgrade -y
sudo apt install -y wget curl gnupg2 tar software-properties-common

echo "=== [2/9] Buat user & group Prometheus ==="
if ! getent group prometheus >/dev/null; then
  sudo groupadd --system prometheus
fi

if ! id -u prometheus >/dev/null 2>&1; then
  sudo useradd --system --no-create-home \
    --shell /usr/sbin/nologin \
    --gid prometheus prometheus
fi

echo "=== [3/9] Buat direktori Prometheus ==="
sudo mkdir -p /etc/prometheus
sudo mkdir -p /var/lib/prometheus

echo "=== [4/9] Download & install Prometheus 2.43.0 ==="
cd /tmp
rm -rf prometheus-2.43.0.linux-amd64 prometheus-2.43.0.linux-amd64.tar.gz
wget https://github.com/prometheus/prometheus/releases/download/v2.43.0/prometheus-2.43.0.linux-amd64.tar.gz
tar xvf prometheus-2.43.0.linux-amd64.tar.gz
cd prometheus-2.43.0.linux-amd64

echo "=== [5/9] Pindahkan binary & file pendukung Prometheus ==="
sudo mv prometheus promtool /usr/local/bin/
sudo mkdir -p /etc/prometheus/consoles /etc/prometheus/console_libraries
sudo mv consoles/ console_libraries/ /etc/prometheus/

echo "=== [6/9] Set kepemilikan direktori Prometheus ==="
sudo chown -R prometheus:prometheus /etc/prometheus /var/lib/prometheus

echo "=== [7/9] Tulis konfigurasi /etc/prometheus/prometheus.yml ==="
sudo tee /etc/prometheus/prometheus.yml > /dev/null << 'EOF'
global:
  scrape_interval: 15s
  evaluation_interval: 15s

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

  - job_name: 'mikrotik-snmp'
    metrics_path: /snmp
    params:
      module: [mikrotik]
    static_configs:
      - targets:
        - '10.20.20.1'  # Mikrotik X86-Home
        - '10.20.20.3'  # Mikrotik CHR VMWare
    relabel_configs:
      - source_labels: [__address__]
        target_label: __param_target
      - source_labels: [__param_target]
        target_label: instance
      - target_label: __address__
        replacement: '127.0.0.1:9116'
EOF

echo "=== [8/9] Buat service systemd Prometheus ==="
sudo tee /etc/systemd/system/prometheus.service > /dev/null << 'EOF'
[Unit]
Description=Prometheus Monitoring
Documentation=https://prometheus.io/docs/introduction/overview/
Wants=network-online.target
After=network-online.target

[Service]
Type=simple
User=prometheus
Group=prometheus
ExecStart=/usr/local/bin/prometheus \
  --config.file=/etc/prometheus/prometheus.yml \
  --storage.tsdb.path=/var/lib/prometheus \
  --web.console.templates=/etc/prometheus/consoles \
  --web.console.libraries=/etc/prometheus/console_libraries \
  --web.listen-address=0.0.0.0:9090
Restart=always

[Install]
WantedBy=multi-user.target
EOF

echo "=== [9/9] Reload & aktifkan service Prometheus ==="
sudo systemctl daemon-reload
sudo systemctl enable --now prometheus

echo "=== [10/15] Install snmp_exporter 0.21.0 ==="
cd /tmp
rm -rf snmp_exporter-0.21.0.linux-amd64 snmp_exporter-0.21.0.linux-amd64.tar.gz
wget https://github.com/prometheus/snmp_exporter/releases/download/v0.21.0/snmp_exporter-0.21.0.linux-amd64.tar.gz
tar xvf snmp_exporter-0.21.0.linux-amd64.tar.gz
cd snmp_exporter-0.21.0.linux-amd64

echo "=== [11/15] Buat user snmp-exporter ==="
if ! id -u snmp-exporter >/dev/null 2>&1; then
  sudo useradd --system --no-create-home \
    --shell /usr/sbin/nologin snmp-exporter
fi

echo "=== [12/15] Pindahkan file snmp_exporter ==="
sudo mkdir -p /etc/snmp_exporter
sudo mv snmp.yml /etc/snmp_exporter/snmp.yml
sudo mv snmp_exporter /usr/local/bin/snmp_exporter
sudo chown -R snmp-exporter:snmp-exporter /etc/snmp_exporter

echo "=== [13/15] Buat service systemd snmp_exporter ==="
sudo tee /etc/systemd/system/snmp_exporter.service > /dev/null << 'EOF'
[Unit]
Description=Prometheus SNMP Exporter
After=network.target

[Service]
Type=simple
User=snmp-exporter
Group=snmp-exporter
ExecStart=/usr/local/bin/snmp_exporter \
  --config.file=/etc/snmp_exporter/snmp.yml
Restart=always

[Install]
WantedBy=multi-user.target
EOF

echo "=== [14/15] Reload & aktifkan service snmp_exporter ==="
sudo systemctl daemon-reload
sudo systemctl enable --now snmp_exporter

echo "=== [15/15] Install Grafana OSS ==="
sudo apt install -y software-properties-common curl gnupg2
echo "deb https://packages.grafana.com/oss/deb stable main" \
 | sudo tee /etc/apt/sources.list.d/grafana.list
curl -s https://packages.grafana.com/gpg.key \
 | sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/grafana.gpg
sudo apt update
sudo apt install -y grafana
sudo systemctl daemon-reload
sudo systemctl enable --now grafana-server

echo ""
echo "==============================================="
echo " Instalasi selesai!"
echo " Prometheus  : http://<IP-SERVER>:9090"
echo " SNMP Export : http://<IP-SERVER>:9116/metrics"
echo " Grafana     : http://<IP-SERVER>:3000 (admin / admin)"
echo "==============================================="

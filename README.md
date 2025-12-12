# install Grafana di Ubuntu Server 24.04
Disini kita akan coba install Grafana di Ubuntu Server 24.04<br>
Kami menggunakan [Putty](https://putty.org/index.html) untuk copy paster dari Github ke Terminal

🧊 Persiapan di Ubuntu 24.04
   - pembaruan paket di repositori
   - Update semua paket yang ada
   - Instal tools untuk download file
```
sudo apt update
sudo apt upgrade -y
sudo apt install -y wget curl gnupg2 tar
```
## 🚀 1. Install Prometheus
🧊 Buat user & group untuk Prometheus
```
sudo groupadd --system prometheus
sudo useradd --system --no-create-home \
  --shell /usr/sbin/nologin \
  --gid prometheus prometheus
```
🧊 Buat folder untuk instalasi prometheus
```
sudo mkdir -p /etc/prometheus
sudo mkdir -p /var/lib/prometheus
```

🧊 Install Prometheus 2.43.0 dan masuk ke folder /tmp
```
cd /tmp
wget https://github.com/prometheus/prometheus/releases/download/v2.43.0/prometheus-2.43.0.linux-amd64.tar.gz
tar xvf prometheus-2.43.0.linux-amd64.tar.gz
cd prometheus-2.43.0.linux-amd64
```
🧊 Pindahkan binary & file pendukung :
```bash
sudo mv prometheus promtool /usr/local/bin/
sudo mkdir -p /etc/prometheus/consoles /etc/prometheus/console_libraries
sudo mv consoles/ console_libraries/ /etc/prometheus/
```
🧊 Set kepemilikan file prometheus (user : prometheus | group : prometheus)
```
sudo chown -R prometheus:prometheus /etc/prometheus /var/lib/prometheus
```

🧊 Rubah Konfigurasi prometheus.yml<p>
**Jangan lupa untuk mengganti IP tujuan yang sesuai dengan device anda**<br>
**Bisa copy paste dulu di Notepad baru dicopy ke [Putty](https://putty.org/index.html)**
```
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
        - '10.20.20.1'  # Rubah dengan IP Tujuan device anda yang akan di monitoring
        - '10.20.20.3'  # Rubah dengan IP Tujuan device anda yang akan di monitoring
    relabel_configs:
      - source_labels: [__address__]
        target_label: __param_target
      - source_labels: [__param_target]
        target_label: instance
      - target_label: __address__
        replacement: '127.0.0.1:9116'
EOF
```

🧊 Rubah Service systemd Prometheus agar bisa autostart
```
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
```

🧊 Reload daemon dan Aktifkan Prometheus
```
sudo systemctl daemon-reload
sudo systemctl enable --now prometheus
```
## 🚀 2. Install snmp_exporter 0.21.0
🧊 Download, Extract dan pindah ke folder instalasi SNMP_Exporter
```
cd /tmp
wget https://github.com/prometheus/snmp_exporter/releases/download/v0.21.0/snmp_exporter-0.21.0.linux-amd64.tar.gz
tar xvf snmp_exporter-0.21.0.linux-amd64.tar.gz
cd snmp_exporter-0.21.0.linux-amd64
```

🧊 Add User untuk konfigurasi snmp_exporter
```
sudo useradd --system --no-create-home \
  --shell /usr/sbin/nologin snmp-exporter
```

🧊 Pindahkan file snmp_exporter
```
sudo mkdir -p /etc/snmp_exporter
sudo mv snmp.yml /etc/snmp_exporter/snmp.yml
sudo mv snmp_exporter /usr/local/bin/snmp_exporter
sudo chown -R snmp-exporter:snmp-exporter /etc/snmp_exporter
```

🧊 Buat Service systemd untuk snmp_exporter
```
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
```

🧊 Reload daemon & Aktifkan snmp_exporter
```
sudo systemctl daemon-reload
sudo systemctl enable --now snmp_exporter
```

## 🚀 3. Install Grafana
🧊 Install Grafana & aktivasi Sekali crot
```
sudo apt install -y software-properties-common curl gnupg2
echo "deb https://packages.grafana.com/oss/deb stable main" \
 | sudo tee /etc/apt/sources.list.d/grafana.list
curl -s https://packages.grafana.com/gpg.key \
 | sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/grafana.gpg
sudo apt update
sudo apt install -y grafana
sudo systemctl daemon-reload
sudo systemctl enable --now grafana-server
```

## 🚀 4. Config Grafana dan masukkan template dashboard
🧊 Masukkan id & password default grafana (admin | admin)
![001](https://github.com/user-attachments/assets/098c1fe0-4a32-48ae-b54f-324228ead55d)



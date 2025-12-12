# Tutorial install Grafana di Ubuntu Server 24.04
Disini kita sama2 belajar langkah demi langkah install Grafana di Ubuntu Server 24.04

🧊 Persiapan di Ubuntu 24.04
   - pembaruan paket di repositori
   - Update semua paket yang ada
   - Instal tools untuk download file
```bash
sudo apt update
sudo apt upgrade -y
sudo apt install -y wget curl gnupg2 tar
```

🧊 Buat user & group untuk Prometheus
```bash
sudo groupadd --system prometheus
sudo useradd --system --no-create-home \
  --shell /usr/sbin/nologin \
  --gid prometheus prometheus
```
🧊 Buat folder untuk instalasi prometheus
```bash
sudo mkdir -p /etc/prometheus
sudo mkdir -p /var/lib/prometheus
```

🧊 Install Prometheus 2.43.0 dan masuk ke folder /tmp
```bash
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
```bash
sudo chown -R prometheus:prometheus /etc/prometheus /var/lib/prometheus
```

🧊 Rubah Konfigurasi prometheus.yml<p>
**Jangan lupa untuk mengganti IP tujuan yang sesuai dengan device anda**<br>
**Bisa copy paste dulu di Notepad baru dicopy ke [Putty]([https://pages.github.com/](https://putty.org/index.html)).**
```bash
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

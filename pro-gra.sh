#!/bin/bash
sudo su -
yum update -y
wget https://dl.grafana.com/oss/release/grafana-9.2.1.linux-amd64.tar.gz
tar -xvzf grafana-9.2.1.linux-amd64.tar.gz
chmod -R 755 grafana-9.2.1
cd grafana-9.2.1/bin/
nohup ./grafana-server & 
cd ../../../opt
 wget https://github.com/prometheus/prometheus/releases/download/v2.39.1/prometheus-2.39.1.linux-amd64.tar.gz
 tar -xf prometheus-2.39.1.linux-amd64.tar.gz
 cd  prometheus-2.39.1.linux-amd64/
 #sed -i 's/localhost:9090/10.0.6.105:9100/' prometheus.yml
#  nohup ./prometheus &
 ./prometheus
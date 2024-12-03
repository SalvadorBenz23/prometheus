#!/bin/bash

echo "Starting the Prometheus Environment Installation"

# Variables
PROMETHEUS_VERSION="2.42.0"
ALERTMANAGER_VERSION="0.25.0"
NODE_EXPORTER_VERSION="1.6.1"
PUSHGATEWAY_VERSION="1.4.1"

# Update system and install necessary packages
echo "Updating system and installing required packages..."
sudo apt update && sudo apt upgrade -y
sudo apt install -y wget tar docker.io docker-compose python3-pip nodejs npm

# Install Prometheus
echo "Installing Prometheus..."
wget https://github.com/prometheus/prometheus/releases/download/v$PROMETHEUS_VERSION/prometheus-$PROMETHEUS_VERSION.linux-amd64.tar.gz
tar -xzf prometheus-$PROMETHEUS_VERSION.linux-amd64.tar.gz
mv prometheus-$PROMETHEUS_VERSION.linux-amd64 prometheus/prometheus
rm prometheus-$PROMETHEUS_VERSION.linux-amd64.tar.gz

# Install AlertManager
echo "Installing AlertManager..."
wget https://github.com/prometheus/alertmanager/releases/download/v$ALERTMANAGER_VERSION/alertmanager-$ALERTMANAGER_VERSION.linux-amd64.tar.gz
tar -xzf alertmanager-$ALERTMANAGER_VERSION.linux-amd64.tar.gz
mv alertmanager-$ALERTMANAGER_VERSION.linux-amd64 prometheus/alertmanager
rm alertmanager-$ALERTMANAGER_VERSION.linux-amd64.tar.gz

# Install Node Exporter
echo "Installing Node Exporter..."
wget https://github.com/prometheus/node_exporter/releases/download/v$NODE_EXPORTER_VERSION/node_exporter-$NODE_EXPORTER_VERSION.linux-amd64.tar.gz
tar -xzf node_exporter-$NODE_EXPORTER_VERSION.linux-amd64.tar.gz
mv node_exporter-$NODE_EXPORTER_VERSION.linux-amd64 prometheus/exporters/node_exporter
rm node_exporter-$NODE_EXPORTER_VERSION.linux-amd64.tar.gz

# Install Pushgateway
echo "Installing Pushgateway..."
wget https://github.com/prometheus/pushgateway/releases/download/v$PUSHGATEWAY_VERSION/pushgateway-$PUSHGATEWAY_VERSION.linux-amd64.tar.gz
tar -xzf pushgateway-$PUSHGATEWAY_VERSION.linux-amd64.tar.gz
mv pushgateway-$PUSHGATEWAY_VERSION.linux-amd64 prometheus/exporters/pushgateway
rm pushgateway-$PUSHGATEWAY_VERSION.linux-amd64.tar.gz

# Configure Python and Node.js applications
echo "Setting up Python application..."
pip3 install flask prometheus-client requests
echo "Setting up Node.js application..."
npm install --prefix prometheus/apps/node_app

# Set up Docker containers
echo "Setting up MySQL and MySQL Exporter..."
docker network create my-mysql-network
docker run -d --name mysql-container --network my-mysql-network -e MYSQL_ROOT_PASSWORD=root -e MYSQL_DATABASE=test -p 3306:3306 mysql:5.7
docker run -d --name mysql-exporter --network my-mysql-network -p 9104:9104 -e DATA_SOURCE_NAME="exporter:P455word_of_exporter@(mysql-container:3306)/" prom/mysqld-exporter:v0.11.0

# Prepare Prometheus configuration
echo "Preparing Prometheus configuration..."
#mkdir -p prometheus/data
#mkdir -p prometheus/rules

# Set up systemd services (Optional)
#echo "Setting up systemd services for Prometheus and AlertManager..."
#cat <<EOT | sudo tee /etc/systemd/system/prometheus.service
#[Unit]
#Description=Prometheus
#After=network.target

#[Service]
#User=$(whoami)
#ExecStart=$(pwd)/prometheus/prometheus --config.file=$(pwd)/prometheus/prometheus.yml --storage.tsdb.path=$(pwd)/prometheus/data

#[Install]
#WantedBy=multi-user.target
#EOT

#cat <<EOT | sudo tee /etc/systemd/system/alertmanager.service
#[Unit]
#Description=AlertManager
#After=network.target

#[Service]
#User=$(whoami)
#ExecStart=$(pwd)/prometheus/alertmanager/alertmanager --config.file=$(pwd)/prometheus/alertmanager/alertmanager.yml

#[Install]
#WantedBy=multi-user.target
#EOT

#sudo systemctl daemon-reload
#sudo systemctl enable prometheus
#sudo systemctl enable alertmanager

# Start all services
echo "Starting all services..."
#sudo systemctl start prometheus
#sudo systemctl start alertmanager
sudo docker start mysql-container
sudo docker start mysql-exporter
nohup prometheus/exporters/node_exporter/node_exporter &> prometheus/exporters/node_exporter/node_exporter.log &
nohup prometheus/exporters/pushgateway/pushgateway &> prometheus/exporters/pushgateway/pushgateway.log &
nohup python3 prometheus/apps/python_app/app_metrics.py &> prometheus/apps/python_app/app_metrics.log &
nohup node prometheus/apps/node_app/server_metrics.js &> prometheus/apps/node_app/server_metrics.log &

echo "Installation complete. Prometheus environment is ready!"

#!/bin/bash

# Restart Docker Monitor
echo "Restarting Docker Monitor..."
sudo rm /var/run/docker.pid
sudo pkill -f dockerd
sudo service docker stop  # docker needs to be stopped to config dockerd
sudo dockerd --experimental --metrics-addr 127.0.0.1:9323 &
sleep 5
echo "Docker Monitor restarted."

# Restart Python App
echo "Restarting Python application..."
pkill -f app_metrics.py
source ~/prometheus/apps/python_app/venv/bin/activate
sudo python3 ~/prometheus/apps/python_app/app_metrics.py &
deactivate
echo "Python application restarted."

# Restart Node.js App
echo "Restarting Node.js application..."
pkill -f server_metrics.js
nohup node ~/prometheus/apps/node_app/server_metrics.js &> ~/prometheus/apps/node_app/server_metrics.log &
echo "Node.js application restarted."

# Restart Pushgateway
echo "Restarting Pushgateway..."
pkill pushgateway
sudo ~/prometheus/exporters/pushgateway/pushgateway &
sleep 2
echo "Pushgateway restarted."

# Restart MySQL and Exporter Containers
echo "Restarting MySQL container and exporter..."
sudo docker start mysql-container
#docker run -d   --name mysql-container   --network my-mysql-network   --restart unless-stopped   -e MYSQL_ROOT_PASSWORD=root_password   -e MYSQL_USER=exporter   -e MYSQL_PASSWORD=P455word_of_exporter   -e MYSQL_DATABASE=mydb   mysql:5.7
sudo docker start mysql-exporter
#docker run -d   --name mysql-exporter   -p 9104:9104   --network my-mysql-network   -e DATA_SOURCE_NAME="exporter:P455word_of_exporter@(mysql-container:3306)/"   prom/mysqld-exporter:v0.11.0

sleep 5
echo "MySQL containers restarted."

# Restart Node Exporter
echo "Restarting Node Exporter..."
pkill -f node_exporter
sudo ~/prometheus/exporters/node_exporter/node_exporter &
sleep 2
echo "Node Exporter restarted."

# Restart Prometheus
echo "Restarting Prometheus server..."
pkill prometheus
cd
nohup prometheus/prometheus --config.file=prometheus/prometheus.yml --web.enable-lifecycle &> ~/prometheus/prometheus.log &
sleep 5
echo "Prometheus server restarted."

echo "All services have been restarted!"
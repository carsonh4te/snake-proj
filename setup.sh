#!/bin/bash

# Portenta X8 Snake Project Setup Script
# Usage: ./setup.sh

echo "========================================"
echo "    SNAKE ENCLOSURE SETUP INITIATED     "
echo "========================================"

# 1. Define Paths
PROJECT_DIR="/home/fio/snake_project"
SD_MOUNT="/mnt/sdcard"

# 2. Check for SD Card Mount
if mountpoint -q "$SD_MOUNT"; then
    echo "[OK] SD Card is mounted at $SD_MOUNT"
else
    echo "[WARNING] SD Card NOT mounted at $SD_MOUNT"
    echo "Attempting to mount all..."
    sudo mount -a
    if mountpoint -q "$SD_MOUNT"; then
        echo "[OK] Mount successful."
    else
        echo "[ERROR] Could not mount SD Card. Check /etc/fstab."
        exit 1
    fi
fi

# 3. Create Data Directories & Fix Permissions
# This is crucial for Node-RED and InfluxDB to work without permission errors
echo "--- Configuring Storage Directories ---"
sudo mkdir -p "$SD_MOUNT/node_red_data"
sudo mkdir -p "$SD_MOUNT/influxdb_data"

# Ensure generic user access (simplifies Docker user mapping issues)
echo "--- Setting Permissions ---"
sudo chmod -R 777 "$SD_MOUNT/node_red_data"
sudo chmod -R 777 "$SD_MOUNT/influxdb_data"

# 4. Convert Line Endings (Just in case git config didn't catch it)
# This prevents the dreaded ^M errors if you edited on Windows
echo "--- Normalizing Line Endings ---"
sed -i 's/\r$//' docker-compose.yml
sed -i 's/\r$//' rpc_bridge.py
sed -i 's/\r$//' Dockerfile.bridge
sed -i 's/\r$//' mosquitto.conf

# 5. Restart M4 Proxy (Fixes Stale Connections)
echo "--- Restarting M4 Proxy Service ---"
sudo systemctl restart m4-proxy

# 6. Launch Docker Stack
echo "--- Launching Docker Containers ---"
# Pull images sequentially to prevent crash on low-memory devices
sudo docker compose pull --ignore-pull-failures
sudo docker compose up -d --build

echo "========================================"
echo "         DEPLOYMENT COMPLETE            "
echo "========================================"
echo "Check logs with: sudo docker compose logs -f"
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
echo "--- Configuring Storage Directories ---"
sudo mkdir -p "$SD_MOUNT/node_red_data"
sudo mkdir -p "$SD_MOUNT/influxdb_data"

echo "--- Setting Permissions ---"
sudo chmod -R 777 "$SD_MOUNT/node_red_data"
sudo chmod -R 777 "$SD_MOUNT/influxdb_data"

# 4. Restart M4 Proxy (Fixes Stale Connections)
echo "--- Restarting M4 Proxy Service ---"
sudo systemctl restart m4-proxy

# 5. Low-Memory Deployment Strategy
# We pull and build everything explicitly BEFORE starting the stack.
# This prevents the 'Unexpected EOF' crash caused by Docker running out of RAM.

echo "--- Step 1/4: Pulling MQTT Broker ---"
sudo docker pull eclipse-mosquitto:2

echo "--- Step 2/4: Pulling Database ---"
sudo docker pull influxdb:1.8

echo "--- Step 3/4: Pulling Node-RED (Large) ---"
sudo docker pull nodered/node-red:latest

echo "--- Step 4/4: Building Bridge Container ---"
# We build this separately so 'up' doesn't have to do it
sudo docker compose build bridge

# 6. Launch Docker Stack
echo "--- LAUNCHING CONTAINERS ---"
# Since everything is pulled and built, this just starts them instantly
sudo docker compose up -d

echo "========================================"
echo "         DEPLOYMENT COMPLETE            "
echo "========================================"
echo "Check logs with: sudo docker compose logs -f"
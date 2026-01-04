#!/bin/bash

# Portenta X8 Snake Project Setup Script
# Usage: ./setup.sh

echo "========================================"
echo "    SNAKE ENCLOSURE SETUP INITIATED     "
echo "========================================"

# --- 0. Helper Function: Robust Pull ---
pull_with_retry() {
    local image=$1
    local max_attempts=5
    local attempt=1

    echo "--- Pulling $image (Attempt $attempt/$max_attempts) ---"
    until sudo docker pull "$image"; do
        if [ $attempt -eq $max_attempts ]; then
            echo "FAILED: Could not pull $image after $max_attempts attempts."
            exit 1
        fi
        echo "WARNING: Pull failed (EOF/Network). Retrying in 5 seconds..."
        sleep 5
        ((attempt++))
        echo "--- Pulling $image (Attempt $attempt/$max_attempts) ---"
    done
    echo "SUCCESS: $image downloaded."
}

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

# 3. CLEANUP: Free Disk Space & RAM (Crucial Fix for EOF Errors)
echo "--- Cleaning up Docker Resources ---"
sudo docker container prune -f
sudo docker image prune -f

# 4. Create Data Directories & Fix Permissions
echo "--- Configuring Storage Directories ---"
sudo mkdir -p "$SD_MOUNT/node_red_data"
sudo mkdir -p "$SD_MOUNT/influxdb_data"

echo "--- Setting Permissions ---"
sudo chmod -R 777 "$SD_MOUNT/node_red_data"
sudo chmod -R 777 "$SD_MOUNT/influxdb_data"

# 5. Restart M4 Proxy (Fixes Stale Connections)
echo "--- Restarting M4 Proxy Service ---"
sudo systemctl restart m4-proxy

# 6. Low-Memory Deployment Strategy (With Retries)
pull_with_retry "eclipse-mosquitto:2"
# CHANGED: Use Alpine for smaller size and better reliability
pull_with_retry "influxdb:1.8-alpine" 
pull_with_retry "nodered/node-red:latest"

echo "--- Building Bridge Container ---"
sudo docker compose build bridge

# 7. Launch Docker Stack
echo "--- LAUNCHING CONTAINERS ---"
sudo docker compose up -d

echo "========================================"
echo "         DEPLOYMENT COMPLETE            "
echo "========================================"
echo "Check logs with: sudo docker compose logs -f"
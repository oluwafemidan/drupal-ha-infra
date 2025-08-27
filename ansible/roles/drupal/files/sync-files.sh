#!/bin/bash
# Drupal File Synchronization Script
# This script syncs files between Drupal instances using rsync

set -e

# Configuration
SYNC_USER="syncuser"
SYNC_KEY="/home/syncuser/.ssh/sync_key"
WEB_ROOT="/var/www/html/sites/default/files"
LOG_FILE="/var/log/drupal-sync.log"
TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")

# Get secondary servers from command line or use default
SECONDARY_SERVERS=("${@:-drupal-instance-2}")

echo "[$TIMESTAMP] Starting file synchronization from $(hostname)" | tee -a $LOG_FILE

# Check if web root exists
if [ ! -d "$WEB_ROOT" ]; then
    echo "Error: Web root directory $WEB_ROOT does not exist" | tee -a $LOG_FILE
    exit 1
fi

# Sync to each secondary server
for SERVER in "${SECONDARY_SERVERS[@]}"; do
    echo "Syncing to $SERVER..." | tee -a $LOG_FILE
    
    # Dry run first to see what would be changed
    rsync -avzn -e "ssh -i $SYNC_KEY -o StrictHostKeyChecking=no" \
        --delete \
        --exclude='.git/' \
        --exclude='tmp/' \
        $WEB_ROOT/ $SYNC_USER@$SERVER:$WEB_ROOT/
    
    # Actual sync
    if rsync -avz -e "ssh -i $SYNC_KEY -o StrictHostKeyChecking=no" \
        --delete \
        --exclude='.git/' \
        --exclude='tmp/' \
        $WEB_ROOT/ $SYNC_USER@$SERVER:$WEB_ROOT/; then
        echo "Success: Files synced to $SERVER" | tee -a $LOG_FILE
    else
        echo "Error: Sync failed for $SERVER" | tee -a $LOG_FILE
    fi
done

echo "[$(date +"%Y-%m-%d %H:%M:%S")] File synchronization completed" | tee -a $LOG_FILE
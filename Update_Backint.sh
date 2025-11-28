#!/bin/bash

# Automatic update script for AWS Backint Agent for SAP HANA
# Author: Maxime GIQUEL

set -e  # Exit on error

# Configuration
BACKINT_DIR="/hana/shared/aws-backint-agent"
DOWNLOAD_URL="https://s3.amazonaws.com/awssap-backint-agent/binary/latest/aws-backint-agent.tar.gz"

# Display functions
log_info() {
    echo "[INFO] $1"
}
log_error() {
    echo "[ERROR] $1"
}
log_warn() {
    echo "[WARN] $1"
}

# Check root privileges
if [[ $EUID -ne 0 ]]; then
   log_error "This script must be run as root"
   exit 1
fi

# Check directory existence
if [[ ! -d "$BACKINT_DIR" ]]; then
    log_error "Directory $BACKINT_DIR does not exist"
    exit 1
fi

# Automatic detection of owner, group and permissions of existing binary
if [[ -f "$BACKINT_DIR/aws-backint-agent" ]]; then
    SAP_USER=$(stat -c '%U' "$BACKINT_DIR/aws-backint-agent")
    SAP_GROUP=$(stat -c '%G' "$BACKINT_DIR/aws-backint-agent")
    SAP_CHMOD=$(stat -c '%a' "$BACKINT_DIR/aws-backint-agent")
    log_info "Owner detected: $SAP_USER:$SAP_GROUP ($SAP_CHMOD)"
else
    log_error "Binary aws-backint-agent does not exist in $BACKINT_DIR"
    exit 1
fi

log_info "Starting AWS Backint Agent update"

# 0. Backup existing installation
BACKUP_TIMESTAMP=$(date +"%Y%m%d%H%M%S")
BACKUP_DIR="${BACKINT_DIR}-backup-$BACKUP_TIMESTAMP"
log_info "Creating backup: $BACKUP_DIR"
if cp -r "$BACKINT_DIR" "$BACKUP_DIR"; then
    log_info "Backup created successfully"
else
    log_error "Backup failed"
    exit 1
fi

# 1. Download new version
log_info "Downloading new version..."
cd "$BACKINT_DIR/package"

# Remove old tarball if it exists
if [[ -f "aws-backint-agent.tar.gz" ]]; then
    rm -f aws-backint-agent.tar.gz
    log_info "Old tarball removed"
fi

# Download
if wget -q "$DOWNLOAD_URL"; then
    log_info "Download completed"
else
    log_error "Download failed"
    exit 1
fi

# 2. Extract new binary
log_info "Extracting new binary..."
if tar -xzf aws-backint-agent.tar.gz; then
    log_info "Extraction successful"
else
    log_error "Extraction failed"
    exit 1
fi

# 3. Check existence of new binary
if [[ ! -f "aws-backint-agent" ]]; then
    log_error "Extracted binary not found"
    exit 1
fi

# 4. Replace binary
log_info "Replacing binary..."
cd "$BACKINT_DIR"

# Remove old binary
rm -f aws-backint-agent

# Copy new binary
if cp package/aws-backint-agent aws-backint-agent; then
    log_info "New binary copied"
else
    log_error "Failed to copy new binary"
    exit 1
fi

# Configure permissions
log_info "Configuring permissions..."
chmod $SAP_CHMOD aws-backint-agent
chown $SAP_USER:$SAP_GROUP aws-backint-agent

# 5. Version verification
log_info "Verifying new version..."
NEW_VERSION=$(./aws-backint-agent -V 2>&1 | grep -o 'AWS Backint Agent.*' || echo "Unknown version")
log_info "Installed version: $NEW_VERSION"

# 6. Final summary
log_info "============================================"
log_info "Update completed successfully!"
log_info "Version: $NEW_VERSION"
log_info "============================================"

exit 0

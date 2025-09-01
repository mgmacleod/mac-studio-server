#!/bin/bash

# Post-log-rotation script for Ollama
# This script is called by newsyslog after rotating Ollama logs

USER=${OLLAMA_USER:-$(whoami)}
BASE_DIR=${OLLAMA_BASE_DIR:-"/Users/$USER/mac-studio-server"}
LOG_FILE="$BASE_DIR/logs/log-rotation.log"

log_action() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log_action "Post-rotation: Restarting Ollama service to switch to new log files..."

# Restart the Ollama service to ensure it uses the new log files
sudo launchctl unload /Library/LaunchDaemons/com.ollama.wrapped.service.plist
sleep 2
sudo launchctl load -w /Library/LaunchDaemons/com.ollama.wrapped.service.plist

log_action "Post-rotation: Ollama service restarted"

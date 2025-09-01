#!/bin/bash

# Configuration
USER=${OLLAMA_USER:-$(whoami)}
BASE_DIR=${OLLAMA_BASE_DIR:-"/Users/$USER/mac-studio-server"}
LOG_FILE="$BASE_DIR/logs/ollama-restart.log"

log_action() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log_action "Restarting Ollama..."
sudo launchctl unload /Library/LaunchDaemons/com.ollama.wrapped.service.plist
sudo launchctl load -w /Library/LaunchDaemons/com.ollama.wrapped.service.plist
log_action "Ollama restarted"
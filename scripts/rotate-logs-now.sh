#!/bin/bash

# Manual log rotation script
USER=${OLLAMA_USER:-$(whoami)}
BASE_DIR=${OLLAMA_BASE_DIR:-"/Users/$USER/mac-studio-server"}
LOG_FILE="$BASE_DIR/logs/log-rotation.log"

log_action() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log_action "Manual log rotation initiated..."

# Force rotation using our smart script
"$BASE_DIR/scripts/rotate-ollama-logs.sh" force

log_action "Manual log rotation completed"

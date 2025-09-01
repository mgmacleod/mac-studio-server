#!/bin/bash

# Smart Ollama log rotation script
# This script properly handles log rotation for launchd-managed services

USER=${OLLAMA_USER:-$(whoami)}
BASE_DIR=${OLLAMA_BASE_DIR:-"/Users/$USER/mac-studio-server"}
LOG_FILE="$BASE_DIR/logs/log-rotation.log"

log_action() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Configuration
OLLAMA_LOG="$BASE_DIR/logs/ollama.log"
OLLAMA_ERR="$BASE_DIR/logs/ollama.err"
MAX_SIZE_KB=5000  # 5MB
MAX_COPIES=10

# Function to get file size in KB
get_file_size_kb() {
    local file="$1"
    if [ -f "$file" ]; then
        # Get size in bytes, convert to KB
        local size_bytes=$(stat -f%z "$file" 2>/dev/null || echo 0)
        echo $((size_bytes / 1024))
    else
        echo 0
    fi
}

# Function to rotate a single log file
rotate_log_file() {
    local logfile="$1"
    local max_copies="$2"
    
    if [ ! -f "$logfile" ]; then
        log_action "Skipping rotation of $logfile (file does not exist)"
        return
    fi
    
    local size_kb=$(get_file_size_kb "$logfile")
    log_action "Checking $logfile: ${size_kb}KB (threshold: ${MAX_SIZE_KB}KB)"
    
    if [ "$size_kb" -lt "$MAX_SIZE_KB" ] && [ "$force_mode" != "force" ]; then
        log_action "Skipping rotation of $logfile (under size threshold)"
        return
    fi
    
    log_action "Rotating $logfile..."
    
    # Remove the oldest log if it exists
    if [ -f "${logfile}.${max_copies}.bz2" ]; then
        rm -f "${logfile}.${max_copies}.bz2"
        log_action "Removed oldest log: ${logfile}.${max_copies}.bz2"
    fi
    
    # Shift all existing logs
    for i in $(seq $((max_copies - 1)) -1 1); do
        if [ -f "${logfile}.${i}.bz2" ]; then
            mv "${logfile}.${i}.bz2" "${logfile}.$((i + 1)).bz2"
        fi
    done
    
    # Move current log to .0 and compress
    if [ -f "$logfile" ]; then
        mv "$logfile" "${logfile}.0"
        # Remove existing .0.bz2 if it exists to avoid bzip2 error
        [ -f "${logfile}.0.bz2" ] && rm -f "${logfile}.0.bz2"
        bzip2 "${logfile}.0"
        log_action "Compressed ${logfile}.0 to ${logfile}.0.bz2"
    fi
    
    # Create new empty log file with proper permissions
    touch "$logfile"
    chown "$USER:staff" "$logfile"
    chmod 644 "$logfile"
    log_action "Created new empty $logfile"
}

# Function to restart Ollama service
restart_ollama_service() {
    log_action "Restarting Ollama service to use new log files..."
    
    # Stop the service
    sudo launchctl unload /Library/LaunchDaemons/com.ollama.wrapped.service.plist
    
    # Wait a moment
    sleep 3
    
    # Start the service
    sudo launchctl load -w /Library/LaunchDaemons/com.ollama.wrapped.service.plist
    
    # Wait for service to start
    sleep 5
    
    # Verify service is running
    if sudo launchctl list | grep -q "com.ollama.service"; then
        log_action "✓ Ollama service restarted successfully"
    else
        log_action "✗ Warning: Ollama service may not have restarted properly"
    fi
}

# Main execution
log_action "Starting Ollama log rotation check..."

# Check if we need to rotate any logs
ollama_log_size=$(get_file_size_kb "$OLLAMA_LOG")
ollama_err_size=$(get_file_size_kb "$OLLAMA_ERR")
force_mode="$1"

needs_rotation=false

if [ "$force_mode" = "force" ] || [ "$ollama_log_size" -ge "$MAX_SIZE_KB" ] || [ "$ollama_err_size" -ge "$MAX_SIZE_KB" ]; then
    needs_rotation=true
fi

if [ "$needs_rotation" = "true" ]; then
    log_action "Log rotation needed (ollama.log: ${ollama_log_size}KB, ollama.err: ${ollama_err_size}KB)"
    
    # Rotate the log files
    rotate_log_file "$OLLAMA_LOG" "$MAX_COPIES"
    rotate_log_file "$OLLAMA_ERR" "$MAX_COPIES"
    
    # Restart the service to pick up new log files
    restart_ollama_service
    
    log_action "Ollama log rotation completed"
else
    log_action "No rotation needed (ollama.log: ${ollama_log_size}KB, ollama.err: ${ollama_err_size}KB)"
fi

# Also run newsyslog for other logs
log_action "Running newsyslog for other logs..."
sudo newsyslog -f /etc/newsyslog.d/ollama.conf >/dev/null 2>&1

log_action "Log rotation check completed"

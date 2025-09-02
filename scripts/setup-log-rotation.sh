#!/bin/bash

# Configuration
USER=${OLLAMA_USER:-$(whoami)}
BASE_DIR=${OLLAMA_BASE_DIR:-"/Users/$USER/mac-studio-server"}
LOG_FILE="$BASE_DIR/logs/log-rotation.log"
NEWSYSLOG_CONF="/etc/newsyslog.d/ollama.conf"

log_action() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Create newsyslog.d directory if it doesn't exist
log_action "Setting up newsyslog configuration..."
sudo mkdir -p /etc/newsyslog.d

# Replace user placeholders in config and install
log_action "Installing Ollama newsyslog configuration..."
sed "s|<OLLAMA_USER>|$USER|g" "$BASE_DIR/config/newsyslog-ollama.conf" > "/tmp/ollama.conf"
sudo cp "/tmp/ollama.conf" "$NEWSYSLOG_CONF"
rm "/tmp/ollama.conf"

# Set proper permissions
sudo chown root:wheel "$NEWSYSLOG_CONF"
sudo chmod 644 "$NEWSYSLOG_CONF"

# Test the configuration
log_action "Testing newsyslog configuration..."
if sudo newsyslog -nvf "$NEWSYSLOG_CONF"; then
    log_action "✓ Newsyslog configuration is valid"
else
    log_action "✗ Error in newsyslog configuration"
    exit 1
fi

# Create a manual rotation script for testing/emergency use
# log_action "Creating manual log rotation script..."
# cat > "$BASE_DIR/scripts/rotate-logs-now.sh" << 'EOF'
# #!/bin/bash

# # Manual log rotation script
# USER=${OLLAMA_USER:-$(whoami)}
# BASE_DIR=${OLLAMA_BASE_DIR:-"/Users/$USER/mac-studio-server"}
# LOG_FILE="$BASE_DIR/logs/log-rotation.log"

# log_action() {
#     echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
# }

# log_action "Manual log rotation initiated..."

# # Force rotation using our config
# sudo newsyslog -f /etc/newsyslog.d/ollama.conf

# log_action "Manual log rotation completed"
# EOF

chmod +x "$BASE_DIR/scripts/rotate-logs-now.sh"

log_action "Log rotation setup completed!"
log_action "Configuration installed to: $NEWSYSLOG_CONF"
log_action "Manual rotation script: $BASE_DIR/scripts/rotate-logs-now.sh"
log_action ""
log_action "Log rotation settings:"
log_action "  - Main logs (ollama.log, ollama.err): Rotate at 5MB, keep 10 copies"
log_action "  - Other logs: Rotate at 1MB, keep 5 copies"
log_action "  - Automatic rotation: Daily at 3:00 AM"
log_action "  - Service restart: Ollama restarts after main log rotation"
log_action ""
log_action "To manually rotate logs: ./scripts/rotate-logs-now.sh"
log_action "To test configuration: sudo newsyslog -nv"

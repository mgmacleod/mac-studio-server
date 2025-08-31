#!/bin/bash

# Get user and base directory from environment or use defaults
USER=${OLLAMA_USER:-$(whoami)}
BASE_DIR=${OLLAMA_BASE_DIR:-"/Users/$USER/mac-studio-server"}
LOG_FILE="$BASE_DIR/logs/optimization.log"

log_action() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Disable Spotlight indexing
# log_action "Disabling Spotlight indexing..."
# sudo launchctl unload -w /System/Library/LaunchDaemons/com.apple.metadata.mds.plist

# Disable Time Machine
# log_action "Disabling Time Machine..."
# sudo tmutil disable

# Disable sleep
log_action "Configuring power settings..."
sudo pmset -a sleep 0
sudo pmset -a hibernatemode 0
sudo pmset -a disablesleep 1

# Disable screen saver but keep Screen Sharing enabled
log_action "Configuring display settings..."
defaults write com.apple.screensaver idleTime 0

# Disable automatic updates
# log_action "Disabling automatic updates..."
# sudo defaults write /Library/Preferences/com.apple.SoftwareUpdate AutomaticDownload -bool false
# sudo defaults write /Library/Preferences/com.apple.SoftwareUpdate AutomaticCheckEnabled -bool false

# Disable power nap
log_action "Disabling power nap..."
sudo pmset -a powernap 0

# Disable sudden motion sensor
log_action "Disabling sudden motion sensor..."
sudo pmset -a sms 0

# Keep Screen Sharing enabled but disable other sharing services
# log_action "Configuring sharing services..."
# sudo launchctl unload -w /System/Library/LaunchDaemons/com.apple.AppleFileServer.plist 2>/dev/null || true
# sudo launchctl unload -w /System/Library/LaunchDaemons/com.apple.smbd.plist 2>/dev/null || true

# Disable Handoff
log_action "Disabling Handoff..."
defaults write ~/Library/Preferences/ByHost/com.apple.coreservices.useractivityd ActivityAdvertisingAllowed -bool no
defaults write ~/Library/Preferences/ByHost/com.apple.coreservices.useractivityd ActivityReceivingAllowed -bool no

# Add explicit enable for Screen Sharing
log_action "Ensuring Screen Sharing is enabled..."
sudo defaults write /var/db/launchd.db/com.apple.launchd/overrides.plist com.apple.screensharing -dict Disabled -bool false
sudo launchctl load -w /System/Library/LaunchDaemons/com.apple.screensharing.plist 2>/dev/null || true

log_action "System optimization completed" 
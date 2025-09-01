#!/bin/bash

# Configuration
USER=${OLLAMA_USER:-$(whoami)}
BASE_DIR=${OLLAMA_BASE_DIR:-"/Users/$USER/mac-studio-server"}
LOG_FILE="$BASE_DIR/logs/update-ollama.log"

log_action() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log_action "Updating Ollama..."

# Stop the service
log_action "Stopping Ollama..."
sudo launchctl stop com.ollama.wrapped.service

# Update the service
log_action "Checking for Ollama updates..."

# Get current version
CURRENT_VERSION=$(ollama --version 2>/dev/null | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+' || echo "unknown")
log_action "Current Ollama version: $CURRENT_VERSION"

# Fetch latest release info from GitHub API
log_action "Fetching latest release information from GitHub..."
LATEST_RELEASE_JSON=$(curl -s https://api.github.com/repos/ollama/ollama/releases/latest)

if [ $? -ne 0 ] || [ -z "$LATEST_RELEASE_JSON" ]; then
    log_action "ERROR: Failed to fetch release information from GitHub"
    exit 1
fi

# Extract latest version and download URL
LATEST_VERSION=$(echo "$LATEST_RELEASE_JSON" | grep '"tag_name"' | head -1 | sed 's/.*"tag_name": "\([^"]*\)".*/\1/')
DOWNLOAD_URL=$(echo "$LATEST_RELEASE_JSON" | grep '"browser_download_url".*Ollama-darwin\.zip' | head -1 | sed 's/.*"browser_download_url": "\([^"]*\)".*/\1/')

# Normalize versions by removing 'v' prefix for comparison
CURRENT_VERSION_NORMALIZED=$(echo "$CURRENT_VERSION" | sed 's/^v//')
LATEST_VERSION_NORMALIZED=$(echo "$LATEST_VERSION" | sed 's/^v//')

if [ -z "$LATEST_VERSION" ] || [ -z "$DOWNLOAD_URL" ]; then
    log_action "ERROR: Could not extract version or download URL from GitHub response"
    exit 1
fi

log_action "Latest Ollama version available: $LATEST_VERSION"

# Compare versions (skip update if already latest)
if [ "$CURRENT_VERSION_NORMALIZED" = "$LATEST_VERSION_NORMALIZED" ]; then
    log_action "Ollama is already up to date (version $CURRENT_VERSION)"
    exit 0
fi

log_action "Updating Ollama from $CURRENT_VERSION to $LATEST_VERSION..."

# Create temporary directory for download
TEMP_DIR=$(mktemp -d)
DOWNLOAD_FILE="$TEMP_DIR/Ollama-darwin.zip"

# Download the latest release
log_action "Downloading Ollama $LATEST_VERSION..."
curl -L "$DOWNLOAD_URL" -o "$DOWNLOAD_FILE"

if [ $? -ne 0 ] || [ ! -f "$DOWNLOAD_FILE" ]; then
    log_action "ERROR: Failed to download Ollama from $DOWNLOAD_URL"
    rm -rf "$TEMP_DIR"
    exit 1
fi

# Verify download (basic check for zip file)
if ! file "$DOWNLOAD_FILE" | grep -q "Zip archive"; then
    log_action "ERROR: Downloaded file is not a valid zip archive"
    rm -rf "$TEMP_DIR"
    exit 1
fi

# Backup current installation
log_action "Creating backup of current Ollama installation..."
if [ -d "/Applications/Ollama.app" ]; then
    sudo mv "/Applications/Ollama.app" "/Applications/Ollama.app.backup.$(date +%Y%m%d_%H%M%S)"
    if [ $? -ne 0 ]; then
        log_action "ERROR: Failed to backup current Ollama installation"
        rm -rf "$TEMP_DIR"
        exit 1
    fi
fi

# Extract the new version
log_action "Extracting Ollama $LATEST_VERSION..."
unzip -q "$DOWNLOAD_FILE" -d "$TEMP_DIR"

if [ $? -ne 0 ] || [ ! -d "$TEMP_DIR/Ollama.app" ]; then
    log_action "ERROR: Failed to extract Ollama application"
    # Restore backup if extraction failed
    if [ -d "/Applications/Ollama.app.backup."* ]; then
        log_action "Restoring backup..."
        sudo mv /Applications/Ollama.app.backup.* "/Applications/Ollama.app"
    fi
    rm -rf "$TEMP_DIR"
    exit 1
fi

# Install the new version
log_action "Installing Ollama $LATEST_VERSION..."
sudo mv "$TEMP_DIR/Ollama.app" "/Applications/"

if [ $? -ne 0 ]; then
    log_action "ERROR: Failed to install new Ollama version"
    # Restore backup if installation failed
    if [ -d "/Applications/Ollama.app.backup."* ]; then
        log_action "Restoring backup..."
        sudo mv /Applications/Ollama.app.backup.* "/Applications/Ollama.app"
    fi
    rm -rf "$TEMP_DIR"
    exit 1
fi

# Ensure proper permissions
sudo chown -R root:admin "/Applications/Ollama.app"
sudo chmod -R 755 "/Applications/Ollama.app"

# Recreate symlink if it doesn't exist or is broken
if [ ! -L "/usr/local/bin/ollama" ] || [ ! -e "/usr/local/bin/ollama" ]; then
    log_action "Creating/updating ollama symlink..."
    sudo rm -f "/usr/local/bin/ollama"
    sudo ln -s "/Applications/Ollama.app/Contents/Resources/ollama" "/usr/local/bin/ollama"
fi

# Verify installation
NEW_VERSION=$(ollama --version 2>/dev/null | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+' || echo "unknown")
NEW_VERSION_NORMALIZED=$(echo "$NEW_VERSION" | sed 's/^v//')
if [ "$NEW_VERSION_NORMALIZED" = "$LATEST_VERSION_NORMALIZED" ]; then
    log_action "Successfully updated Ollama to version $NEW_VERSION"
    # Clean up old backup after successful installation
    sudo rm -rf /Applications/Ollama.app.backup.*
else
    log_action "WARNING: Installation may have failed. Expected version $LATEST_VERSION_NORMALIZED, but got $NEW_VERSION"
fi

# Clean up temporary files
rm -rf "$TEMP_DIR"
log_action "Cleanup completed"

# Start the service
log_action "Starting Ollama..."
sudo launchctl start com.ollama.wrapped.service

log_action "Ollama updated"
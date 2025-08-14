#!/bin/bash

# Get user from environment or use default
USER=${OLLAMA_USER:-$(whoami)}
BASE_DIR=${OLLAMA_BASE_DIR:-"/Users/$USER/mac-studio-server"}
ENV_FILE="$BASE_DIR/config/ollama.env"

# Load environment variables from external file if it exists
if [ -f "$ENV_FILE" ]; then
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Loading configuration from $ENV_FILE"
    source "$ENV_FILE"
else
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] No environment file found at $ENV_FILE, using defaults"
fi

# Set defaults if not provided in environment file
export OLLAMA_HOST=${OLLAMA_HOST:-"0.0.0.0:11434"}
export OLLAMA_NUM_PARALLEL=${OLLAMA_NUM_PARALLEL:-"8"}
export OLLAMA_KEEP_ALIVE=${OLLAMA_KEEP_ALIVE:-"30m"}
export OLLAMA_FLASH_ATTENTION=${OLLAMA_FLASH_ATTENTION:-"true"}
export OLLAMA_MAX_LOADED_MODELS=${OLLAMA_MAX_LOADED_MODELS:-"4"}
export OLLAMA_NOPRUNE=${OLLAMA_NOPRUNE:-"true"}

# Log the configuration being used
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Starting Ollama with configuration:"
echo "  OLLAMA_HOST: $OLLAMA_HOST"
echo "  OLLAMA_NUM_PARALLEL: $OLLAMA_NUM_PARALLEL"
echo "  OLLAMA_KEEP_ALIVE: $OLLAMA_KEEP_ALIVE"
echo "  OLLAMA_FLASH_ATTENTION: $OLLAMA_FLASH_ATTENTION"
echo "  OLLAMA_MAX_LOADED_MODELS: $OLLAMA_MAX_LOADED_MODELS"
echo "  OLLAMA_NOPRUNE: $OLLAMA_NOPRUNE"

# Start Ollama
exec /usr/local/bin/ollama serve

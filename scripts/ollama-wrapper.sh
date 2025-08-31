#!/bin/bash

# Get user from environment or use default
USER=${OLLAMA_USER:-$(whoami)}
BASE_DIR=${OLLAMA_BASE_DIR:-"/Users/$USER/mac-studio-server"}
ENV_FILE="$BASE_DIR/config/ollamarc"

# Load environment variables from external file if it exists
if [ -f "$ENV_FILE" ]; then
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Loading configuration from $ENV_FILE"
    source "$ENV_FILE"
else
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] No environment file found at $ENV_FILE, using defaults"
fi

# Log the configuration being used
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Starting Ollama with configuration:"
echo "  OLLAMA_HOST: $OLLAMA_HOST"
echo "  OLLAMA_ORIGINS: $OLLAMA_ORIGINS"
echo "  OLLAMA_KEEP_ALIVE: $OLLAMA_KEEP_ALIVE"
echo "  OLLAMA_FLASH_ATTENTION: $OLLAMA_FLASH_ATTENTION"
echo "  OLLAMA_MAX_LOADED_MODELS: $OLLAMA_MAX_LOADED_MODELS"
echo "  OLLAMA_KV_CACHE_TYPE: $OLLAMA_KV_CACHE_TYPE"
echo "  OLLAMA_DEBUG: $OLLAMA_DEBUG"
echo "  OLLAMA_CONTEXT_LENGTH: $OLLAMA_CONTEXT_LENGTH"

# Start Ollama
exec /usr/local/bin/ollama serve

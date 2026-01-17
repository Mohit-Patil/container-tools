#!/bin/bash
set -e

# =============================================================================
# Entrypoint script for AI CLI Tools Container
# =============================================================================

# Fix ownership of mounted volumes if running as devuser
if [ "$(id -u)" = "1000" ]; then
    # Fix ownership of mounted volumes (they may be owned by root initially)
    sudo chown -R devuser:devuser /home/devuser/.config 2>/dev/null || true
    sudo chown -R devuser:devuser /home/devuser/.claude 2>/dev/null || true
    sudo chown -R devuser:devuser /home/devuser/.codex 2>/dev/null || true
    sudo chown -R devuser:devuser /home/devuser/.aider 2>/dev/null || true

    # Ensure directories exist with correct permissions
    mkdir -p /home/devuser/.config
    mkdir -p /home/devuser/.claude
    mkdir -p /home/devuser/.codex
    mkdir -p /home/devuser/.aider

    # Create tool-specific config directories
    mkdir -p /home/devuser/.config/gh
    mkdir -p /home/devuser/.config/aider
    mkdir -p /home/devuser/.config/amazon-q
fi

# Source environment files if they exist
[ -f /home/devuser/.env ] && source /home/devuser/.env

# Execute the command passed to the container
exec "$@"

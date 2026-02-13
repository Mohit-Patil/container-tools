#!/bin/bash
set -e

# =============================================================================
# Entrypoint script for AI CLI Tools Container
# =============================================================================

# Fix ownership of mounted volumes if running as devuser
if [ "$(id -u)" = "1000" ]; then
    SENTINEL="/home/devuser/.config/.ownership-fixed"

    # Ensure directories exist first
    mkdir -p /home/devuser/.config \
             /home/devuser/.claude \
             /home/devuser/.codex

    # Only run recursive chown on first start (gets slow as volumes grow)
    if [ ! -f "$SENTINEL" ]; then
        sudo chown -R devuser:devuser /home/devuser/.config 2>/dev/null || true
        sudo chown -R devuser:devuser /home/devuser/.claude 2>/dev/null || true
        sudo chown -R devuser:devuser /home/devuser/.codex 2>/dev/null || true
        touch "$SENTINEL"
    fi
fi

# Persist bash history to a volume so it survives container recreation
export HISTFILE=/home/devuser/.config/.bash_history

# Source environment variables safely (env vars only, no function definitions)
if [ -f /home/devuser/.env ]; then
    set -a
    . /home/devuser/.env
    set +a
fi

# Execute the command passed to the container
exec "$@"

#!/bin/bash
# =============================================================================
# Welcome message for AI CLI Tools Container
# Only shown once per container lifecycle to avoid noise in nested shells/tmux
# =============================================================================

WELCOME_SENTINEL="/tmp/.welcome-shown"

if [ -t 1 ] && [ ! -f "$WELCOME_SENTINEL" ]; then
    cat << 'EOF'

========================================================================
                    AI CLI Tools Container
========================================================================

  Available Tools:
    claude, cc    - Claude Code (Anthropic)
    opencode, oc  - OpenCode
    agent         - Cursor CLI
    codex, cx     - OpenAI Codex CLI
    ghcp          - GitHub Copilot CLI

  Agent Teams (Claude Code):
    Enabled by default. Use split-pane mode with tmux:
      claude --teammate-mode tmux
    Or in-process mode (default, no tmux needed):
      claude --teammate-mode in-process

  Commands:
    ai-tools        - List all tools and aliases
    ai-auth-status  - Check authentication status
    ai-check        - Check which tools are installed

  Workspace: /workspace (your project folder)

  Run 'ai-check' to verify which tools are installed.
========================================================================

EOF
    touch "$WELCOME_SENTINEL"
fi

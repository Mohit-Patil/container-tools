#!/bin/bash
# =============================================================================
# Welcome message for AI CLI Tools Container
# =============================================================================

# Only show on interactive shells
if [ -t 1 ]; then
    echo ""
    echo "========================================================================"
    echo "                    AI CLI Tools Container"
    echo "========================================================================"
    echo ""
    echo "  Available Tools:"
    echo "    claude, cc    - Claude Code (Anthropic)"
    echo "    agent         - Cursor CLI"
    echo "    codex, cx     - OpenAI Codex CLI"
    echo "    aider, ai     - AI Pair Programming"
    echo "    ghcp          - GitHub Copilot CLI"
    echo "    gemini, gem   - Google Gemini CLI"
    echo "    q, qchat      - Amazon Q Developer CLI"
    echo ""
    echo "  Commands:"
    echo "    ai-tools        - List all tools and aliases"
    echo "    ai-auth-status  - Check authentication status"
    echo "    ai-login        - Show authentication help"
    echo "    ai-check        - Check which tools are installed"
    echo ""
    echo "  Workspace: /workspace (your project folder)"
    echo ""
    echo "  Credentials (persisted via Docker volumes):"
    echo "    ~/.config  - GitHub CLI, Gemini, Amazon Q, Cursor CLI"
    echo "    ~/.claude  - Claude Code"
    echo "    ~/.codex   - OpenAI Codex"
    echo "    ~/.aider   - Aider"
    echo ""
    echo "========================================================================"
    echo ""
fi

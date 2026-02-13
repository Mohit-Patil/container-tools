#!/bin/bash
# =============================================================================
# AI CLI Tool Aliases and Helper Functions
# =============================================================================

# Conditional aliases — only set if the command exists
command -v claude &>/dev/null && alias cc='claude'
command -v opencode &>/dev/null && alias oc='opencode'
command -v codex &>/dev/null && alias cx='codex'
command -v github-copilot-cli &>/dev/null && alias ghcp='github-copilot-cli'

# =============================================================================
# Helper Functions
# =============================================================================

ai-tools() {
    cat << 'EOF'

=== Available AI CLI Tools ===

Claude Code (Anthropic):
  claude, cc           - Start Claude Code

OpenCode:
  opencode, oc         - Start OpenCode

OpenAI Codex:
  codex, cx            - Start Codex CLI

GitHub Copilot CLI:
  ghcp                 - GitHub Copilot CLI

Cursor CLI:
  agent                - Start Cursor CLI

=== Quick Commands ===
  ai-auth-status       - Check authentication status
  ai-check             - Check which tools are installed

EOF
}

ai-auth-status() {
    echo ""
    echo "=== Authentication Status ==="
    echo ""

    echo -n "GitHub CLI:        "
    if gh auth status &>/dev/null; then
        echo "Authenticated"
    else
        echo "Not authenticated (run: gh auth login)"
    fi

    echo -n "Claude Code:       "
    if [ -f ~/.claude/credentials.json ] || [ -f ~/.claude/.credentials.json ]; then
        echo "Credentials found"
    else
        echo "Not authenticated (run: claude)"
    fi

    echo ""
}

# Check which tools are installed (with timeout to prevent hangs)
ai-check() {
    echo ""
    echo "=== Installed Tools Check ==="
    echo ""

    for cmd in claude opencode codex gh agent; do
        echo -n "$cmd: "
        if command -v $cmd &>/dev/null; then
            version=$(timeout 5 $cmd --version 2>/dev/null | head -1 || echo "installed")
            echo "$version"
        else
            echo "not found"
        fi
    done
    echo ""
}

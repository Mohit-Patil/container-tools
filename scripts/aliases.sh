#!/bin/bash
# =============================================================================
# AI CLI Tool Aliases and Helper Functions
# =============================================================================

# --- Claude Code ---
alias cc='claude'
alias claude-chat='claude --chat'

# --- OpenAI Codex ---
alias cx='codex'

# --- Aider ---
alias ai='aider'
alias aider-sonnet='aider --model sonnet'
alias aider-gpt4='aider --model gpt-4'
alias aider-opus='aider --model opus'

# --- GitHub Copilot CLI ---
alias ghcp='github-copilot-cli'

# --- Gemini CLI ---
alias gem='gemini'

# --- Amazon Q ---
alias qchat='q chat'

# =============================================================================
# Helper Functions
# =============================================================================

# Show all available AI tools
ai-tools() {
    echo ""
    echo "=== Available AI CLI Tools ==="
    echo ""
    echo "Claude Code (Anthropic):"
    echo "  claude, cc           - Start Claude Code"
    echo "  claude --chat        - Chat mode"
    echo ""
    echo "OpenAI Codex:"
    echo "  codex, cx            - Start Codex CLI"
    echo ""
    echo "Aider:"
    echo "  aider, ai            - Start Aider"
    echo "  aider-sonnet         - Aider with Claude Sonnet"
    echo "  aider-gpt4           - Aider with GPT-4"
    echo "  aider-opus           - Aider with Claude Opus"
    echo ""
    echo "GitHub Copilot CLI:"
    echo "  ghcp                 - GitHub Copilot CLI"
    echo ""
    echo "Gemini CLI:"
    echo "  gemini, gem          - Google Gemini CLI"
    echo ""
    echo "Amazon Q Developer:"
    echo "  q, qchat             - Amazon Q CLI"
    echo ""
    echo "=== Quick Commands ==="
    echo "  ai-auth-status       - Check authentication status"
    echo "  ai-login             - Show authentication help"
    echo ""
}

# Check authentication status for all tools
ai-auth-status() {
    echo ""
    echo "=== Authentication Status ==="
    echo ""

    # GitHub CLI
    echo -n "GitHub CLI:        "
    if gh auth status &>/dev/null; then
        echo "Authenticated"
    else
        echo "Not authenticated (run: gh auth login)"
    fi

    # Claude Code
    echo -n "Claude Code:       "
    if [ -f ~/.claude/credentials.json ] || [ -d ~/.claude ] && [ "$(ls -A ~/.claude 2>/dev/null)" ]; then
        echo "Credentials may exist (check with: claude)"
    else
        echo "Not authenticated (run: claude)"
    fi

    # Aider
    echo -n "Aider:             "
    if [ -n "$ANTHROPIC_API_KEY" ] || [ -n "$OPENAI_API_KEY" ]; then
        echo "API key(s) set"
    else
        echo "No API keys set (set ANTHROPIC_API_KEY or OPENAI_API_KEY)"
    fi

    # Amazon Q
    echo -n "Amazon Q:          "
    if command -v q &>/dev/null; then
        echo "Installed (run: q login to authenticate)"
    else
        echo "Not installed"
    fi

    # Gemini
    echo -n "Gemini CLI:        "
    if command -v gemini &>/dev/null; then
        echo "Installed (run: gemini to authenticate)"
    else
        echo "Not installed"
    fi

    echo ""
}

# Quick login helper
ai-login() {
    echo ""
    echo "=== AI Tool Authentication Helper ==="
    echo ""
    echo "1. GitHub (for Copilot CLI):"
    echo "   gh auth login"
    echo ""
    echo "2. Claude Code:"
    echo "   claude"
    echo "   (Follow OAuth prompts in browser)"
    echo ""
    echo "3. OpenAI Codex:"
    echo "   codex"
    echo "   (Follow OAuth prompts or set OPENAI_API_KEY)"
    echo ""
    echo "4. Aider (set API keys):"
    echo "   export ANTHROPIC_API_KEY=your-key"
    echo "   export OPENAI_API_KEY=your-key"
    echo ""
    echo "5. Amazon Q:"
    echo "   q login"
    echo "   (Use AWS Builder ID)"
    echo ""
    echo "6. Gemini CLI:"
    echo "   gemini"
    echo "   (Follow Google OAuth prompts)"
    echo ""
    echo "Tip: Authentication is persisted in the config volume."
    echo "     You only need to login once per tool."
    echo ""
}

# Check which tools are installed
ai-check() {
    echo ""
    echo "=== Installed Tools Check ==="
    echo ""

    for cmd in claude codex aider gh gemini q; do
        echo -n "$cmd: "
        if command -v $cmd &>/dev/null; then
            version=$($cmd --version 2>/dev/null | head -1 || echo "installed")
            echo "$version"
        else
            echo "not found"
        fi
    done
    echo ""
}

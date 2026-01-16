# =============================================================================
# AI CLI Tools Container
# Base: Ubuntu 24.04 with full development environment
# Includes: Claude Code, Codex, Aider, GitHub Copilot CLI, Gemini CLI, Amazon Q
# =============================================================================
FROM ubuntu:24.04

LABEL maintainer="container-tools"
LABEL description="Multi-tool AI CLI container with Claude Code, Codex, Aider, and more"
LABEL version="1.0.0"

# Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC

# =============================================================================
# Layer 1: System packages and build tools
# =============================================================================
RUN apt-get update && apt-get install -y --no-install-recommends \
    # Build essentials
    build-essential \
    gcc \
    g++ \
    make \
    cmake \
    # Version control
    git \
    git-lfs \
    # Editors and utilities
    vim \
    nano \
    less \
    tree \
    htop \
    # Network tools
    curl \
    wget \
    # Data processing
    jq \
    # Archive tools
    zip \
    unzip \
    tar \
    # Process management
    tmux \
    screen \
    # SSL and security
    ca-certificates \
    gnupg \
    openssh-client \
    # Misc utilities
    sudo \
    locales \
    tzdata \
    && rm -rf /var/lib/apt/lists/*

# Set locale
RUN locale-gen en_US.UTF-8
ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8

# =============================================================================
# Layer 2: Python installation (Python 3.12)
# =============================================================================
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3.12 \
    python3.12-venv \
    python3.12-dev \
    python3-pip \
    pipx \
    && rm -rf /var/lib/apt/lists/* \
    && update-alternatives --install /usr/bin/python python /usr/bin/python3.12 1 \
    && update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.12 1

# =============================================================================
# Layer 3: Node.js installation (Node.js 22 LTS via NodeSource)
# =============================================================================
RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
    && apt-get install -y nodejs \
    && rm -rf /var/lib/apt/lists/* \
    && npm install -g npm@latest

# =============================================================================
# Layer 4: GitHub CLI installation
# =============================================================================
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg \
    && chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
    && apt-get update \
    && apt-get install -y gh \
    && rm -rf /var/lib/apt/lists/*

# =============================================================================
# Layer 5: Create non-root user
# =============================================================================
ARG USERNAME=devuser
ARG USER_UID=1000
ARG USER_GID=1000

# Remove existing ubuntu user and create devuser
# Ubuntu 24.04 comes with 'ubuntu' user at UID 1000
RUN userdel -r ubuntu 2>/dev/null || true \
    && groupdel ubuntu 2>/dev/null || true \
    && groupadd --gid ${USER_GID} ${USERNAME} \
    && useradd --uid ${USER_UID} --gid ${USER_GID} -m -s /bin/bash ${USERNAME} \
    && echo "${USERNAME} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/${USERNAME} \
    && chmod 0440 /etc/sudoers.d/${USERNAME}

# =============================================================================
# Layer 6: AI CLI Tools Installation (as root for global install)
# =============================================================================

# --- Claude Code (Anthropic) ---
RUN npm install -g @anthropic-ai/claude-code || echo "Claude Code installation skipped (may not be available)"

# --- OpenAI Codex CLI ---
RUN npm install -g @openai/codex || echo "Codex installation skipped (may not be available)"

# --- GitHub Copilot CLI ---
RUN npm install -g @githubnext/github-copilot-cli || echo "GitHub Copilot CLI installation skipped"

# --- Gemini CLI (Google) ---
RUN npm install -g @anthropic-ai/gemini-cli || npm install -g gemini-cli || npm install -g @anthropic-ai/gemini-cli 2>/dev/null || echo "Gemini CLI installation skipped"

# --- Aider (pip-based) ---
# Use --ignore-installed to bypass system package conflicts
RUN pip install --break-system-packages --ignore-installed packaging \
    && pip install --break-system-packages aider-chat || echo "Aider installation skipped"

# --- Amazon Q Developer CLI ---
# Detect architecture and download appropriate binary
RUN ARCH=$(dpkg --print-architecture) \
    && if [ "$ARCH" = "amd64" ]; then \
        cd /tmp \
        && curl --proto '=https' --tlsv1.2 -sSf "https://desktop-release.q.us-east-1.amazonaws.com/latest/q-x86_64-linux.zip" -o "q.zip" \
        && unzip -q q.zip \
        && ./q/install.sh --install-dir /opt/amazon-q --bin-dir /usr/local/bin 2>/dev/null \
        && rm -rf q.zip q/; \
    else \
        echo "Amazon Q: No ARM64 binary available, skipping"; \
    fi || true

# =============================================================================
# Layer 7: User configuration and setup
# =============================================================================
USER ${USERNAME}
WORKDIR /home/${USERNAME}

# Create necessary directories
RUN mkdir -p /home/${USERNAME}/.config \
    /home/${USERNAME}/.local/bin \
    /home/${USERNAME}/.cache \
    /home/${USERNAME}/.claude \
    /home/${USERNAME}/.codex \
    /home/${USERNAME}/.bashrc.d

# Add local bin to PATH
ENV PATH="/home/${USERNAME}/.local/bin:${PATH}"

# =============================================================================
# Layer 8: Copy configuration files
# =============================================================================
COPY --chown=${USERNAME}:${USERNAME} scripts/aliases.sh /home/${USERNAME}/.aliases.sh
COPY --chown=${USERNAME}:${USERNAME} scripts/welcome.sh /home/${USERNAME}/.welcome.sh
COPY --chown=${USERNAME}:${USERNAME} config/bashrc /home/${USERNAME}/.bashrc.d/ai-tools.sh
COPY --chown=${USERNAME}:${USERNAME} scripts/entrypoint.sh /home/${USERNAME}/entrypoint.sh

# Make scripts executable and update .bashrc
RUN chmod +x /home/${USERNAME}/entrypoint.sh \
    && chmod +x /home/${USERNAME}/.aliases.sh \
    && chmod +x /home/${USERNAME}/.welcome.sh \
    && echo '[ -f ~/.aliases.sh ] && source ~/.aliases.sh' >> /home/${USERNAME}/.bashrc \
    && echo '[ -f ~/.welcome.sh ] && source ~/.welcome.sh' >> /home/${USERNAME}/.bashrc \
    && echo '[ -f ~/.bashrc.d/ai-tools.sh ] && source ~/.bashrc.d/ai-tools.sh' >> /home/${USERNAME}/.bashrc

# =============================================================================
# Volume mount points
# =============================================================================
# Mount points for code and persistent auth/config data
# Different tools store credentials in different locations:
#   - Claude Code: ~/.claude/
#   - Codex: ~/.codex/
#   - GitHub CLI: ~/.config/gh/
#   - Aider: ~/.aider/ or ~/.config/aider/
#   - Amazon Q: ~/.config/amazon-q/
VOLUME ["/workspace", "/home/devuser/.claude", "/home/devuser/.codex", "/home/devuser/.config", "/home/devuser/.aider"]

# Working directory
WORKDIR /workspace

# =============================================================================
# Entrypoint
# =============================================================================
ENTRYPOINT ["/home/devuser/entrypoint.sh"]
CMD ["/bin/bash"]

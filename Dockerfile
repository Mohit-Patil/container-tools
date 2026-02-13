# =============================================================================
# AI CLI Tools Container
# Runtime: ubuntu:24.04 (Noble Numbat)
# Includes: Claude Code, OpenCode, Cursor CLI, Codex, GitHub Copilot CLI
# =============================================================================
FROM ubuntu:24.04

LABEL maintainer="container-tools"
LABEL description="Multi-tool AI CLI container with Claude Code, OpenCode, Codex, and more"
LABEL version="2.0.0"

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC

# --- Node.js 22 via NodeSource ---
RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates curl gnupg \
    && curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
    && apt-get install -y --no-install-recommends nodejs \
    && rm -rf /var/lib/apt/lists/*

# --- Runtime system packages ---
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    curl \
    jq \
    unzip \
    less \
    ca-certificates \
    gnupg \
    openssh-client \
    sudo \
    locales \
    # Core utilities for AI CLI tools
    grep \
    findutils \
    sed \
    gawk \
    coreutils \
    diffutils \
    procps \
    # Claude Code dependencies (system rg is faster than bundled)
    ripgrep \
    fzf \
    fd-find \
    # Common interactive shell utilities
    vim \
    tree \
    && sed -i '/en_US.UTF-8/s/^# //' /etc/locale.gen \
    && locale-gen \
    && rm -rf /var/lib/apt/lists/* \
    && ln -sf /usr/bin/fdfind /usr/local/bin/fd

ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8
# Use system ripgrep instead of bundled one (faster on large codebases)
ENV USE_BUILTIN_RIPGREP=0

# --- GitHub CLI (direct .deb install) ---
RUN ARCH=$(dpkg --print-architecture) \
    && curl -fsSL "https://github.com/cli/cli/releases/latest/download/gh_$(curl -fsSL https://api.github.com/repos/cli/cli/releases/latest | grep -oP '"tag_name":\s*"v\K[^"]+')_linux_${ARCH}.deb" -o /tmp/gh.deb \
    && dpkg -i /tmp/gh.deb \
    && rm -f /tmp/gh.deb

# --- Create non-root user ---
ARG USERNAME=devuser
ARG USER_UID=1000
ARG USER_GID=1000

# Ubuntu 24.04 ships with an 'ubuntu' user at UID 1000 — remove it first
RUN userdel -r ubuntu 2>/dev/null || true \
    && groupdel ubuntu 2>/dev/null || true \
    && groupadd --gid ${USER_GID} ${USERNAME} 2>/dev/null || true \
    && useradd --uid ${USER_UID} --gid ${USER_GID} -m -s /bin/bash ${USERNAME} \
    && echo "${USERNAME} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/${USERNAME} \
    && chmod 0440 /etc/sudoers.d/${USERNAME}

# --- npm-based AI tools (single layer, cache cleaned) ---
RUN (npm install -g @openai/codex || true) \
    && (npm install -g @githubnext/github-copilot-cli || true) \
    && npm cache clean --force \
    && rm -rf /root/.npm

# Allow devuser to manage global npm packages for self-updates
RUN NPM_PREFIX=$(npm config get prefix) \
    && chown -R ${USER_UID}:${USER_GID} ${NPM_PREFIX}/lib/node_modules ${NPM_PREFIX}/bin

# =============================================================================
# User setup and tool installation
# =============================================================================
USER ${USERNAME}
WORKDIR /home/${USERNAME}

RUN mkdir -p /home/${USERNAME}/.config \
    /home/${USERNAME}/.local/bin \
    /home/${USERNAME}/.cache \
    /home/${USERNAME}/.claude \
    /home/${USERNAME}/.codex \
    /home/${USERNAME}/.bashrc.d

ENV PATH="/home/${USERNAME}/.local/bin:${PATH}"

# --- Claude Code (native installer, binary moved outside ~/.claude volume) ---
RUN curl -fsSL https://claude.ai/install.sh | bash \
    && mv ~/.claude/local ~/.claude-code \
    && ln -sf ~/.claude-code/bin/claude ~/.local/bin/claude \
    || echo "Claude Code installation skipped"

# --- OpenCode (installer puts binary in ~/.opencode/bin/) ---
RUN curl -fsSL https://opencode.ai/install | bash \
    && ln -sf ~/.opencode/bin/opencode ~/.local/bin/opencode \
    || echo "OpenCode installation skipped"

# --- Cursor CLI ---
RUN curl -fsSL https://cursor.com/install | bash || echo "Cursor CLI installation skipped"

# =============================================================================
# Configuration files
# =============================================================================
COPY --chown=${USERNAME}:${USERNAME} scripts/aliases.sh /home/${USERNAME}/.aliases.sh
COPY --chown=${USERNAME}:${USERNAME} scripts/welcome.sh /home/${USERNAME}/.welcome.sh
COPY --chown=${USERNAME}:${USERNAME} config/bashrc /home/${USERNAME}/.bashrc.d/ai-tools.sh
COPY --chown=${USERNAME}:${USERNAME} scripts/entrypoint.sh /home/${USERNAME}/entrypoint.sh

RUN chmod +x /home/${USERNAME}/entrypoint.sh \
    && chmod +x /home/${USERNAME}/.aliases.sh \
    && chmod +x /home/${USERNAME}/.welcome.sh \
    && echo '[ -f ~/.aliases.sh ] && source ~/.aliases.sh' >> /home/${USERNAME}/.bashrc \
    && echo '[ -f ~/.welcome.sh ] && source ~/.welcome.sh' >> /home/${USERNAME}/.bashrc \
    && echo '[ -f ~/.bashrc.d/ai-tools.sh ] && source ~/.bashrc.d/ai-tools.sh' >> /home/${USERNAME}/.bashrc

# =============================================================================
# Smoke tests
# =============================================================================
COPY --chown=${USERNAME}:${USERNAME} scripts/test-tools.sh /home/${USERNAME}/test-tools.sh
RUN chmod +x /home/${USERNAME}/test-tools.sh \
    && /home/${USERNAME}/test-tools.sh

# Working directory (volumes managed by docker-compose.yml)
WORKDIR /workspace

ENTRYPOINT ["/home/devuser/entrypoint.sh"]
CMD ["/bin/bash"]

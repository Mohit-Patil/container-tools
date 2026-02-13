# AI CLI Tools Container

A Docker container bundling AI coding CLI tools into a single development environment. Run Claude Code, OpenCode, Codex, and more from a container with your code mounted as a volume.

## Included Tools

| Tool | Command | Authentication |
|------|---------|----------------|
| [Claude Code](https://github.com/anthropics/claude-code) | `claude`, `cc` | OAuth (Anthropic) |
| [OpenCode](https://opencode.ai) | `opencode`, `oc` | OAuth |
| [Cursor CLI](https://cursor.com) | `agent` | OAuth (Cursor) |
| [OpenAI Codex](https://github.com/openai/codex) | `codex`, `cx` | ChatGPT / API Key |
| [GitHub Copilot CLI](https://github.com/github/copilot-cli) | `ghcp` | GitHub OAuth |
| [GitHub CLI](https://cli.github.com/) | `gh` | GitHub OAuth |

## Quick Start

### 1. Build the container

```bash
make build
```

### 2. Run an interactive shell

```bash
make run
```

This mounts your current directory to `/workspace` inside the container.

### 3. Authenticate tools (inside container)

```bash
# GitHub (required for Copilot CLI)
gh auth login

# Claude Code
claude

# Cursor CLI
agent
```

### 4. Start coding with AI

```bash
# Use Claude Code
claude "explain this codebase"

# Use OpenCode
opencode

# Use Codex
codex "write unit tests for this file"
```

## Usage

### Using Make (Recommended)

```bash
# Build the container
make build

# Run interactive shell (current directory mounted)
make run

# Attach to running container
make shell

# Run with environment file
make run-with-env

# Run with host network (for OAuth callbacks)
make run-host-network

# Stop container
make stop

# Remove container
make clean

# Backup authentication data
make backup-config

# Restore authentication data
make restore-config
```

### Using Docker Compose

```bash
# Start container
docker-compose up -d

# Shell into container
docker-compose exec ai-tools bash

# Stop container
docker-compose down
```

### Global Command (Run from Any Directory)

Install the `ai-container` command to launch the container from any project folder:

```bash
# Create symlink (one-time setup)
sudo ln -s /path/to/container-tools/bin/ai-container /usr/local/bin/ai-container
```

Then use it from anywhere:

```bash
cd /path/to/any/project
ai-container

# Or specify a directory explicitly
ai-container /path/to/project
```

### Using Docker Directly

```bash
# Run with current directory mounted
docker run -it --rm \
  -v $(pwd):/workspace \
  -v ai-cli-config:/home/devuser/.config \
  -v ai-cli-claude:/home/devuser/.claude \
  -v ai-cli-codex:/home/devuser/.codex \
  -v ~/.gitconfig:/home/devuser/.gitconfig:ro \
  -v ~/.ssh:/home/devuser/.ssh:ro \
  ai-cli-tools:latest
```

## Persistent Authentication

Authentication tokens are stored in Docker named volumes that persist between container runs. You only need to authenticate once per tool, and credentials are shared across all projects.

### How It Works

| Volume | Container Path | Tools |
|--------|----------------|-------|
| `ai-cli-config` | `~/.config` | GitHub CLI, Cursor CLI |
| `ai-cli-claude` | `~/.claude` | Claude Code |
| `ai-cli-codex` | `~/.codex` | OpenAI Codex |

### Credentials Shared Across Projects

Since volumes are managed by Docker (not tied to any project folder), your credentials work everywhere:

```
Project A (/Users/you/app1)     ─┐
Project B (/Users/you/app2)      ├──► Same volumes ──► Same credentials
Project C (/Users/you/backend)  ─┘
```

### View Volumes

```bash
docker volume ls | grep ai-cli
```

### Backup and Restore

```bash
# Backup authentication data
make backup-config

# Restore authentication data
make restore-config
```

### Reset Authentication

```bash
# Remove all saved authentication (requires confirmation)
make clean-volume
```

## Git and SSH Configuration

The container automatically mounts your host's Git configuration and SSH keys (read-only) to enable seamless git operations and SSH-based authentication:

**Mounted files:**
- `~/.gitconfig` → Container's `~/.gitconfig` (read-only)
- `~/.ssh/` → Container's `~/.ssh/` (read-only)

**What this enables:**
- Git commits use your name and email from host
- SSH keys work for git operations (GitHub, GitLab, etc.)
- No need to configure git identity inside container

**Note:** SSH keys are mounted read-only for security. If you need to generate new keys, do it on your host machine.

## Testing Tools

Smoke tests run automatically during `docker build` to verify all tools start:

```bash
# Tests run during build
docker build -t ai-cli-tools:latest .

# Run tests on a running container
docker compose exec ai-tools ~/test-tools.sh
```

Tests verify: `claude`, `opencode`, `codex`, `cursor`, `gh`, `git`, `node` — each with a 10-second timeout.

## Helper Commands (Inside Container)

| Command | Description |
|---------|-------------|
| `ai-tools` | List all available tools and aliases |
| `ai-auth-status` | Check authentication status |
| `ai-check` | Check which tools are installed |

## Environment Variables

Copy `.env.example` to `.env` and configure:

```bash
cp .env.example .env
```

| Variable | Description |
|----------|-------------|
| `OPENAI_API_KEY` | For Codex with OpenAI models |
| `GH_TOKEN` | For non-interactive GitHub auth |

## Project Structure

```
container-tools/
├── Dockerfile              # Multi-stage container image (node:22-slim)
├── docker-compose.yml      # Docker Compose configuration
├── Makefile                # Build and run automation
├── .env.example            # Environment variable template
├── .dockerignore           # Build context exclusions
├── README.md               # This file
├── bin/
│   └── ai-container       # Standalone launcher script
├── scripts/
│   ├── entrypoint.sh      # Container entrypoint
│   ├── aliases.sh         # Tool aliases and helpers
│   ├── welcome.sh         # Welcome banner
│   ├── test-tools.sh      # Smoke tests for all tools
│   └── run-tests.sh       # Test runner helper
└── config/
    └── bashrc             # Shell configuration
```

## Troubleshooting

### OAuth Callbacks Not Working

Some tools require OAuth callbacks. If login fails, try running with host network:

```bash
make run-host-network
```

### Permission Issues

The container runs as `devuser` (UID 1000). If you have permission issues with mounted files:

```bash
# Option 1: Match your host UID
docker run -it --rm -u $(id -u):$(id -g) ...

# Option 2: Fix permissions on host
sudo chown -R $(id -u):$(id -g) /path/to/code
```

### Tool Not Found

Some tools may fail to install during build. Check installation status:

```bash
ai-check
```

### GitHub CLI Keyring Issues

If `gh auth login` fails with keyring errors:

```bash
# Use token-based auth
export GH_TOKEN=your_token
gh auth status
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## License

MIT License - feel free to use and modify as needed.

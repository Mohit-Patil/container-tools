# AI CLI Tools Container

A Docker container bundling all major AI coding CLI tools into a single development environment. Run Claude Code, Codex, Aider, and more from a container with your code mounted as a volume.

## Included Tools

| Tool | Command | Authentication |
|------|---------|----------------|
| [Claude Code](https://github.com/anthropics/claude-code) | `claude`, `cc` | OAuth (Anthropic) |
| [Cursor CLI](https://cursor.com) | `agent` | OAuth (Cursor) |
| [OpenAI Codex](https://github.com/openai/codex) | `codex`, `cx` | ChatGPT / API Key |
| [Aider](https://github.com/Aider-AI/aider) | `aider`, `ai` | API Keys |
| [GitHub Copilot CLI](https://github.com/github/copilot-cli) | `ghcp` | GitHub OAuth |
| [Gemini CLI](https://github.com/google-gemini/gemini-cli) | `gemini`, `gem` | Google Account |
| [Amazon Q](https://github.com/aws/amazon-q-developer-cli) | `q`, `qchat` | AWS Builder ID |
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
# Show authentication help
ai-login

# GitHub (required for Copilot CLI)
gh auth login

# Claude Code
claude

# Cursor CLI
agent

# Amazon Q
q login

# Gemini
gemini
```

### 4. Start coding with AI

```bash
# Use Claude Code
claude "explain this codebase"

# Use Aider
aider --model sonnet

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
  -v ai-cli-aider:/home/devuser/.aider \
  -v ~/.gitconfig:/home/devuser/.gitconfig:ro \
  -v ~/.ssh:/home/devuser/.ssh:ro \
  ai-cli-tools:latest

# Run with specific directory
docker run -it --rm \
  -v /path/to/your/code:/workspace \
  -v ai-cli-config:/home/devuser/.config \
  -v ai-cli-claude:/home/devuser/.claude \
  -v ai-cli-codex:/home/devuser/.codex \
  -v ai-cli-aider:/home/devuser/.aider \
  -v ~/.gitconfig:/home/devuser/.gitconfig:ro \
  -v ~/.ssh:/home/devuser/.ssh:ro \
  ai-cli-tools:latest
```

## Persistent Authentication

Authentication tokens are stored in Docker named volumes that persist between container runs. You only need to authenticate once per tool, and credentials are shared across all projects.

### How It Works

Different AI tools store credentials in different locations. We use separate named volumes for each:

| Volume | Container Path | Tools |
|--------|----------------|-------|
| `ai-cli-config` | `~/.config` | GitHub CLI, Gemini, Amazon Q, Cursor CLI (`~/.config/Cursor/`) |
| `ai-cli-claude` | `~/.claude` | Claude Code |
| `ai-cli-codex` | `~/.codex` | OpenAI Codex |
| `ai-cli-aider` | `~/.aider` | Aider |

### Credentials Shared Across Projects

Since volumes are managed by Docker (not tied to any project folder), your credentials work everywhere:

```
Project A (/Users/you/app1)     ─┐
Project B (/Users/you/app2)      ├──► Same volumes ──► Same credentials
Project C (/Users/you/backend)  ─┘
```

**Example:**
```bash
# First time - login once
cd ~/projects/app1
ai-container
claude   # Login via OAuth
# Exit

# Later - different project, already authenticated
cd ~/work/backend
ai-container
claude   # Already logged in!
```

### View Volumes

```bash
docker volume ls | grep ai-cli
```

### Backup and Restore

```bash
# Backup authentication data
make backup-config
# Creates: ai-cli-config-backup.tar.gz

# Restore authentication data
make restore-config
# Restores from: ai-cli-config-backup.tar.gz
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
- SSH agent forwarding works automatically

**Note:** SSH keys are mounted read-only for security. If you need to generate new keys, do it on your host machine.

## Helper Commands (Inside Container)

| Command | Description |
|---------|-------------|
| `ai-tools` | List all available tools and aliases |
| `ai-auth-status` | Check authentication status for all tools |
| `ai-login` | Show authentication instructions |
| `ai-check` | Check which tools are installed |

## Environment Variables

Copy `.env.example` to `.env` and configure API keys:

```bash
cp .env.example .env
```

Key variables:

| Variable | Description |
|----------|-------------|
| `ANTHROPIC_API_KEY` | For Aider with Claude models |
| `OPENAI_API_KEY` | For Aider/Codex with OpenAI models |
| `GH_TOKEN` | For non-interactive GitHub auth |
| `GOOGLE_API_KEY` | For Gemini CLI |

Then run with:

```bash
make run-with-env
```

## Project Structure

```
container-tools/
├── Dockerfile              # Container image definition
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
│   └── welcome.sh         # Welcome banner
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


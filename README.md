```
   _____ _____ _______   _____  ______ _               __   __
  / ____|_   _|__   __| |  __ \|  ____| |        /\    \ \ / /
 | |  __  | |    | |    | |__) | |__  | |       /  \    \ V /
 | | |_ | | |    | |    |  _  /|  __| | |      / /\ \    > <
 | |__| |_| |_   | |    | | \ \| |____| |____ / ____ \  / . \
  \_____|_____|  |_|    |_|  \_\______|______/_/    \_\/_/ \_\
```

AI-powered Git workflow assistant. Generate commit messages, create PRs, and review code - all with AI.

## Installation

### Quick Install (Recommended)

```bash
curl -fsSL https://raw.githubusercontent.com/porameht/git-relax/main/install.sh | sh
```

### Cargo

```bash
cargo install git-relax
```

### From Source

```bash
git clone https://github.com/porameht/git-relax.git
cd git-relax
cargo install --path .
```

## Setup

```bash
# Set API key (choose one)
export OPENAI_API_KEY="sk-..."
# or
export ANTHROPIC_API_KEY="sk-ant-..."

# For GitHub features
export GITHUB_TOKEN="ghp_..."
```

Add to `~/.zshrc` or `~/.bashrc` for persistence.

## Usage

```bash
git-relax              # Interactive menu
git-relax cm           # Generate commit message
git-relax pr           # Create pull request
git-relax rv           # AI code review
git-relax rv 123       # Review specific PR
git-relax config       # Check configuration
```

## Features

### Commit Messages

```bash
git add .
git-relax cm
```

- Conventional commits format
- Breaking change detection
- AI-generated from staged diff

### Pull Requests

```bash
git-relax pr
```

- Auto-generated title and description
- Changelog from diff
- JIRA/issue linking

### Code Review

```bash
git-relax rv
```

- Security vulnerability scan
- Performance suggestions
- Inline comments on specific lines

## Configuration

| Variable | Description | Default |
|----------|-------------|---------|
| `OPENAI_API_KEY` | OpenAI API key | - |
| `ANTHROPIC_API_KEY` | Anthropic API key | - |
| `OPENAI_MODEL` | OpenAI model | `gpt-4o-mini` |
| `ANTHROPIC_MODEL` | Anthropic model | `claude-3-5-haiku-latest` |
| `GITHUB_TOKEN` | GitHub token | - |

## Why Rust?

| | Before (Bash) | After (Rust) |
|---|---|---|
| Dependencies | git, gh, gum, mods, jq | None |
| Install | 8 steps | 1 command |
| Binary | ~50KB script | 2.3MB single binary |
| Platform | Unix only | Windows, macOS, Linux |

## License

MIT

# git-relax

AI-powered commit & PR generator.

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/porameht/git-relax/main/install.sh | sh
```

Or via Cargo:

```bash
cargo install git-relax
```

Or from source:

```bash
git clone https://github.com/porameht/git-relax.git
cd git-relax
cargo install --path .
```

## Setup

```bash
export OPENROUTER_API_KEY="sk-..."  # recommended
# or
export OPENAI_API_KEY="sk-..."
```

## Usage

```bash
git-relax          # Interactive menu
git-relax commit   # Generate commit message
git-relax pull     # Create PR with AI description
```

## License

MIT

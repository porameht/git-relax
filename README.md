# Git-Relax 🚀 

A smart Git workflow assistant that standardizes commit messages and pull request descriptions using AI-powered suggestions and conventional commit formats.


## 🌟 Features

- **Intelligent Commit Messages**: Generate well-formatted commits following industry standards
- **AI-Powered PR Creation**: Automatically craft meaningful pull request titles and descriptions
- **Flexible Message Formats**:
  - Conventional commit format support
  - Long-form and concise message options
  - Customizable prompts for different team needs

## 🔧 Prerequisites

Ensure the following tools are installed:

- Git
- GitHub CLI (`gh`)
- Gum
- Mods (AI command-line tool)
- OpenAI API Key

### Installation Steps

1. Install Required Tools
```bash
# macOS (using Homebrew)
brew install gh
brew install charmbracelet/tap/mods
brew install gum
```

2. Set Up OpenAI API Key
- Create an account at OpenAI
- Generate an API key
- Set the environment variable:
```bash
export OPENAI_API_KEY='your_openai_api_key'
```

3. Clone and Install Git-Relax
```bash
git clone https://github.com/yourusername/git-relax.git
cd git-relax
chmod +x git-relax.sh
cp git-relax.sh ~/.local/bin/git-relax
```

4. Add to PATH
```bash
echo 'export PATH=$PATH:~/.local/bin' >> ~/.bashrc
# Or for zsh users
echo 'export PATH=$PATH:~/.local/bin' >> ~/.zshrc
```

## 🎮 Usage

### Commit Messages
```bash
git-relax cm
```

### Create Pull Requests
```bash
git-relax pr
```

## 🛠 Customization

### Commit Message Types
- `fix`: Bug fixes and patches
- `feat`: New features
- `build`: Build system changes
- `chore`: Maintenance tasks
- `ci`: CI configuration updates
- `docs`: Documentation improvements
- `style`: Code style modifications
- `refactor`: Code restructuring
- `perf`: Performance enhancements
- `test`: Test-related changes

## 📋 Pull Request Template

Generated PRs follow a structured format:
- Problems addressed
- Solution approach
- Implementation details
- Testing steps
- Dependency changes
- Deployment notes

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Commit using `git-relax cm`
4. Push your changes
5. Create PR using `git-relax pr`

## 📄 License

MIT License - see [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments
- Inspired by conventional commit standards
- Built for developer productivity
- Community-driven development

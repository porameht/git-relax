# Git-Relax 🎯

A smart Git workflow assistant that helps standardize commit messages and PR descriptions using conventional commit format and AI-powered suggestions, with support for customizable prompts.

## 🌟 Features

- **Standardized Commit Messages**: Generate well-formatted commit messages following conventional commit standards
- **Interactive PR Creation**: Create pull requests with AI-assisted title and description generation
- **Multiple Message Formats**: Support for different commit message styles:
  - Conventional commit format
  - Long-form messages with multiple lines
  - Short and concise messages
- **Customizable Prompts**: Tailor the AI prompts to match your team's specific needs and preferences

## 🚀 Installation

Add export script
```bash
PATH=$PATH:~/.local/bin in ~/.bashrc or ~/.zshrc
```

Clone the repository
```bash
git clone https://github.com/yourusername/git-relax.git
```

Run the installation script
```bash
./git-relax.sh
```

## 📋 Requirements

The following tools must be installed:
- git
- gum (for interactive prompts)
- gh (GitHub CLI)
- mods (for AI-powered text generation)

## 🎮 Usage

### Commit Messages
```bash
git-relax commit
```
or use the shorter alias
```bash
git-r commit
```

### Create Pull Requests
```bash
git-relax pr
```
or use the shorter alias
```bash
git-r pr
```

## 🎨 Customizing Prompts

Git-Relax allows you to customize the AI prompts used for generating commit messages and PR descriptions.

### Custom Commit Message Prompts

You can modify the prompts in your configuration file (`~/.config/git-relax/config.sh`):

```bash
# Default prompt templates
COMMIT_PROMPT_CONVENTIONAL="Generate a commit message following these rules:
1. Use type: {types}
2. Format: <type>(<scope>): <title>
3. Use imperative mood
4. Max 50 chars for title
Only output the formatted message."

# Custom prompt example
COMMIT_PROMPT_CUSTOM="As a senior developer in our team, create a commit message that:
1. Follows our team's prefix convention: {custom_types}
2. Includes the affected module in parentheses
3. Describes the change in under 50 characters
4. Adds any relevant ticket numbers
Format: <type>(<module>): <message> [TICKET-123]"
```

### Custom PR Description Prompts

Customize PR description generation:

```bash
# Default PR prompts
PR_PROMPT_PROBLEM="What problem does this PR solve? Be specific but concise."
PR_PROMPT_SOLUTION="How does this PR solve the problem? Focus on high-level approach."

# Custom PR prompts
PR_PROMPT_CUSTOM_PROBLEM="Describe the business impact and technical challenges this PR addresses, including:
1. Current limitations
2. User impact
3. Technical debt implications"

PR_PROMPT_CUSTOM_SOLUTION="Explain the solution architecture, considering:
1. Design patterns used
2. Performance implications
3. Security considerations"
```

### Available Prompt Variables

When customizing prompts, you can use these variables:
- `{types}`: Available commit types (fix, feat, etc.)
- `{scope}`: Current scope or module
- `{branch}`: Current branch name
- `{ticket}`: Extracted ticket number from branch
- `{custom_types}`: Your team's custom commit types

### Prompt Best Practices

1. **Be Specific**: Clearly define what you want in the output
2. **Include Format**: Always specify the desired output format
3. **Set Constraints**: Define character limits and required elements
4. **Add Context**: Include team-specific requirements or conventions
5. **Use Examples**: Provide examples of good and bad outputs

## 💫 Commit Message Types

- `fix`: for patches and bug fixes
- `feat`: for new features
- `build`: changes to build system
- `chore`: maintenance tasks
- `ci`: changes to CI configuration
- `docs`: documentation updates
- `style`: code style changes
- `refactor`: code refactoring
- `perf`: performance improvements
- `test`: adding or modifying tests

## 🎯 PR Template Structure

Pull requests generated with git-relax follow this structure:

```markdown
### Problems
[AI-generated description of the problems being solved]

### Solutions
[AI-generated description of the implemented solutions]

### Changes
[AI-generated list of main changes]
```

You can customize this template in your configuration file:

```bash
# Custom PR template
PR_TEMPLATE="
### 🎯 Objective
{problem}

### 💡 Solution Approach
{solution}

### 📝 Implementation Details
{changes}

### 🧪 Testing Steps
- [ ] Unit tests added
- [ ] Integration tests completed
- [ ] Manual testing performed

### 📦 Dependencies
- List any new dependencies
- Note any version changes

### 🚀 Deployment Notes
- Special deployment requirements
- Configuration changes needed
"
```

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes using git-relax (`git-r commit`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Create a Pull Request using git-relax (`git-r pr`)

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Inspired by conventional commits format
- Built with love for the developer community
- Special thanks to contributors who helped shape the prompt customization features

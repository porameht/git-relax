# Check if ship file exists
if [ -f ~/.local/bin/ship ]; then
    echo "😆 Updating existing ship script..."
else
    echo "🚀 Creating new ship script..."
    mkdir -p ~/.local/bin
fi

cat >~/.local/bin/ship <<'EOL'
#!/bin/bash

# Exit on error
set -e

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check for required commands
for cmd in git gum gh mods; do
    if ! command_exists "$cmd"; then
        echo "🚨 $cmd is not installed."
        exit 1
    fi
done

# Get the default branch from the remote repository
get_default_branch() {
    git remote show origin | grep 'HEAD branch' | cut -d' ' -f5
}

# Generate mods rules for commit message formatting
get_commit_rules() {
    local type="$1"
    local scope="$2"
    local breaking_change="$3"

    case "$type" in
        "message_conventional")
            echo "rules:
  - use_types:
      - fix: for patches/bugs
      - feat: for new features
      - build
      - chore
      - ci
      - docs
      - style
      - refactor
      - perf
      - test
  - format: '<type>${scope}${breaking_change}: <title>'
  - breaking_change:
      if_present: add 'BREAKING CHANGE: <description>' in footer
  - title:
      style: imperative mood
      length: <50 chars
  - body:
      optional: true
      position: after blank line
      wrap: 72 chars
  - content:
      focus: what and why, not how
output: formatted commit message only"
            ;;
        "message_long_more_lines")
            echo "rules:
  - type:
      prefix:
        - fix
        - feat
        - build
        - chore
        - ci
        - docs
        - style
        - refactor
        - perf
        - test
  - format: '<type>${scope}${breaking_change}: <title>'
  - description:
      position: after blank line
      style: detailed
  - content:
      mood: imperative
      include:
        - context
        - reasoning
output: formatted message only"
            ;;
        "message_short")
            echo "rules:
  - type:
      options:
        - fix
        - feat
        - build
        - chore
        - ci
        - docs
        - style
        - refactor
        - perf
        - test
  - format: '<type>${scope}${breaking_change}: <title>'
  - style: imperative mood
  - title_length: max 50 chars
output: single-line message only"
            ;;
        *)
            echo "rules:
  - format: '<type>${scope}${breaking_change}: <message>'
  - type:
      options:
        - fix
        - feat
        - build
        - chore
        - ci
        - docs
        - style
        - refactor
        - perf
        - test
  - style: imperative tense
  - length: max 50 chars
output: formatted message only"
            ;;
    esac
}

# Generate commit message
generate_commit_message() {
    local commit_message
    local breaking_change=""
    local scope=""

    # Select message type
    local type=$(gum choose "🔨 message_conventional" "🔨 message_long_more_lines" "🔨 message_long_single_line")

    # Ask about breaking changes
    if gum confirm "Does this commit contain breaking changes?"; then
        breaking_change="!"
    fi

    # Optional scope
    scope=$(gum input --placeholder "Enter scope (optional)")
    [ -n "$scope" ] && scope="($scope)"

    # Get rules and generate commit message
    local rules=$(get_commit_rules "$type" "$scope" "$breaking_change")
    commit_message=$(git diff --cached | mods "$rules")

    echo "$commit_message"

    if gum confirm "Do you want to push this commit now?"; then
        git commit -m "$commit_message"
    elif gum confirm "Do you want to regenerate the commit message?"; then
        generate_commit_message
    fi
}

# Generate PR rules for mods
get_pr_rules() {
    local rule_type="$1"
    
    case "$rule_type" in
        "title")
            echo "rules:
  - content: concise PR title describing main change
  - style: start with lowercase verb"
            ;;
        "problems")
            echo "task: describe PR problem
style:
  - brief
  - clear"
            ;;
        "solutions")
            echo "task: describe solution
output: solution only"
            ;;
        "changes")
            echo "task: list main changes
style:
  - use present-tense verbs
  - specific but concise"
            ;;
    esac
}

# Generate PR title and body
generate_pr_info() {
    local default_branch
    default_branch=$(get_default_branch)

    local type scope pr_title_prefix pr_summary pr_body

    # Using the Conventional Commit format
    type=$(gum choose "fix" "feat" "docs" "style" "refactor" "test" "chore" "revert")
    scope=$(gum input --placeholder "scope")
    [ -n "$scope" ] && scope="($scope)"

    pr_title_prefix="$type$scope"

    gum style --foreground 212 "Generating PR title..."
    pr_summary=$(git diff "$default_branch".. | mods "$(get_pr_rules "title")")
    pr_title="$pr_title_prefix: $pr_summary"

    gum style --foreground 212 "🔨 Generating PR body..."

    # Create sections for the PR template
    local problems=$(git diff "$default_branch".. | mods "$(get_pr_rules "problems")")
    local solutions=$(git diff "$default_branch".. | mods "$(get_pr_rules "solutions")")
    local changes=$(git diff "$default_branch".. | mods "$(get_pr_rules "changes")")

    # Construct the PR body using the template
    pr_body="### Problems

$problems

### Solutions

$solutions

### Changes

$changes"

    echo "🔨 Previewing Pull Request:" | gum format
    echo "Title: $pr_title" | gum format
    echo "Body: $pr_body" | gum format

    if gum confirm "🔨 Do you want to push this PR now?"; then
        gh pr create \
            --title "$pr_title" \
            --body "$pr_body"
        echo "Pull Request has been created!" | gum format
    fi
}

# Main script execution starts here
if [ "$1" = "cm" ]; then
    generate_commit_message
else
    generate_pr_info
fi
EOL

# Make script executable
chmod +x ~/.local/bin/ship

# Show confirmation message
if [ -f ~/.local/bin/ship ]; then
    echo "🎉 Script has been updated at ~/.local/bin/ship"
else
    echo "🎉 Script has been created at ~/.local/bin/ship"
fi

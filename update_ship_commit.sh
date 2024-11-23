# update ship commit message
cat > ~/.local/bin/ship << 'EOL'
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
        echo "Error: $cmd is not installed."
        exit 1
    fi
done

# Get the default branch from the remote repository
get_default_branch() {
    git remote show origin | grep 'HEAD branch' | cut -d' ' -f5
}

generate_commit_message() {
    local commit_message
    local breaking_change

    # Select message type
    type=$(gum choose "message_conventional" "message_long_more_lines" "message_long_single_line")

    # Ask about breaking changes
    if gum confirm "Does this commit contain breaking changes?"; then
        breaking_change="!"
    else
        breaking_change=""
    fi

    # Optional scope
    scope=$(gum input --placeholder "Enter scope (optional)")
    [ -n "$scope" ] && scope="($scope)"

    if [ "$type" == "message_conventional" ]; then
        commit_message=$(git diff --cached | mods "
rules:
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
output: formatted commit message only")
    elif [ "$type" == "message_long_more_lines" ]; then
        commit_message=$(git diff --cached | mods "
rules:
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
output: formatted message only")
    elif [ "$type" == "message_short" ]; then
        commit_message=$(git diff --cached | mods "
rules:
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
output: single-line message only")
    else
        commit_message=$(git diff --cached | mods "
rules:
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
output: formatted message only")
    fi

    echo "$commit_message"

    if gum confirm "Do you want to push this commit now?"; then
        git commit -m "$commit_message"
    elif gum confirm "Do you want to regenerate the commit message?"; then
        generate_commit_message
    fi
}

# Generate PR title and body
generate_pr_info() {
    local default_branch
    default_branch=$(get_default_branch)

    local type scope pr_title_prefix pr_summary pr_body

    # Using the Conventional Commit format
    type=$(gum choose "fix" "feat" "docs" "style" "refactor" "test" "chore" "revert")
    scope=$(gum input --placeholder "scope")

    # Since the scope is optional, wrap it in parentheses if it has a value.
    [ -n "$scope" ] && scope="($scope)"

    pr_title_prefix="$type$scope"

    gum style --foreground 212 "Generating PR title..."
    pr_summary=$(git diff "$default_branch".. | mods "
rules:
  - content: concise PR title describing main change
  - style: start with lowercase verb")
    pr_title="$pr_title_prefix: $pr_summary"

    gum style --foreground 212 "Generating PR body..."

    # Create sections for the PR template with more concise prompts
    local problems changes solutions

    problems=$(git diff "$default_branch".. | mods "
task: describe PR problem
style:
  - brief
  - clear")
    solutions=$(git diff "$default_branch".. | mods "
task: describe solution
output: solution only")
    changes=$(git diff "$default_branch".. | mods "
task: list main changes
style:
  - use present-tense verbs
  - specific but concise")

    # Construct the PR body using the template
    pr_body="### Problems

$problems

### Solutions

$solutions

### Changes

$changes"

    echo "Previewing Pull Request:"
    echo "Title: $pr_title"
    echo "Body: $pr_body"

    if gum confirm "Do you want to push this PR now?"; then
        gh pr create \
            --title "$pr_title" \
            --body "$pr_body"
        echo "Pull Request has been created!"
    fi
}

# Main script execution starts here
if [ "$1" = "cm" ]; then
    generate_commit_message
else
    generate_pr_info
fi
EOL

# ให้สิทธิ์การรันอีกครั้ง (เผื่อสิทธิ์หาย)
chmod +x ~/.local/bin/ship

# แสดงข้อความยืนยัน
echo "Script has been updated at ~/.local/bin/ship"

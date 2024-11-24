# Check if ship file exists
if [ -f ~/.local/bin/git-relax ]; then
    echo "😆 Updating existing git-relax script..."
else
    echo "🚀 Creating new git-relax script..."
    mkdir -p ~/.local/bin
fi

# Create git-relax script
cat >~/.local/bin/git-relax <<'EOL'
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
        "🔨 message_conventional")
            echo "Generate a commit message following these rules:
        1. Use one of these types: fix (for patches/bugs), feat (for new features), build, chore, ci, docs, style, refactor, perf, test
        2. Format: <type>${scope}${breaking_change}: <title>
        3. If breaking_change is present, add 'BREAKING CHANGE: <description>' in the footer
        4. Use imperative mood in the title
        5. Optionally add detailed description after a blank line
        6. Keep title concise (<50 chars)
        7. Wrap body at 72 chars
        8. Explain the what and why, not the how
        Only output the formatted commit message."
            ;;
        "🔨 message_long_more_lines")
            echo "Generate a detailed commit message with:
        1. Type prefix: fix/feat/build/chore/ci/docs/style/refactor/perf/test
        2. Format: <type>${scope}${breaking_change}: <title>
        3. Follow with detailed description after blank line
        4. Use imperative mood
        5. Explain context and reasoning
        Only output the formatted message."
            ;;
        "🔨 message_long_single_line")
            echo "Generate a concise commit message:
        1. Use type: fix/feat/build/chore/ci/docs/style/refactor/perf/test
        2. Format: <type>${scope}${breaking_change}: <title>
        3. Use imperative mood
        4. Max 50 chars for title
        Only output the single-line message."
            ;;
        *)
            echo "Generate a concise commit message in format <type>${scope}${breaking_change}: <message> where type is fix/feat/build/chore/ci/docs/style/refactor/perf/test. Use imperative tense. Max 50 chars."
            echo "Debug: type=$type, scope=$scope, breaking_change=$breaking_change"
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
    if gum confirm "🚨 Does this commit contain breaking changes?"; then
        breaking_change="!"
    fi

    # Optional scope
    scope=$(gum input --placeholder "Enter scope (optional)")
    [ -n "$scope" ] && scope="($scope)"

    # Get rules and generate commit message
    local rules=$(get_commit_rules "$type" "$scope" "$breaking_change")
    commit_message=$(git diff --cached | mods "$rules")

    echo "$commit_message"

    if gum confirm "👨‍💻 Do you want to commit now?"; then
        git commit -m "$commit_message"
    elif gum confirm "👨‍💻 Do you want to regenerate the commit message?"; then
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
if [ "$1" = "commit" ]; then
    generate_commit_message
elif [ "$1" = "pr" ]; then
    generate_pr_info
else
    echo "🚨 Invalid command. Usage: git-relax commit|pr"
fi
EOL

# Make script executable
chmod +x ~/.local/bin/git-relax

# Show confirmation message
if [ -f ~/.local/bin/git-relax ]; then
    echo "🎉 Script has been updated at ~/.local/bin/git-relax"
else
    echo "🎉 Script has been created at ~/.local/bin/git-relax"
fi

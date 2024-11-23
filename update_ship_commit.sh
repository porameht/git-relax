# อัพเดทไฟล์
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
        commit_message=$(git diff --cached | mods "Generate a commit message following these rules:
        1. Use one of these types: fix (for patches/bugs), feat (for new features), build, chore, ci, docs, style, refactor, perf, test
        2. Format: <type>${scope}${breaking_change}: <title>
        3. If breaking_change is present, add 'BREAKING CHANGE: <description>' in the footer
        4. Use imperative mood in the title
        5. Optionally add detailed description after a blank line
        6. Keep title concise (<50 chars)
        7. Wrap body at 72 chars
        8. Explain the what and why, not the how
        Only output the formatted commit message.")
    elif [ "$type" == "message_long_more_lines" ]; then
        commit_message=$(git diff --cached | mods "Generate a detailed commit message with:
        1. Type prefix: fix/feat/build/chore/ci/docs/style/refactor/perf/test
        2. Format: <type>${scope}${breaking_change}: <title>
        3. Follow with detailed description after blank line
        4. Use imperative mood
        5. Explain context and reasoning
        Only output the formatted message.")
    elif [ "$type" == "message_short" ]; then
        commit_message=$(git diff --cached | mods "Generate a concise commit message:
        1. Use type: fix/feat/build/chore/ci/docs/style/refactor/perf/test
        2. Format: <type>${scope}${breaking_change}: <title>
        3. Use imperative mood
        4. Max 50 chars for title
        Only output the single-line message.")
    else
        
        commit_message=$(git diff --cached | mods "Generate a concise commit message in format <type>${scope}${breaking_change}: <message> where type is fix/feat/build/chore/ci/docs/style/refactor/perf/test. Use imperative tense. Max 50 chars.")
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
    pr_summary=$(git diff "$default_branch".. | mods "Generate a concise PR title describing the main change. Start with lowercase verb.")
    pr_title="$pr_title_prefix: $pr_summary"

    gum style --foreground 212 "Generating PR body..."

    # Create sections for the PR template with more concise prompts
    local problems changes solutions

    problems=$(git diff "$default_branch".. | mods "What problem does this PR solve? Be brief but clear.")
    solutions=$(git diff "$default_branch".. | mods "How does this PR solve the problem? only answer with the solution")
    changes=$(git diff "$default_branch".. | mods "List main changes using present-tense verbs. Be specific but concise.")

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

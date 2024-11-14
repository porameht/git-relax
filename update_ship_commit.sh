
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

    # select type
    type=$(gum choose "message_long_more_lines" "message_long_single_line" "message_short" "message_brief")

    if [ "$type" == "message_long_more_lines" ]; then
        commit_message=$(git diff --cached | mods "You are an expert software engineer.Review the provided context and diffs which are about to be committed to a git repo.Review the diffs carefully.Generate a commit message for those changes.The commit message MUST use the imperative tense.The commit message should be structured as follows: <type>: <title>The commit message can come with an optional description after the title with a blank line.Remember don't make the title too long.Use these for <type>: fix, feat, build, chore, ci, docs, style, refactor, perf, testReply with JUST the commit message, without quotes, comments, questions, etc!")
    elif [ "$type" == "message_long_single_line" ]; then
        # Get the diff and generate commit message using mods
        commit_message=$(git diff --cached | mods "You are an expert software engineer. Review the diffs and generate a commit message that starts with one of these types: fix, feat, build, chore, ci, docs, style, refactor, perf, test. Format must be '<type>: <short message> - <optional detailed description>'. Keep everything on a single line using a hyphen to separate description. Use imperative tense. Reply with only the commit message.")
    elif [ "$type" == "message_short" ]; then
        commit_message=$(git diff --cached | mods "You are an expert software engineer. Generate a commit message for the changes. The commit message MUST use the imperative tense starting with a type prefix from this list: fix, feat, build, chore, ci, docs, style, refactor, perf, test. Format should be <type>: <short message>. Keep it concise and meaningful. DO NOT add line breaks or descriptions.")
    elif [ "$type" == "message_brief" ]; then
        commit_message=$(git diff --cached | mods "Generate a concise commit message in format '<type>: <message> - <brief context>' where type is fix/feat/build/chore/ci/docs/style/refactor/perf/test. Use imperative tense. Describe core change in 3-5 words, add essential context after hyphen if needed.")
    fi

    echo "$commit_message"
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

    gum style --foreground 212 "Generating Pull Request title..."
    pr_summary=$(git diff "$default_branch".. | mods "create a concise Pull Request title that describes the main change. First word should start with a lowercase letter")
    pr_title="$pr_title_prefix: $pr_summary"

    gum style --foreground 212 "Generating Pull Request body..."
    
    # Create sections for the PR template
    local problems changes solutions

    problems=$(git diff "$default_branch".. | mods -f "Describe the problems or issues that needed to be addressed. Focus on why these changes were necessary." --max-tokens 200)
    solutions=$(git diff "$default_branch".. | mods -f "Explain the solutions implemented to address the problems. Include important technical details and implementation choices." --max-tokens 200)
    changes=$(git diff "$default_branch".. | mods -f "Create a bullet-point list of the main changes made in this PR. Each point should be concise and start with a verb in present tense." --max-tokens 200)

    # Construct the PR body using the template
    pr_body="### Problems

$problems

### Solutions

$solutions

### Changes

$changes"

    gh pr create \
        --title "$pr_title" \
        --body "$pr_body"
}

# Main script execution starts here
if [ "$1" = "commit" ]; then
    commit_msg=$(generate_commit_message)
    git commit -m "$commit_msg"
else
    generate_pr_info
fi
EOL

# ให้สิทธิ์การรันอีกครั้ง (เผื่อสิทธิ์หาย)
chmod +x ~/.local/bin/ship

# แสดงข้อความยืนยัน
echo "Script has been updated at ~/.local/bin/ship"
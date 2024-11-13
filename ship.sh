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
    pr_body=$(git diff "$default_branch".. | mods -f "Create a detailed PR description that includes: 
    - The main changes made
    - Why these changes were necessary
    - Any important implementation details
    Keep it clear and concise." --max-tokens 400)

    gh pr create \
        --title "$pr_title" \
        --body "$pr_body"
}

# Main script execution starts here
generate_pr_info
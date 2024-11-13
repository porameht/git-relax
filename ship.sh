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
generate_pr_info
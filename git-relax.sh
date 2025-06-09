#!/bin/bash

set -e

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

for cmd in git gum gh mods; do
    if ! command_exists "$cmd"; then
        echo "🚨 $cmd is not installed."
        exit 1
    fi
done

get_default_branch() {
    git remote show origin | grep 'HEAD branch' | cut -d' ' -f5
}

get_commit_rules() {
    local scope="$1"
    local breaking_change="$2"

    echo "Generate a concise commit message:
        1. Use type: fix/feat/build/chore/ci/docs/style/refactor/perf/test
        2. Format: <type>${scope}${breaking_change}: <title>
        3. Use imperative mood
        4. Max 50 chars for title
        5. Lowercase the message
        Only output the single-line message."
}

generate_commit_message() {
    local commit_message
    local breaking_change=""
    local scope=""

    if gum confirm "🚨 Does this commit contain breaking changes?"; then
        breaking_change="!"
    fi

    scope=$(gum input --placeholder "Enter scope (optional)")
    [ -n "$scope" ] && scope="($scope)"

    local rules=$(get_commit_rules "$scope" "$breaking_change")
    commit_message=$(git diff --cached | mods "$rules" | tr '[:upper:]' '[:lower:]')

    echo "$commit_message"

    if gum confirm "👨‍💻 Do you want to commit now?"; then
        git commit -m "$commit_message"
    elif gum confirm "👨‍💻 Do you want to regenerate the commit message?"; then
        generate_commit_message
    fi
}

get_pr_rules() {
    local rule_type="$1"
    
    case "$rule_type" in
        "title")
            echo "rules:
  - content: concise PR title describing main change
  - style: start with lowercase verb"
            ;;
        "objective")
            echo "task: summarize the main objective of this change
style:
  - brief summary
  - clear purpose"
            ;;
        "changelog")
            echo "task: list main changes as bullet points
style:
  - use present-tense verbs
  - specific but concise
  - format as bullet points"
            ;;
    esac
}

generate_pr_info() {
    local default_branch
    default_branch=$(get_default_branch)

    local type scope pr_title_prefix pr_summary pr_body

    type=$(gum choose "fix" "feat" "docs" "style" "refactor" "test" "chore" "revert")
    scope=$(gum input --placeholder "scope")
    [ -n "$scope" ] && scope="($scope)"

    pr_title_prefix="$type$scope"

    gum style --foreground 212 "Generating PR title..."
    pr_summary=$(git diff "$default_branch".. | mods "$(get_pr_rules "title")" | tr '[:upper:]' '[:lower:]')
    pr_title="$pr_title_prefix: $pr_summary"

    gum style --foreground 212 "🔨 Generating PR body..."

    local objective=$(git diff "$default_branch".. | mods "$(get_pr_rules "objective")" | tr '[:upper:]' '[:lower:]')
    local jira_ticket=$(gum input --placeholder "Enter Jira Ticket URL (optional)")
    local changelog=$(git diff "$default_branch".. | mods "$(get_pr_rules "changelog")")
    local deployment_dependency=$(gum input --placeholder "Enter deployment dependencies (optional)")

    pr_body="## Objective
${objective}

## Jira Ticket
${jira_ticket:-"(JIRA Ticket URL)"}

## Change logs
${changelog}

## Deployment Dependency
${deployment_dependency:-"(e.g. Depends on other Jira Tasks)"}

## Test / Snapshots

(Your images & test description here)"

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

if [ "$1" = "cm" ]; then
    generate_commit_message
elif [ "$1" = "pr" ]; then
    generate_pr_info
else
    echo "🚨 Invalid command. Usage: git-relax cm|pr"
fi

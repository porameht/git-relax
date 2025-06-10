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
            echo "Generate a complete PR title with prefix (max 50 chars):
  - format: <type>(<scope>): <description>
  - types: fix/feat/docs/style/refactor/test/chore/build/ci/perf/revert
  - scope: brief area of change (optional)
  - description: start with lowercase verb
  - example: 'feat(auth): add user login validation' or 'fix: resolve memory leak issue'"
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
        "review")
            echo "Perform a comprehensive code review with actionable suggestions:

ANALYSIS REQUIREMENTS:
- Analyze code quality, security, performance, maintainability
- Check for best practices, potential bugs, and architectural issues
- Review error handling, input validation, and resource management
- Examine code patterns, naming conventions, and documentation
- Apply KISS principle (Keep It Simple, Stupid) - prioritize simplicity and readability
- Identify overcomplicated logic that can be simplified
- Check for unnecessary abstractions or complex patterns

OUTPUT FORMAT:
✅ **Strengths**
- List positive aspects with specific examples from the code
- Highlight good practices being followed

⚠️ **Issues & Suggestions** 
- For each issue, provide:
  1. **Problem**: Clear description of the issue
  2. **Why**: Explain why this is problematic (security, performance, maintainability)
  3. **Solution**: Show exact code example of the fix
  4. **Benefit**: Explain what improvement this brings

💡 **Recommendations**
- Suggest broader improvements with examples
- Include best practices not currently implemented
- Provide specific implementation guidance
- Recommend simplifications following KISS principle
- Suggest refactoring complex functions into smaller, focused ones
- Identify opportunities to reduce cognitive complexity

EXAMPLE FORMAT for Issues:

**Security Issue Example:**
**Problem**: Missing input validation in user registration
**Why**: This allows malicious data to enter the system, potentially causing XSS or injection attacks
**Solution**: 
\`\`\`python
# Before
def register_user(username, email):
    user = User(username=username, email=email)
    
# After  
def register_user(username, email):
    if not username or len(username) < 3:
        raise ValueError('Username must be at least 3 characters')
    if not re.match(r'^[^@]+@[^@]+\.[^@]+$', email):
        raise ValueError('Invalid email format')
    user = User(username=username, email=email)
\`\`\`
**Benefit**: Prevents invalid data from entering the system and provides clear error messages

**KISS Principle Example:**
**Problem**: Overcomplicated conditional logic that's hard to read
**Why**: Complex nested conditions violate KISS principle, making code harder to understand and maintain
**Solution**: 
\`\`\`python
# Before (Complex)
def process_user(user):
    if user.is_active and (user.subscription_type == 'premium' or (user.subscription_type == 'basic' and user.credits > 0)) and not user.is_suspended:
        return handle_active_user(user)
    else:
        return handle_inactive_user(user)

# After (Simple & Clear)
def process_user(user):
    if not user.is_active or user.is_suspended:
        return handle_inactive_user(user)
    
    has_access = (user.subscription_type == 'premium' or 
                  (user.subscription_type == 'basic' and user.credits > 0))
    
    if has_access:
        return handle_active_user(user)
    else:
        return handle_inactive_user(user)
\`\`\`
**Benefit**: Code is easier to read, understand, and debug. Each condition is clear and testable.

Be specific, actionable, and educational in your review."
            ;;
    esac
}



generate_pr_info() {
    local default_branch
    default_branch=$(get_default_branch)

    local pr_title pr_body choice

    choice=$(gum choose "🤖 AI คิดให้ (Auto generate)" "👨‍💻 เลือกเอง (Manual select)")

    if [[ "$choice" == *"AI คิดให้"* ]]; then
        gum style --foreground 212 "🤖 AI กำลังสร้าง PR title..."
        pr_title=$(git diff "$default_branch".. | mods "$(get_pr_rules "title")" | tr '[:upper:]' '[:lower:]')
    else
        local type scope pr_title_prefix pr_summary
        
        type=$(gum choose "fix" "feat" "docs" "style" "refactor" "test" "chore" "revert")
        scope=$(gum input --placeholder "scope (optional)")
        [ -n "$scope" ] && scope="($scope)"
        
        pr_title_prefix="$type$scope"
        
        gum style --foreground 212 "👨‍💻 กำลังสร้าง PR title..."
        pr_summary=$(git diff "$default_branch".. | mods "Generate a short description (no prefix): describe the main change, start with lowercase verb, max 30 chars" | tr '[:upper:]' '[:lower:]')
        pr_title="$pr_title_prefix: $pr_summary"
    fi

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
        local pr_url
        pr_url=$(gh pr create \
            --title "$pr_title" \
            --body "$pr_body")
        
        echo "Pull Request has been created!" | gum format
        echo "🔗 $pr_url" | gum format
        
        # เพิ่มเมนูถาม review หลังสร้าง PR เสร็จ
        echo ""
        if gum confirm "🔍 ต้องการให้ AI review โค้ดใน PR นี้ต่อเลยหรือไม่?"; then
            echo ""
            gum style --foreground 212 "🔄 เริ่มต้น AI Code Review..."
            
            # ดึง PR number จาก URL ที่ได้
            local pr_number
            pr_number=$(echo "$pr_url" | grep -o '[0-9]\+$')
            generate_code_review "$pr_number"
        fi
    fi
}

generate_code_review() {
    local pr_number="$1"
    local default_branch
    default_branch=$(get_default_branch)

    # ถ้าไม่ได้ระบุ PR number ให้ใช้ current PR
    if [ -z "$pr_number" ]; then
        pr_number=$(gh pr view --json number --jq '.number' 2>/dev/null)
        if [ -z "$pr_number" ]; then
            echo "🚨 ไม่พบ PR ในสาขาปัจจุบัน กรุณาระบุ PR number หรือสร้าง PR ก่อน"
            return 1
        fi
    fi

    gum style --foreground 212 "🔍 กำลังวิเคราะห์โค้ดใน PR #$pr_number..."

    # ดึงข้อมูล PR
    local pr_title=$(gh pr view "$pr_number" --json title --jq '.title')
    echo "📋 PR: $pr_title"

    # เลือกประเภทการ review
    local review_type
    review_type=$(gum choose "💬 General Review (PR comment)" "🎯 Inline Comments (True line-specific)" "🔄 ทั้งคู่ (Both)")

    if [[ "$review_type" == *"General"* ]] || [[ "$review_type" == *"ทั้งคู่"* ]]; then
        # วิเคราะห์โค้ดด้วย AI สำหรับ general review
        local review_comment
        review_comment=$(git diff "$default_branch".. | mods "$(get_pr_rules "review")")

        echo ""
        echo "🔍 AI General Review:" | gum format
        echo "$review_comment" | gum format

        if gum confirm "💬 ต้องการส่ง general review comment นี้ไปที่ PR หรือไม่?"; then
            gh pr comment "$pr_number" --body "$review_comment"
            echo "✅ ส่ง general review comment เรียบร้อยแล้ว!" | gum format
        fi
    fi

    if [[ "$review_type" == *"Inline"* ]] || [[ "$review_type" == *"ทั้งคู่"* ]]; then
        generate_inline_comments "$pr_number" "$default_branch"
    fi
}

generate_inline_comments() {
    local pr_number="$1"
    local default_branch="$2"

    gum style --foreground 212 "🎯 สร้าง true inline comments..."

    # ดึงข้อมูล PR และ commit SHA
    local commit_sha
    commit_sha=$(gh pr view "$pr_number" --json headRefOid --jq '.headRefOid')
    
    # ดึงรายการไฟล์ที่เปลี่ยนแปลงจาก git diff
    local changed_files
    changed_files=$(git diff --name-only "$default_branch"..)

    if [ -z "$changed_files" ]; then
        echo "🚨 ไม่พบไฟล์ที่เปลี่ยนแปลง"
        return 1
    fi

    echo "📁 ไฟล์ที่เปลี่ยนแปลง:"
    echo "$changed_files" | gum format
    echo "📝 Commit SHA: $commit_sha" | gum format

    # สร้าง array สำหรับเก็บ inline comments
    local -a inline_comments=()
    
    # วิเคราะห์แต่ละไฟล์และสร้าง line-specific comments
    while IFS= read -r file; do
        if [ -f "$file" ]; then
            echo "🔍 วิเคราะห์ไฟล์: $file" | gum format
            
            # ดึง diff พร้อม line numbers ที่ถูกต้อง
            local file_diff
            file_diff=$(git diff "$default_branch".."HEAD" -- "$file")
            
            if [ -n "$file_diff" ]; then
                # ให้ AI วิเคราะห์และสร้าง comments สำหรับบรรทัดที่เปลี่ยน
                local ai_response
                ai_response=$(echo "$file_diff" | mods "Analyze this git diff for file: $file

Provide inline code review suggestions for changed lines only.
Focus on critical issues: Security, Performance, KISS principle, Best practices.

OUTPUT FORMAT: For each issue, output exactly:
LINE_NUMBER:COMMENT_TEXT

Where:
- LINE_NUMBER: exact new line number from the diff (+ lines only)
- COMMENT_TEXT: concise suggestion with code example if helpful (max 200 chars)

RULES:
- Only comment on lines that have + (additions) in the diff
- Use NEW line numbers (right side of diff)  
- Include specific improvement suggestions
- Reference variable/function names from the code
- If no issues found, output: NO_ISSUES_FOUND

EXAMPLES:
25:🔒 Use parameterized queries: \`cursor.execute(\"SELECT * FROM users WHERE id = %s\", (user_id,))\`
42:⚡ Use list comprehension: \`active_users = [u for u in users if u.active]\`
15:🎯 Simplify: \`return not user.active\` instead of if/else")

                if [ -n "$ai_response" ] && [ "$ai_response" != "NO_ISSUES_FOUND" ]; then
                    echo "  🤖 AI found $(echo "$ai_response" | wc -l) suggestions" | gum format
                    
                    # แปลง AI response เป็น inline comments array
                    while IFS= read -r line; do
                        if [[ "$line" =~ ^[0-9]+:.+ ]]; then
                            local line_num=$(echo "$line" | cut -d':' -f1)
                            local comment_text=$(echo "$line" | cut -d':' -f2-)
                            
                            inline_comments+=("$file:$line_num:$comment_text:$commit_sha")
                            echo "  📝 Valid comment: $file:$line_num" | gum format
                        fi
                    done <<< "$ai_response"
                else
                    echo "  ✅ No issues found in $file" | gum format
                fi
            fi
        fi
    done <<< "$changed_files"

    # แสดง preview ของ inline comments
    echo ""
    echo "🎯 Inline Comments Preview:" | gum format
    if [ ${#inline_comments[@]} -eq 0 ]; then
        echo "✅ ไม่พบ issues ที่ต้องการ inline comments" | gum format
        return 0
    fi

    for comment in "${inline_comments[@]}"; do
        local file_path=$(echo "$comment" | cut -d':' -f1)
        local line_num=$(echo "$comment" | cut -d':' -f2)
        local comment_text=$(echo "$comment" | cut -d':' -f3)
        
        echo "📍 $file_path:$line_num" | gum format
        echo "   $comment_text" | gum format
        echo ""
    done

    if gum confirm "🎯 ต้องการส่ง inline comments เหล่านี้ไปที่ PR หรือไม่?"; then
        # ดึงข้อมูล repository
        local repo_info
        repo_info=$(gh repo view --json owner,name --jq '{owner: .owner.login, name: .name}')
        local owner=$(echo "$repo_info" | jq -r '.owner')
        local repo=$(echo "$repo_info" | jq -r '.name')

        echo "🚀 กำลังส่ง ${#inline_comments[@]} inline comments..." | gum format
        
        # ส่งแต่ละ comment ผ่าน GitHub API
        local success_count=0
        for comment in "${inline_comments[@]}"; do
            local file_path=$(echo "$comment" | cut -d':' -f1)
            local line_num=$(echo "$comment" | cut -d':' -f2)
            local comment_text=$(echo "$comment" | cut -d':' -f3)
            local commit_id=$(echo "$comment" | cut -d':' -f4)
            
            echo "📍 Creating inline comment: $file_path:$line_num" | gum format
            
            # สร้าง JSON payload สำหรับ GitHub API
            local json_payload
            json_payload=$(jq -n \
                --arg body "$comment_text" \
                --arg commit_id "$commit_id" \
                --arg path "$file_path" \
                --arg line "$line_num" \
                --arg side "RIGHT" \
                '{
                    body: $body,
                    commit_id: $commit_id,
                    path: $path,
                    line: ($line | tonumber),
                    side: $side
                }')
            
            # ส่ง comment ผ่าน GitHub API
            if gh api \
                "repos/$owner/$repo/pulls/$pr_number/comments" \
                --method POST \
                --input - <<< "$json_payload" >/dev/null 2>&1; then
                echo "  ✅ Inline comment created successfully"
                ((success_count++))
            else
                echo "  ⚠️ Failed to create inline comment, trying with gh pr review..."
                # Fallback: ใช้ gh pr review
                if gh pr review "$pr_number" --comment \
                    --body "$comment_text" \
                    --file "$file_path" \
                    --line "$line_num" 2>/dev/null; then
                    echo "  ✅ Comment created via gh pr review"
                    ((success_count++))
                else
                    echo "  ❌ Failed to create comment"
                fi
            fi
        done
        
        echo "✅ สร้าง $success_count/${#inline_comments[@]} inline comments สำเร็จ!" | gum format
        echo "💡 ดู inline comments ใน Files tab ของ PR" | gum format
    elif gum confirm "✏️ ต้องการแก้ไข comments ก่อนส่งหรือไม่?"; then
        # สร้าง temporary file สำหรับการแก้ไข
        local temp_file=$(mktemp)
        
        # เขียน comments ลง temp file
        for comment in "${inline_comments[@]}"; do
            local file_path=$(echo "$comment" | cut -d':' -f1)
            local line_num=$(echo "$comment" | cut -d':' -f2)
            local comment_text=$(echo "$comment" | cut -d':' -f3)
            echo "$file_path:$line_num:$comment_text" >> "$temp_file"
        done
        
        # ให้ user แก้ไข
        local edited_comments
        edited_comments=$(gum write --value "$(cat "$temp_file")" --placeholder "แก้ไข inline comments (format: file:line:comment)")
        
        if [ -n "$edited_comments" ]; then
            echo "🚀 Processing edited comments..."
            # TODO: ประมวลผล edited comments (similar logic as above)
            echo "✅ Feature สำหรับแก้ไข comments จะเพิ่มในเวอร์ชันต่อไป" | gum format
        fi
        
        rm -f "$temp_file"
    fi
}

if [ "$1" = "cm" ]; then
    generate_commit_message
elif [ "$1" = "pr" ]; then
    generate_pr_info
elif [ "$1" = "rv" ]; then
    generate_code_review "$2"
else
    echo "🚨 Invalid command. Usage:"
    echo "  git-relax cm           - Generate commit message"
    echo "  git-relax pr           - Create pull request"
    echo "  git-relax rv [PR#]     - Review code with AI (general/inline)"
    echo "                          (if PR# not specified, uses current PR)"
fi

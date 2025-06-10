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

get_valid_comment_lines() {
    local file="$1"
    local default_branch="$2"
    
    # หา ALL lines ที่สามารถ comment ได้ใน GitHub PR diff:
    # 1. Added lines (+ lines) - บรรทัดที่เพิ่มใหม่
    # 2. Context lines (" " lines) - บรรทัดที่ไม่เปลี่ยนแต่อยู่ใน diff context
    # ❌ ไม่รวม Deleted lines (- lines) เพราะไม่มีในไฟล์ใหม่
    git diff "$default_branch".."HEAD" -- "$file" | awk '
        BEGIN { 
            in_hunk = 0
            new_line_current = 0
        }
        /^@@/ {
            # Parse hunk header: @@ -old_start,old_count +new_start,new_count @@
            # Extract new file starting line number
            if (match($0, /\+([0-9]+)/)) {
                new_line_current = substr($0, RSTART+1, RLENGTH-1)
                in_hunk = 1
            }
            next
        }
        in_hunk && /^[+]/ && !/^\+\+\+/ {
            # Added line - สามารถ comment ได้
            print new_line_current ":ADDED:" substr($0, 2)
            new_line_current++
        }
        in_hunk && /^[ ]/ {
            # Context line - สามารถ comment ได้เช่นกัน
            print new_line_current ":CONTEXT:" substr($0, 2)
            new_line_current++
        }
        in_hunk && /^[-]/ && !/^---/ {
            # Deleted line - ไม่สามารถ comment ได้ และไม่ increment new_line_current
            # เพราะบรรทัดนี้ไม่มีในไฟล์ใหม่
        }
    '
}

validate_line_in_diff() {
    local file="$1"
    local line_num="$2"
    local default_branch="$3"
    
    # ตรวจสอบว่า line number นี้อยู่ในรายการ valid lines หรือไม่
    # format ใหม่: line_number:TYPE:content
    local valid_lines
    valid_lines=$(get_valid_comment_lines "$file" "$default_branch")
    
    if echo "$valid_lines" | grep -q "^$line_num:"; then
        # แสดงประเภทของ line ที่ validate
        local line_type
        line_type=$(echo "$valid_lines" | grep "^$line_num:" | cut -d':' -f2 | head -1)
        if [ "$line_type" = "ADDED" ]; then
            echo "    🎯 Line $line_num is valid (NEWLY ADDED)" >&2
        else
            echo "    📝 Line $line_num is valid (CONTEXT)" >&2
        fi
        return 0  # Valid
    else
        return 1  # Invalid
    fi
}

generate_inline_comments() {
    local pr_number="$1"
    local default_branch="$2"

    gum style --foreground 212 "🎯 สร้าง smart inline comments..."

    # ไม่ต้องใช้ commit SHA สำหรับ Reviews API
    
    # ดึงรายการไฟล์ที่เปลี่ยนแปลงจาก git diff
    local changed_files
    changed_files=$(git diff --name-only "$default_branch"..)

    if [ -z "$changed_files" ]; then
        echo "🚨 ไม่พบไฟล์ที่เปลี่ยนแปลง"
        return 1
    fi

    echo "📁 ไฟล์ที่เปลี่ยนแปลง:"
    echo "$changed_files" | gum format

    # สร้าง array สำหรับเก็บ inline comments
    local -a inline_comments=()
    
    # วิเคราะห์แต่ละไฟล์และสร้าง line-specific comments
    while IFS= read -r file; do
        if [ -f "$file" ]; then
            echo "🔍 วิเคราะห์ไฟล์: $file" | gum format
            
            # หาเฉพาะ lines ที่เปลี่ยนแปลงและสามารถ comment ได้ใน GitHub
            local valid_lines
            valid_lines=$(get_valid_comment_lines "$file" "$default_branch")
            
            if [ -n "$valid_lines" ]; then
                lines_count=$(echo "$valid_lines" | wc -l)
                echo "  📊 Found $lines_count valid comment lines" | gum format
                echo "  🎯 Valid lines for comments:" | gum format
                echo "$valid_lines" | head -5 | while IFS= read -r line; do
                    line_num=$(echo "$line" | cut -d':' -f1)
                    line_type=$(echo "$line" | cut -d':' -f2)
                    content=$(echo "$line" | cut -d':' -f3- | head -c 50)
                    if [ "$line_type" = "ADDED" ]; then
                        echo "    ✅ Line $line_num (NEW): $content..."
                    else
                        echo "    📝 Line $line_num (CONTEXT): $content..."
                    fi
                done | gum format
                
                # สร้าง context ให้ AI โดยแสดงเฉพาะ lines ที่เปลี่ยน
                local diff_context
                diff_context=$(git diff "$default_branch".."HEAD" -- "$file")
                
                # สร้างรายการ valid line numbers ที่ AI สามารถใช้ได้
                local valid_line_numbers
                valid_line_numbers=$(echo "$valid_lines" | cut -d':' -f1 | sort -n | uniq)
                
                # แยกประเภทของ lines เพื่อให้ AI เข้าใจดีขึ้น
                local added_lines_preview
                local context_lines_preview
                added_lines_preview=$(echo "$valid_lines" | grep ":ADDED:" | head -8 | while IFS= read -r line; do
                    line_num=$(echo "$line" | cut -d':' -f1)
                    content=$(echo "$line" | cut -d':' -f3-)
                    echo "  Line $line_num: $content"
                done)
                
                context_lines_preview=$(echo "$valid_lines" | grep ":CONTEXT:" | head -5 | while IFS= read -r line; do
                    line_num=$(echo "$line" | cut -d':' -f1)
                    content=$(echo "$line" | cut -d':' -f3-)
                    echo "  Line $line_num: $content"
                done)
                
                # ให้ AI วิเคราะห์โดยใช้ข้อมูล valid lines เท่านั้น
                local ai_prompt="Analyze this git diff for file: $file

🎯 VALID LINES FOR COMMENTS (must use only these line numbers):
$(echo "$valid_line_numbers" | head -20)

📝 NEWLY ADDED LINES (focus here for reviews):
$added_lines_preview

📄 CONTEXT LINES (can also comment but less priority):
$context_lines_preview

⚠️ CRITICAL: Only comment on line numbers listed in VALID LINES above!
Focus on: Security, Performance, KISS principle, Best practices.

OUTPUT FORMAT: For each issue, output exactly:
LINE_NUMBER:COMMENT_TEXT

RULES:
- LINE_NUMBER must be from VALID LINES list only
- Keep comments under 200 characters
- Include specific improvement suggestions
- Reference variable/function names from the code
- If no issues found, output: NO_ISSUES_FOUND

EXAMPLES:
25:🔒 Use parameterized queries: \`cursor.execute(\"SELECT * FROM users WHERE id = %s\", (user_id,))\`
42:⚡ Use list comprehension: \`active_users = [u for u in users if u.active]\`
15:🎯 Simplify: \`return not user.active\` instead of if/else"

                local ai_response
                ai_response=$(echo "$diff_context" | mods "$ai_prompt")

                if [ -n "$ai_response" ] && [ "$ai_response" != "NO_ISSUES_FOUND" ]; then
                    echo "  🤖 AI found $(echo "$ai_response" | wc -l) suggestions" | gum format
                    
                    # แปลง AI response เป็น inline comments array พร้อม validation
                    while IFS= read -r line; do
                        if [[ "$line" =~ ^[0-9]+:.+ ]]; then
                            local line_num=$(echo "$line" | cut -d':' -f1)
                            local comment_text=$(echo "$line" | cut -d':' -f2-)
                            
                            # ตรวจสอบว่า line number นี้ valid จริงหรือไม่
                            if validate_line_in_diff "$file" "$line_num" "$default_branch"; then
                                inline_comments+=("$file:$line_num:$comment_text")
                                echo "  ✅ Valid comment: $file:$line_num" | gum format
                            else
                                echo "  ❌ REJECTED: $file:$line_num (not in valid diff lines)" | gum format
                                echo "     AI tried to comment on invalid line - this would cause GitHub API error" | gum format
                            fi
                        fi
                    done <<< "$ai_response"
                else
                    echo "  ✅ No issues found in $file" | gum format
                fi
            else
                echo "  📝 No valid comment lines in $file" | gum format
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
        
        # ใช้ GitHub Reviews API แบบ batch เท่านั้น - เรียบง่ายและมีประสิทธิภาพสูงสุด
        echo "🚀 Creating batch review with ${#inline_comments[@]} inline comments..."
        
        # สร้าง JSON array สำหรับ comments โดยใช้ jq (format ใหม่: file:line:comment)
        comments_array="[]"
        for comment in "${inline_comments[@]}"; do
            file_path=$(echo "$comment" | cut -d':' -f1)
            line_num=$(echo "$comment" | cut -d':' -f2)
            comment_text=$(echo "$comment" | cut -d':' -f3-)
            
            echo "  📝 Adding comment: $file_path:$line_num" | gum format
            
            # เพิ่ม comment เข้าไปใน array
            comments_array=$(echo "$comments_array" | jq \
                --arg path "$file_path" \
                --arg line "$line_num" \
                --arg body "$comment_text" \
                '. += [{
                    path: $path,
                    line: ($line | tonumber),
                    body: $body
                }]')
        done
        
        # ทำให้ JSON เป็น compact format และตรวจสอบความถูกต้อง
        comments_array=$(echo "$comments_array" | jq -c .)
        
        echo "🔍 Preview first 3 comments:" | gum format
        echo "$comments_array" | jq '.[:3]' | gum format
        echo ""
        echo "📦 Sending batch review..." | gum format
        
        # ส่ง batch review ด้วย gh api โดยใช้ --raw-field สำหรับ JSON array
        api_response=$(gh api "repos/$owner/$repo/pulls/$pr_number/reviews" \
            --method POST \
            --field body="🤖 **AI Code Review**

✨ ข้อเสนอแนะจาก AI เพื่อปรับปรุงคุณภาพโค้ด

📊 พบ ${#inline_comments[@]} จุดที่สามารถปรับปรุงได้" \
            --field event="COMMENT" \
            --raw-field comments="$comments_array" 2>&1)
        
        if [ $? -eq 0 ]; then
            echo "✅ สร้าง batch review สำเร็จ!" | gum format
            echo "🎯 ${#inline_comments[@]} inline comments ถูกสร้างพร้อมกัน" | gum format
            success_count=${#inline_comments[@]}
            batch_method_count=${#inline_comments[@]}
        else
            echo "❌ ไม่สามารถสร้าง batch review ได้" | gum format
            echo "🔍 Error details:" | gum format
            echo "$api_response" | gum format
            echo ""
            echo "💡 สาเหตุที่เป็นไปได้:" | gum format
            echo "  • Line numbers ไม่อยู่ใน diff (ตรวจสอบ line mapping)" | gum format  
            echo "  • File paths ไม่ถูกต้อง (ต้องเป็น relative path จาก repo root)" | gum format
            echo "  • ไม่มีสิทธิ์ write access ใน repository" | gum format
            echo "  • PR ถูก lock หรือ close แล้ว" | gum format
            success_count=0
        fi
        
        echo ""
        echo "📊 Inline Comments Results Summary:" | gum format
        
        if [ $success_count -gt 0 ]; then
            echo "✅ สร้าง $success_count/${#inline_comments[@]} comments สำเร็จ!" | gum format
            echo ""
            echo "🚀 ใช้ GitHub Reviews API แบบ batch - วิธีที่ดีที่สุด!" | gum format
            echo "⚡ ส่งทุก comments พร้อมกันในครั้งเดียว" | gum format
            echo "🔗 Review จะปรากฏเป็น single review พร้อม inline comments" | gum format
            echo ""
            echo "💡 ดู inline comments ใน Files tab ของ PR" | gum format
        else
            echo "❌ ไม่สามารถสร้าง inline comments ได้" | gum format
            echo "🔍 สาเหตุที่เป็นไปได้:" | gum format
            echo "  • ไม่มีสิทธิ์ write access ใน repository" | gum format
            echo "  • PR อาจถูก lock หรือ close แล้ว" | gum format
            echo "  • Line numbers ไม่ตรงกับ current diff" | gum format
            echo "  • GitHub API มีปัญหาชั่วคราว" | gum format
        fi
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

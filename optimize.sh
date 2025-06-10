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

    echo "Generate a concise commit message following conventional commits:

REQUIREMENTS:
- Type: fix/feat/build/chore/ci/docs/style/refactor/perf/test
- Format: <type>${scope}${breaking_change}: <description>
- Use imperative mood (add, fix, update, remove)
- Max 50 characters total
- Lowercase everything
- Be specific about what changed

EXAMPLES:
✅ feat(auth): add jwt token validation
✅ fix(api): resolve memory leak in user service  
✅ docs: update installation guide
❌ updated some stuff
❌ Fix bug (too vague)

CONTEXT: Analyze the git diff and create ONE line commit message only."
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
            echo "Generate a concise PR title following conventional commits:

REQUIREMENTS:
- Format: <type>(<scope>): <description>
- Types: fix/feat/docs/style/refactor/test/chore/build/ci/perf/revert
- Scope: component/module name (optional but recommended)
- Description: start with lowercase verb, be specific
- Max 50 characters total
- Use imperative mood

EXAMPLES:
✅ feat(auth): add oauth2 integration
✅ fix(database): resolve connection timeout
✅ refactor(ui): simplify button components
❌ Update some files
❌ Bug fixes

OUTPUT: Single line only, no explanations."
            ;;
        "objective")
            echo "Summarize the main objective of this change:

REQUIREMENTS:
- 1-2 sentences maximum
- Focus on business value or technical benefit
- Use present tense
- Be specific about the problem being solved

EXAMPLES:
✅ Improve user authentication security by implementing JWT tokens
✅ Reduce API response time by optimizing database queries
❌ Made some changes to the code
❌ Fixed stuff"
            ;;
        "changelog")
            echo "List the main changes as concise bullet points:

REQUIREMENTS:
- Use present-tense action verbs (add, remove, update, fix)
- Be specific about what changed
- Include technical details when relevant
- Group similar changes together
- Maximum 5-7 bullet points

FORMAT:
- Add user authentication with JWT tokens
- Update database schema for user roles
- Remove deprecated API endpoints
- Fix memory leak in background tasks

FOCUS ON: What actually changed, not how it was implemented."
            ;;
        "review")
            echo "Perform a comprehensive code review with actionable feedback:

🎯 ANALYSIS PRIORITIES (in order):
1. **SECURITY** - Authentication, authorization, input validation, SQL injection, XSS
2. **PERFORMANCE** - Database queries, loops, memory usage, caching opportunities  
3. **RELIABILITY** - Error handling, edge cases, null checks, exception management
4. **MAINTAINABILITY** - Code clarity, naming, function size, separation of concerns
5. **BEST PRACTICES** - Language conventions, design patterns, code standards

📋 REVIEW METHODOLOGY:
- Examine each function for single responsibility
- Check variable and function naming clarity
- Look for complex conditional logic that can be simplified
- Identify repeated code patterns (DRY principle)
- Verify proper error handling and logging
- Check for potential race conditions or concurrency issues
- Assess test coverage implications

🔍 SPECIFIC CHECKS:
**Security Vulnerabilities:**
- Unvalidated user inputs
- Hardcoded credentials or secrets
- Unsafe deserialization
- Missing authentication/authorization
- Potential injection attacks

**Performance Issues:**
- N+1 query problems
- Inefficient loops or algorithms
- Missing database indices
- Large object creation in loops
- Blocking operations without async handling

**Code Quality:**
- Functions longer than 20 lines (consider splitting)
- Deeply nested conditions (max 3 levels)
- Magic numbers or strings (use constants)
- Unclear variable names (avoid abbreviations)
- Missing or outdated comments

🚀 OUTPUT FORMAT:
## 🔒 Security Issues
**Issue**: [Specific problem found]
**Risk**: [Why this is dangerous - impact and likelihood]
**Solution**: [Exact code fix with before/after examples]
**Priority**: [Critical/High/Medium/Low]

## ⚡ Performance Optimizations  
**Issue**: [Performance bottleneck identified]
**Impact**: [Quantify the performance impact]
**Solution**: [Specific optimization with code example]
**Benefit**: [Expected improvement]

## 🧹 Code Quality Improvements
**Issue**: [Maintainability or readability problem]
**Why**: [How this affects code maintenance]
**Solution**: [Refactoring suggestion with example]
**Benefit**: [Improved maintainability aspect]

## ✅ Positive Findings
- [Highlight good practices being followed]
- [Acknowledge well-implemented patterns]
- [Mention appropriate use of frameworks/libraries]

## 💡 Additional Recommendations
- [Architecture suggestions]
- [Testing recommendations]  
- [Documentation improvements]
- [Future refactoring opportunities]

EXAMPLE SECURITY ISSUE:
**Issue**: User input not validated in login endpoint
**Risk**: High - Allows SQL injection attacks that could expose user data
**Solution**: 
```python
# Before (Vulnerable)
query = f\"SELECT * FROM users WHERE email = '{email}'\"

# After (Secure)  
query = \"SELECT * FROM users WHERE email = %s\"
cursor.execute(query, (email,))
```
**Priority**: Critical - Fix immediately

EXAMPLE PERFORMANCE ISSUE:
**Issue**: Database query inside loop causing N+1 problem
**Impact**: 100ms per iteration, scales poorly with data growth
**Solution**:
```python
# Before (Slow)
for user in users:
    orders = db.query(\"SELECT * FROM orders WHERE user_id = ?\", user.id)

# After (Fast)
user_ids = [u.id for u in users]  
all_orders = db.query(\"SELECT * FROM orders WHERE user_id IN (?)\", user_ids)
orders_by_user = group_by(all_orders, 'user_id')
```
**Benefit**: Reduces database calls from N to 1, improves response time by ~80%

Be thorough, specific, and educational. Focus on actionable improvements."
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
        
        echo ""
        if gum confirm "🔍 ต้องการให้ AI review โค้ดใน PR นี้ต่อเลยหรือไม่?"; then
            echo ""
            gum style --foreground 212 "🔄 เริ่มต้น AI Code Review..."
            
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

    if [ -z "$pr_number" ]; then
        pr_number=$(gh pr view --json number --jq '.number' 2>/dev/null)
        if [ -z "$pr_number" ]; then
            echo "🚨 ไม่พบ PR ในสาขาปัจจุบัน กรุณาระบุ PR number หรือสร้าง PR ก่อน"
            return 1
        fi
    fi

    gum style --foreground 212 "🔍 กำลังวิเคราะห์โค้ดใน PR #$pr_number..."

    local pr_title=$(gh pr view "$pr_number" --json title --jq '.title')
    echo "📋 PR: $pr_title"

    local review_type
    review_type=$(gum choose "💬 General Review (PR comment)" "🎯 Inline Comments (Line-specific)" "🔄 ทั้งคู่ (Both)")

    if [[ "$review_type" == *"General"* ]] || [[ "$review_type" == *"ทั้งคู่"* ]]; then
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
    
    git diff "$default_branch".."HEAD" -- "$file" | awk '
        BEGIN { 
            in_hunk = 0
            new_line_current = 0
        }
        /^@@/ {
            if (match($0, /\+([0-9]+)/)) {
                new_line_current = substr($0, RSTART+1, RLENGTH-1)
                in_hunk = 1
            }
            next
        }
        in_hunk && /^[+]/ && !/^\+\+\+/ {
            print new_line_current ":ADDED:" substr($0, 2)
            new_line_current++
        }
        in_hunk && /^[ ]/ {
            print new_line_current ":CONTEXT:" substr($0, 2)
            new_line_current++
        }
        in_hunk && /^[-]/ && !/^---/ {
            # Deleted lines don't increment new_line_current
        }
    '
}

validate_line_in_diff() {
    local file="$1"
    local line_num="$2"
    local default_branch="$3"
    
    local valid_lines
    valid_lines=$(get_valid_comment_lines "$file" "$default_branch")
    
    if echo "$valid_lines" | grep -q "^$line_num:"; then
        local line_type
        line_type=$(echo "$valid_lines" | grep "^$line_num:" | cut -d':' -f2 | head -1)
        if [ "$line_type" = "ADDED" ]; then
            echo "    🎯 Line $line_num is valid (NEWLY ADDED)" >&2
        else
            echo "    📝 Line $line_num is valid (CONTEXT)" >&2
        fi
        return 0
    else
        return 1
    fi
}

get_enhanced_inline_prompt() {
    local file="$1"
    local valid_line_numbers="$2"
    local added_lines_preview="$3"
    local context_lines_preview="$4"

    echo "🤖 **ADVANCED CODE ANALYSIS FOR: $file**

🎯 **VALID LINE NUMBERS** (CRITICAL - Only use these):
$valid_line_numbers

📝 **NEWLY ADDED CODE** (Primary focus):
$added_lines_preview

📄 **CONTEXT LINES** (Secondary focus):
$context_lines_preview

---

🔍 **ANALYSIS FRAMEWORK**:

**1. SECURITY SCAN** (Priority 1):
- Input validation vulnerabilities
- SQL injection possibilities  
- XSS vulnerabilities
- Authentication/authorization bypass
- Hardcoded secrets or credentials
- Unsafe deserialization
- Path traversal vulnerabilities

**2. PERFORMANCE ANALYSIS** (Priority 2):
- Database query optimization (N+1, missing indexes)
- Algorithm complexity (O(n²) vs O(n))
- Memory leaks or excessive allocations
- Blocking operations in async contexts
- Inefficient data structures
- Missing caching opportunities

**3. RELIABILITY CHECKS** (Priority 3):
- Error handling completeness
- Null/undefined checks
- Edge case handling
- Resource cleanup (files, connections)
- Race condition potential
- Exception propagation

**4. CODE QUALITY** (Priority 4):
- Function complexity (cyclomatic complexity > 10)
- Naming conventions and clarity
- DRY principle violations
- Single responsibility principle
- Magic numbers/strings
- Code duplication

**5. MAINTAINABILITY** (Priority 5):
- Documentation needs
- Test coverage implications
- Configuration management
- Logging and monitoring
- Deployment considerations

---

🎯 **OUTPUT FORMAT** (STRICT):
For each issue found, output EXACTLY:
LINE_NUMBER:EMOJI CATEGORY: SPECIFIC_ISSUE_DESCRIPTION | SOLUTION_PREVIEW

**EMOJI CATEGORIES**:
- 🔒 Security
- ⚡ Performance  
- 🛡️ Reliability
- 🧹 Code Quality
- 📚 Maintainability

**EXAMPLES**:
25:🔒 Security: SQL injection risk in user query | Use parameterized queries: \`WHERE id = %s\`
42:⚡ Performance: N+1 query in loop | Batch query: \`SELECT * WHERE id IN (%s)\`
18:🛡️ Reliability: Missing null check on user object | Add: \`if (!user) return null;\`
33:🧹 Code Quality: Function too complex (15 lines) | Split into smaller functions
12:📚 Maintainability: Magic number 86400 | Use constant: \`const SECONDS_PER_DAY = 86400\`

---

⚠️ **CRITICAL RULES**:
1. ONLY use line numbers from VALID LINE NUMBERS list
2. Focus on NEWLY ADDED CODE first
3. Keep suggestions under 100 characters
4. Provide specific, actionable solutions
5. If no issues found, output: NO_ISSUES_FOUND
6. Maximum 8 comments per file (quality over quantity)
7. Include variable/function names from actual code
8. Prioritize critical security and performance issues

---

🧠 **ANALYSIS STRATEGY**:
1. Scan for security vulnerabilities first
2. Check performance bottlenecks  
3. Verify error handling
4. Review code clarity and maintainability
5. Suggest specific improvements with examples"
}

generate_inline_comments() {
    local pr_number="$1"
    local default_branch="$2"

    gum style --foreground 212 "🎯 สร้าง enhanced inline comments with advanced analysis..."

    local changed_files
    changed_files=$(git diff --name-only "$default_branch"..)

    if [ -z "$changed_files" ]; then
        echo "🚨 ไม่พบไฟล์ที่เปลี่ยนแปลง"
        return 1
    fi

    echo "📁 ไฟล์ที่เปลี่ยนแปลง:"
    echo "$changed_files" | gum format

    local -a inline_comments=()
    
    while IFS= read -r file; do
        if [ -f "$file" ]; then
            echo "🔍 วิเคราะห์ไฟล์: $file" | gum format
            
            local valid_lines
            valid_lines=$(get_valid_comment_lines "$file" "$default_branch")
            
            if [ -n "$valid_lines" ]; then
                lines_count=$(echo "$valid_lines" | wc -l)
                echo "  📊 Found $lines_count valid comment lines" | gum format
                
                local valid_line_numbers
                valid_line_numbers=$(echo "$valid_lines" | cut -d':' -f1 | sort -n | uniq | head -20)
                
                local added_lines_preview
                local context_lines_preview
                added_lines_preview=$(echo "$valid_lines" | grep ":ADDED:" | head -10 | while IFS= read -r line; do
                    line_num=$(echo "$line" | cut -d':' -f1)
                    content=$(echo "$line" | cut -d':' -f3- | head -c 80)
                    echo "  Line $line_num: $content"
                done)
                
                context_lines_preview=$(echo "$valid_lines" | grep ":CONTEXT:" | head -5 | while IFS= read -r line; do
                    line_num=$(echo "$line" | cut -d':' -f1)
                    content=$(echo "$line" | cut -d':' -f3- | head -c 60)
                    echo "  Line $line_num: $content"
                done)
                
                local diff_context
                diff_context=$(git diff "$default_branch".."HEAD" -- "$file")
                
                local enhanced_prompt
                enhanced_prompt=$(get_enhanced_inline_prompt "$file" "$valid_line_numbers" "$added_lines_preview" "$context_lines_preview")
                
                echo "  🤖 Running enhanced AI analysis..." | gum format
                local ai_response
                ai_response=$(echo "$diff_context" | mods "$enhanced_prompt")

                if [ -n "$ai_response" ] && [ "$ai_response" != "NO_ISSUES_FOUND" ]; then
                    echo "  🎯 AI found $(echo "$ai_response" | wc -l) suggestions" | gum format
                    
                    while IFS= read -r line; do
                        if [[ "$line" =~ ^[0-9]+:.+ ]]; then
                            local line_num=$(echo "$line" | cut -d':' -f1)
                            local comment_text=$(echo "$line" | cut -d':' -f2-)
                            
                            if validate_line_in_diff "$file" "$line_num" "$default_branch"; then
                                inline_comments+=("$file:$line_num:$comment_text")
                                echo "  ✅ Valid comment: $file:$line_num" | gum format
                            else
                                echo "  ❌ REJECTED: $file:$line_num (invalid line)" | gum format
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

    echo ""
    echo "🎯 Enhanced Inline Comments Preview:" | gum format
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

    if gum confirm "🎯 ต้องการส่ง enhanced inline comments เหล่านี้ไปที่ PR หรือไม่?"; then
        local repo_info
        repo_info=$(gh repo view --json owner,name --jq '{owner: .owner.login, name: .name}')
        local owner=$(echo "$repo_info" | jq -r '.owner')
        local repo=$(echo "$repo_info" | jq -r '.name')

        echo "🚀 กำลังส่ง ${#inline_comments[@]} enhanced inline comments..." | gum format
        
        comments_array="[]"
        for comment in "${inline_comments[@]}"; do
            file_path=$(echo "$comment" | cut -d':' -f1)
            line_num=$(echo "$comment" | cut -d':' -f2)
            comment_text=$(echo "$comment" | cut -d':' -f3-)
            
            echo "  📝 Adding comment: $file_path:$line_num" | gum format
            
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
        
        comments_array=$(echo "$comments_array" | jq -c .)
        
        echo "📦 Sending enhanced batch review..." | gum format
        
        api_response=$(gh api "repos/$owner/$repo/pulls/$pr_number/reviews" \
            --method POST \
            --field body="🤖 **Enhanced AI Code Review**

🔍 **Multi-Layer Analysis Results**
- 🔒 Security vulnerabilities
- ⚡ Performance optimizations  
- 🛡️ Reliability improvements
- 🧹 Code quality enhancements
- 📚 Maintainability suggestions

📊 พบ ${#inline_comments[@]} จุดที่สามารถปรับปรุงได้

💡 แต่ละ comment มีคำแนะนำเฉพาะเจาะจงพร้อมตัวอย่างโค้ด" \
            --field event="COMMENT" \
            --raw-field comments="$comments_array" 2>&1)
        
        if [ $? -eq 0 ]; then
            echo "✅ สร้าง enhanced batch review สำเร็จ!" | gum format
            echo "🎯 ${#inline_comments[@]} enhanced inline comments ถูกสร้างพร้อมกัน" | gum format
            echo "🔍 ใช้ multi-layer analysis framework" | gum format
            echo "💡 ดู inline comments ใน Files tab ของ PR" | gum format
        else
            echo "❌ ไม่สามารถสร้าง enhanced batch review ได้" | gum format
            echo "🔍 Error details:" | gum format
            echo "$api_response" | gum format
        fi
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
    echo "  git-relax rv [PR#]     - Enhanced AI code review (general/inline)"
    echo "                          (if PR# not specified, uses current PR)"
fi

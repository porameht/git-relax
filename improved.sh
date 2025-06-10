#!/bin/bash

set -e

# Professional logging with timestamps and log levels
log() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local icon=""
    
    case "$level" in
        "INFO") icon="ℹ️" ;;
        "SUCCESS") icon="✅" ;;
        "WARNING") icon="⚠️" ;;
        "ERROR") icon="❌" ;;
        "PROGRESS") icon="🔄" ;;
        *) icon="📝" ;;
    esac
    
    echo "[$timestamp] $icon $message"
}

# Professional error handling with context
handle_error() {
    local exit_code=$?
    local line_number=$1
    log "ERROR" "Script failed at line $line_number with exit code $exit_code"
    log "ERROR" "Please check the prerequisites and try again"
    exit $exit_code
}

trap 'handle_error $LINENO' ERR

# Check if command exists with professional messaging
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Validate prerequisites with detailed feedback
validate_prerequisites() {
    log "INFO" "Validating system prerequisites..."
    
    local missing_commands=()
    for cmd in git gum gh mods; do
        if ! command_exists "$cmd"; then
            missing_commands+=("$cmd")
        fi
    done
    
    if [ ${#missing_commands[@]} -ne 0 ]; then
        log "ERROR" "Missing required dependencies: ${missing_commands[*]}"
        log "INFO" "Please install the following tools:"
        for cmd in "${missing_commands[@]}"; do
            case "$cmd" in
                "git") echo "  - Git: https://git-scm.com/" ;;
                "gum") echo "  - Gum: https://github.com/charmbracelet/gum" ;;
                "gh") echo "  - GitHub CLI: https://cli.github.com/" ;;
                "mods") echo "  - Mods: https://github.com/charmbracelet/mods" ;;
            esac
        done
        exit 1
    fi
    
    log "SUCCESS" "All prerequisites validated successfully"
}

# Get default branch with proper error handling
get_default_branch() {
    local default_branch
    default_branch=$(git remote show origin 2>/dev/null | grep 'HEAD branch' | cut -d' ' -f5)
    
    if [ -z "$default_branch" ]; then
        log "WARNING" "Could not determine default branch, defaulting to 'main'"
        default_branch="main"
    fi
    
    echo "$default_branch"
}

# Professional commit message generation rules
get_commit_rules() {
    local scope="$1"
    local breaking_change="$2"

    cat << EOF
Generate a professional commit message following conventional commits specification:

REQUIREMENTS:
- Type: feat|fix|docs|style|refactor|test|build|ci|perf|chore|revert
- Format: <type>${scope}${breaking_change}: <description>
- Use imperative mood (add, fix, update, remove, implement)
- Maximum 50 characters total
- Use lowercase for consistency
- Be specific and descriptive about the change

BEST PRACTICES:
✅ feat(auth): implement jwt token validation
✅ fix(database): resolve connection timeout issue
✅ docs(readme): update installation instructions
✅ refactor(utils): extract helper functions
✅ perf(query): optimize database index usage
❌ updated some stuff (too vague)
❌ Fix bug (lacks specificity)
❌ WIP commit (not descriptive)

CONTEXT: Analyze the staged changes and generate ONE concise commit message.
Focus on the primary purpose and impact of the changes.
EOF
}

# Enhanced commit message generation with validation
generate_commit_message() {
    log "INFO" "Initiating commit message generation process"
    
    # Check for staged changes
    if ! git diff --cached --quiet; then
        log "INFO" "Staged changes detected, proceeding with commit message generation"
    else
        log "WARNING" "No staged changes found. Please stage your changes first with 'git add'"
        return 1
    fi
    
    local commit_message
    local breaking_change=""
    local scope=""

    # Professional prompts for user input
    echo
    if gum confirm "Does this commit introduce breaking changes?"; then
        breaking_change="!"
        log "INFO" "Breaking change flag will be included"
    fi

    scope=$(gum input --placeholder "Enter scope (e.g., auth, api, ui) - optional")
    if [ -n "$scope" ]; then
        scope="($scope)"
        log "INFO" "Scope set to: $scope"
    fi

    log "PROGRESS" "Generating commit message using AI analysis..."
    local rules=$(get_commit_rules "$scope" "$breaking_change")
    commit_message=$(git diff --cached | mods "$rules" | tr '[:upper:]' '[:lower:]')

    # Validate commit message length
    if [ ${#commit_message} -gt 50 ]; then
        log "WARNING" "Generated commit message exceeds 50 characters (${#commit_message} chars)"
        log "INFO" "Consider shortening the scope or description"
    fi

    echo
    log "SUCCESS" "Generated commit message:"
    echo "  → $commit_message"
    echo

    if gum confirm "Proceed with this commit message?"; then
        git commit -m "$commit_message"
        log "SUCCESS" "Commit created successfully"
    elif gum confirm "Generate a new commit message?"; then
        generate_commit_message
    else
        log "INFO" "Commit operation cancelled by user"
    fi
}

# Professional PR rules with comprehensive guidance
get_pr_rules() {
    local rule_type="$1"
    
    case "$rule_type" in
        "title")
            cat << EOF
Generate a professional pull request title following conventional commits:

REQUIREMENTS:
- Format: <type>(<scope>): <description>
- Types: feat|fix|docs|style|refactor|test|chore|build|ci|perf|revert
- Scope: component/module name (recommended for clarity)
- Description: imperative mood, specific action, lowercase start
- Maximum 50 characters for optimal display
- Clear and descriptive for reviewers

EXAMPLES:
✅ feat(authentication): add oauth2 integration
✅ fix(database): resolve connection pool timeout
✅ refactor(components): simplify button hierarchy
✅ perf(queries): optimize user data retrieval
❌ Update files (lacks specificity)
❌ Bug fixes (too generic)
❌ WIP changes (not ready for PR)

OUTPUT: Single line only, no explanations or formatting.
EOF
            ;;
        "objective")
            cat << EOF
Summarize the main objective and business value of this change:

REQUIREMENTS:
- 1-2 concise sentences maximum
- Focus on user impact or technical benefit
- Use present tense for consistency
- Highlight the problem being solved
- Avoid implementation details

EXAMPLES:
✅ Enhance user authentication security by implementing industry-standard JWT tokens
✅ Improve API response performance by optimizing database query execution
✅ Streamline deployment process by automating configuration management
❌ Changed some code files (lacks context)
❌ Fixed various issues (too vague)

OUTPUT: Clear, professional summary focusing on value proposition.
EOF
            ;;
        "changelog")
            cat << EOF
Generate a comprehensive changelog with clear, actionable bullet points:

REQUIREMENTS:
- Use action verbs in present tense (add, remove, update, fix, optimize)
- Be specific about what changed and why
- Include technical details when relevant for reviewers
- Group related changes logically
- Maximum 7 bullet points for readability
- Order by importance/impact

FORMAT EXAMPLES:
- Add user authentication with JWT token validation
- Update database schema to support role-based permissions  
- Remove deprecated API endpoints (v1.x compatibility)
- Fix memory leak in background task processing
- Optimize database queries to reduce response time by 40%
- Refactor utility functions for better maintainability
- Update documentation with new API examples

FOCUS: What changed, why it matters, and any notable technical details.
EOF
            ;;
        "review")
            cat << EOF
Perform a comprehensive, professional code review with actionable insights:

🎯 ANALYSIS FRAMEWORK (Priority Order):

1. **SECURITY ASSESSMENT** (Critical)
   - Input validation and sanitization
   - Authentication and authorization controls
   - SQL injection and XSS vulnerability checks
   - Sensitive data exposure risks
   - Cryptographic implementation review

2. **PERFORMANCE OPTIMIZATION** (High)
   - Database query efficiency (N+1 problems, indexing)
   - Algorithm complexity analysis
   - Memory usage patterns
   - Caching strategy evaluation
   - Async operation handling

3. **RELIABILITY & ROBUSTNESS** (High)
   - Error handling completeness
   - Edge case coverage
   - Resource management (connections, files)
   - Concurrency safety
   - Graceful degradation

4. **CODE QUALITY & MAINTAINABILITY** (Medium)
   - Function complexity and single responsibility
   - Naming conventions and clarity
   - DRY principle adherence
   - Design pattern usage
   - Code documentation quality

5. **BEST PRACTICES COMPLIANCE** (Medium)
   - Language-specific conventions
   - Framework usage patterns
   - Testing coverage implications
   - Configuration management
   - Logging and monitoring integration

📋 DETAILED REVIEW METHODOLOGY:

**Security Checklist:**
- Validate all user inputs at application boundaries
- Verify authentication mechanisms are properly implemented
- Check for hardcoded credentials or API keys
- Ensure proper session management
- Review data encryption and hashing practices

**Performance Analysis:**
- Identify potential bottlenecks in critical paths
- Check for inefficient database operations
- Analyze memory allocation patterns
- Review async/await usage for non-blocking operations
- Evaluate caching opportunities

**Code Quality Metrics:**
- Functions should be under 20 lines (consider refactoring if exceeded)
- Cyclomatic complexity should be reasonable (< 10)
- Variable and function names should be self-documenting
- Avoid deep nesting (max 3 levels recommended)
- Eliminate magic numbers and strings

🚀 PROFESSIONAL OUTPUT FORMAT:

## 🔐 Security Analysis
**Finding**: [Specific security concern identified]
**Risk Assessment**: [Impact level and probability]
**Recommendation**: [Detailed solution with code example]
**Priority**: Critical | High | Medium | Low

## ⚡ Performance Insights  
**Optimization Opportunity**: [Performance bottleneck description]
**Impact Analysis**: [Quantified performance implications]
**Solution**: [Specific optimization approach with implementation]
**Expected Benefit**: [Measurable improvement estimate]

## 🛡️ Reliability Improvements
**Issue**: [Reliability or robustness concern]
**Consequences**: [Potential failure scenarios]
**Resolution**: [Recommended fix with error handling approach]
**Testing Consideration**: [How to verify the fix]

## 🧹 Code Quality Enhancements
**Observation**: [Maintainability or readability issue]
**Impact on Maintenance**: [How this affects future development]
**Refactoring Suggestion**: [Specific improvement with example]
**Long-term Benefit**: [Maintainability improvement]

## ✅ Positive Observations
- [Acknowledge well-implemented security practices]
- [Highlight efficient algorithm choices]
- [Recognize good architectural decisions]
- [Commend clear documentation and comments]

## 💡 Strategic Recommendations
- [Architecture improvement suggestions]
- [Testing strategy enhancements]  
- [Documentation gaps to address]
- [Future refactoring opportunities]
- [Performance monitoring recommendations]

EXAMPLE SECURITY FINDING:
**Finding**: SQL query construction uses string concatenation with user input
**Risk Assessment**: High - Enables SQL injection attacks potentially exposing entire database
**Recommendation**: 
```python
# Current (Vulnerable)
query = f"SELECT * FROM users WHERE email = '{user_email}'"

# Recommended (Secure)  
query = "SELECT * FROM users WHERE email = %s"
cursor.execute(query, (user_email,))
```
**Priority**: Critical - Address before merge

EXAMPLE PERFORMANCE INSIGHT:
**Optimization Opportunity**: Database queries executed within loop causing N+1 performance issue
**Impact Analysis**: Linear degradation with data growth, current 100ms per iteration
**Solution**:
```python
# Current (Inefficient)
for user in users:
    orders = db.execute("SELECT * FROM orders WHERE user_id = ?", user.id)

# Optimized (Efficient)
user_ids = [user.id for user in users]  
all_orders = db.execute("SELECT * FROM orders WHERE user_id IN (?)", user_ids)
orders_by_user = group_by(all_orders, 'user_id')
```
**Expected Benefit**: 80% reduction in database load, sub-10ms response time

Provide thorough, professional analysis with specific, implementable recommendations.
Focus on delivering value through actionable insights that improve code quality and system reliability.
EOF
            ;;
    esac
}

# Enhanced PR generation with professional workflow
generate_pr_info() {
    log "INFO" "Initiating pull request creation workflow"
    
    local default_branch
    default_branch=$(get_default_branch)
    log "INFO" "Default branch identified as: $default_branch"

    # Check for unpushed commits
    if ! git diff --quiet "$default_branch"..HEAD; then
        log "INFO" "Changes detected between current branch and $default_branch"
    else
        log "WARNING" "No changes detected. Ensure you have commits to include in the PR"
        return 1
    fi

    local pr_title pr_body choice

    echo
    choice=$(gum choose "🤖 AI-Generated (Recommended)" "👨‍💻 Manual Configuration")

    if [[ "$choice" == *"AI-Generated"* ]]; then
        log "PROGRESS" "Generating PR title using AI analysis..."
        pr_title=$(git diff "$default_branch".. | mods "$(get_pr_rules "title")" | tr '[:upper:]' '[:lower:]')
        log "INFO" "AI-generated title: $pr_title"
    else
        log "INFO" "Manual PR configuration selected"
        local type scope pr_title_prefix pr_summary
        
        echo "Select commit type:"
        type=$(gum choose "feat" "fix" "docs" "style" "refactor" "test" "chore" "perf" "build" "ci" "revert")
        
        scope=$(gum input --placeholder "Enter scope (e.g., auth, api, ui) - optional")
        [ -n "$scope" ] && scope="($scope)"
        
        pr_title_prefix="$type$scope"
        
        log "PROGRESS" "Generating description using AI analysis..."
        pr_summary=$(git diff "$default_branch".. | mods "Generate concise PR description: imperative mood, specific action, max 30 characters" | tr '[:upper:]' '[:lower:]')
        pr_title="$pr_title_prefix: $pr_summary"
    fi

    log "PROGRESS" "Generating comprehensive PR body..."

    local objective=$(git diff "$default_branch".. | mods "$(get_pr_rules "objective")")
    local jira_ticket=$(gum input --placeholder "JIRA/Issue URL (optional)")
    local changelog=$(git diff "$default_branch".. | mods "$(get_pr_rules "changelog")")
    local deployment_dependency=$(gum input --placeholder "Deployment dependencies (optional)")

    # Professional PR body template
    pr_body="## 🎯 Objective
${objective}

## 🔗 Related Issues
${jira_ticket:-"N/A - No linked issues"}

## 📋 Changes Summary
${changelog}

## 🚀 Deployment Considerations
${deployment_dependency:-"No special deployment requirements"}

## 🧪 Testing & Validation

**Testing Checklist:**
- [ ] Unit tests pass
- [ ] Integration tests pass  
- [ ] Manual testing completed
- [ ] Performance impact assessed
- [ ] Security considerations reviewed

**Test Results:**
(Add screenshots, test outputs, or performance metrics here)

## 📝 Reviewer Notes

**Areas requiring special attention:**
- Review security implications
- Validate performance impact
- Check error handling completeness

**Additional Context:**
(Add any context that would help reviewers understand the changes)"

    echo
    log "SUCCESS" "Pull request preview generated:"
    echo
    echo "Title: $pr_title"
    echo
    echo "Body Preview:"
    echo "$pr_body" | head -20
    echo "... (truncated for preview)"
    echo

    if gum confirm "Create pull request with this configuration?"; then
        log "PROGRESS" "Creating pull request..."
        
        local pr_url
        pr_url=$(gh pr create \
            --title "$pr_title" \
            --body "$pr_body" 2>&1)
        
        if [ $? -eq 0 ]; then
            log "SUCCESS" "Pull request created successfully"
            echo "🔗 PR URL: $pr_url"
            
            echo
            if gum confirm "Would you like to run an AI code review on this PR?"; then
                echo
                log "PROGRESS" "Initiating AI code review process..."
                
                local pr_number
                pr_number=$(echo "$pr_url" | grep -o '[0-9]\+$')
                generate_code_review "$pr_number"
            fi
        else
            log "ERROR" "Failed to create pull request"
            echo "$pr_url"
            return 1
        fi
    else
        log "INFO" "Pull request creation cancelled by user"
    fi
}

# Professional code review with comprehensive analysis
generate_code_review() {
    local pr_number="$1"
    local default_branch
    default_branch=$(get_default_branch)

    if [ -z "$pr_number" ]; then
        log "INFO" "No PR number provided, attempting to detect current PR..."
        pr_number=$(gh pr view --json number --jq '.number' 2>/dev/null)
        if [ -z "$pr_number" ]; then
            log "ERROR" "Could not find PR in current branch. Please specify PR number or create a PR first"
            return 1
        fi
    fi

    log "PROGRESS" "Analyzing code in PR #$pr_number..."

    local pr_title=$(gh pr view "$pr_number" --json title --jq '.title')
    log "INFO" "Reviewing PR: $pr_title"

    local review_type
    echo
    echo "Select review type:"
    review_type=$(gum choose "💬 Comprehensive Review (General)" "🎯 Line-by-Line Analysis (Inline)" "🔄 Complete Analysis (Both)")

    if [[ "$review_type" == *"Comprehensive"* ]] || [[ "$review_type" == *"Complete"* ]]; then
        log "PROGRESS" "Generating comprehensive code review..."
        
        local review_comment
        review_comment=$(git diff "$default_branch".. | mods "$(get_pr_rules "review")")

        echo
        log "SUCCESS" "Comprehensive AI Review Generated:"
        echo
        echo "$review_comment"
        echo

        if gum confirm "Post this comprehensive review to the PR?"; then
            gh pr comment "$pr_number" --body "$review_comment"
            log "SUCCESS" "Comprehensive review posted successfully"
        fi
    fi

    if [[ "$review_type" == *"Line-by-Line"* ]] || [[ "$review_type" == *"Complete"* ]]; then
        generate_inline_comments "$pr_number" "$default_branch"
    fi
}

# Enhanced inline comment analysis with validation
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

# Validate line numbers for inline comments
validate_line_in_diff() {
    local file="$1"
    local line_num="$2"
    local default_branch="$3"
    
    local valid_lines
    valid_lines=$(get_valid_comment_lines "$file" "$default_branch")
    
    if echo "$valid_lines" | grep -q "^$line_num:"; then
        local line_type
        line_type=$(echo "$valid_lines" | grep "^$line_num:" | cut -d':' -f2 | head -1)
        case "$line_type" in
            "ADDED") log "INFO" "Line $line_num validated (newly added)" ;;
            "CONTEXT") log "INFO" "Line $line_num validated (context)" ;;
        esac
        return 0
    else
        return 1
    fi
}

# Professional inline comment prompt with comprehensive analysis
get_enhanced_inline_prompt() {
    local file="$1"
    local valid_line_numbers="$2"
    local added_lines_preview="$3"
    local context_lines_preview="$4"

    cat << EOF
🔍 **PROFESSIONAL CODE ANALYSIS FOR: $file**

📍 **VALID LINE NUMBERS** (CRITICAL - Only use these exact line numbers):
$valid_line_numbers

🆕 **NEWLY ADDED CODE** (Primary analysis focus):
$added_lines_preview

📄 **SURROUNDING CONTEXT** (Secondary reference):
$context_lines_preview

---

🎯 **COMPREHENSIVE ANALYSIS FRAMEWORK**

**1. SECURITY ASSESSMENT** (Highest Priority):
- Input validation and sanitization gaps
- SQL injection vulnerability patterns
- Cross-site scripting (XSS) potential  
- Authentication and authorization bypass risks
- Sensitive data exposure in logs or responses
- Cryptographic implementation weaknesses
- Path traversal and file access vulnerabilities

**2. PERFORMANCE OPTIMIZATION** (High Priority):
- Database query efficiency (N+1 queries, missing indexes)
- Algorithm time complexity analysis (O(n²) vs O(n log n))
- Memory allocation patterns and potential leaks
- Synchronous operations blocking async contexts
- Inefficient data structure usage
- Missing caching opportunities for expensive operations

**3. RELIABILITY & ERROR HANDLING** (High Priority):
- Exception handling completeness and appropriateness
- Null pointer and undefined value checks
- Resource cleanup (database connections, file handles)
- Edge case handling for boundary conditions
- Race condition potential in concurrent code
- Circuit breaker patterns for external dependencies

**4. CODE QUALITY & MAINTAINABILITY** (Medium Priority):
- Function complexity analysis (cyclomatic complexity)
- Single Responsibility Principle adherence
- DRY (Don't Repeat Yourself) principle violations
- Naming convention consistency and clarity
- Magic numbers and hardcoded values
- Code documentation and comment quality

**5. BEST PRACTICES & STANDARDS** (Medium Priority):
- Language-specific idiom compliance
- Framework usage pattern adherence
- Configuration management best practices
- Logging and monitoring integration
- Test coverage implications
- Deployment and operational considerations

---

🎯 **STRICT OUTPUT FORMAT**

For each issue discovered, use EXACTLY this format:
LINE_NUMBER:📊 CATEGORY: SPECIFIC_ISSUE | ACTIONABLE_SOLUTION

**CATEGORY ICONS & MEANINGS:**
- 🔐 Security (Critical vulnerabilities)
- ⚡ Performance (Optimization opportunities)  
- 🛡️ Reliability (Error handling & robustness)
- 🧹 Quality (Code maintainability)
- 📋 Standards (Best practice compliance)

**PROFESSIONAL EXAMPLES:**
42:🔐 Security: Unvalidated user input in SQL query | Use parameterized queries: \`cursor.execute("SELECT * FROM users WHERE id = %s", [user_id])\`
15:⚡ Performance: N+1 query pattern in user iteration | Batch load: \`users = User.objects.prefetch_related('orders').all()\`
28:🛡️ Reliability: Missing null check for API response | Add validation: \`if (!response?.data) throw error\`
35:🧹 Quality: Function exceeds complexity threshold | Extract helper methods: \`validateInput()\`, \`processData()\`
8:📋 Standards: Magic number 3600 used directly | Define constant: \`const CACHE_TTL_SECONDS = 3600\`

---

⚠️ **CRITICAL REQUIREMENTS**

1. **Line Number Validation**: ONLY use line numbers from the VALID LINE NUMBERS list
2. **Focus Priority**: Analyze NEWLY ADDED CODE first, context second
3. **Solution Specificity**: Provide concrete, implementable solutions
4. **Brevity**: Keep each suggestion under 100 characters
5. **Quality Control**: Maximum 8 high-quality comments per file
6. **Actionability**: Every comment must include a specific fix
7. **Evidence-Based**: Reference actual variable/function names from the code
8. **Priority-Driven**: Security and performance issues take precedence

---

🚀 **ANALYSIS EXECUTION STRATEGY**

1. **Security Scan**: Systematically check for common vulnerabilities
2. **Performance Review**: Identify bottlenecks and optimization opportunities
3. **Reliability Assessment**: Evaluate error handling and edge cases
4. **Quality Evaluation**: Review code structure and maintainability
5. **Standards Compliance**: Check adherence to best practices

**Special Instructions:**
- If no significant issues are found, respond with: NO_ISSUES_FOUND
- Focus on actionable improvements that provide clear value
- Prioritize issues by potential impact and fix complexity
- Include specific code examples in solutions when possible
- Consider the broader context and system architecture

**Quality Threshold:**
Only report issues that materially impact security, performance, reliability, or long-term maintainability. Avoid nitpicking or subjective style preferences unless they significantly affect code quality.
EOF
}

# Professional inline comment generation with comprehensive validation
generate_inline_comments() {
    local pr_number="$1"
    local default_branch="$2"

    log "PROGRESS" "Generating professional inline code analysis..."

    local changed_files
    changed_files=$(git diff --name-only "$default_branch"..)

    if [ -z "$changed_files" ]; then
        log "WARNING" "No changed files detected in this PR"
        return 1
    fi

    local file_count=$(echo "$changed_files" | wc -l)
    log "INFO" "Analyzing $file_count changed files:"
    echo "$changed_files" | sed 's/^/  - /'

    local -a inline_comments=()
    local files_processed=0
    
    while IFS= read -r file; do
        if [ -f "$file" ]; then
            ((files_processed++))
            log "PROGRESS" "[$files_processed/$file_count] Analyzing: $file"
            
            local valid_lines
            valid_lines=$(get_valid_comment_lines "$file" "$default_branch")
            
            if [ -n "$valid_lines" ]; then
                local lines_count=$(echo "$valid_lines" | wc -l)
                log "INFO" "  Found $lines_count commentable lines"
                
                # Extract valid line numbers (limited for API efficiency)
                local valid_line_numbers
                valid_line_numbers=$(echo "$valid_lines" | cut -d':' -f1 | sort -n | uniq | head -25)
                
                # Generate previews for AI analysis
                local added_lines_preview
                local context_lines_preview
                added_lines_preview=$(echo "$valid_lines" | grep ":ADDED:" | head -15 | while IFS= read -r line; do
                    local line_num=$(echo "$line" | cut -d':' -f1)
                    local content=$(echo "$line" | cut -d':' -f3- | head -c 120)
                    echo "    Line $line_num: $content"
                done)
                
                context_lines_preview=$(echo "$valid_lines" | grep ":CONTEXT:" | head -8 | while IFS= read -r line; do
                    local line_num=$(echo "$line" | cut -d':' -f1)
                    local content=$(echo "$line" | cut -d':' -f3- | head -c 80)
                    echo "    Line $line_num: $content"
                done)
                
                # Get comprehensive diff context
                local diff_context
                diff_context=$(git diff "$default_branch".."HEAD" -- "$file")
                
                # Generate enhanced analysis prompt
                local enhanced_prompt
                enhanced_prompt=$(get_enhanced_inline_prompt "$file" "$valid_line_numbers" "$added_lines_preview" "$context_lines_preview")
                
                log "PROGRESS" "  Running comprehensive AI analysis..."
                local ai_response
                ai_response=$(echo "$diff_context" | mods "$enhanced_prompt")

                if [ -n "$ai_response" ] && [ "$ai_response" != "NO_ISSUES_FOUND" ]; then
                    local suggestions_count=$(echo "$ai_response" | wc -l)
                    log "INFO" "  AI generated $suggestions_count suggestions"
                    
                    # Process each AI suggestion with validation
                    while IFS= read -r line; do
                        if [[ "$line" =~ ^[0-9]+:.+ ]]; then
                            local line_num=$(echo "$line" | cut -d':' -f1)
                            local comment_text=$(echo "$line" | cut -d':' -f2-)
                            
                            if validate_line_in_diff "$file" "$line_num" "$default_branch"; then
                                inline_comments+=("$file:$line_num:$comment_text")
                                log "SUCCESS" "  ✓ Valid suggestion for line $line_num"
                            else
                                log "WARNING" "  ✗ Rejected invalid line reference: $line_num"
                            fi
                        fi
                    done <<< "$ai_response"
                else
                    log "SUCCESS" "  ✓ No issues found - code quality is good"
                fi
            else
                log "INFO" "  No commentable lines found in $file"
            fi
        fi
    done <<< "$changed_files"

    echo
    log "SUCCESS" "Professional Code Analysis Complete"
    
    if [ ${#inline_comments[@]} -eq 0 ]; then
        log "SUCCESS" "🎉 Excellent code quality! No issues requiring inline comments were found."
        log "INFO" "This indicates strong adherence to security, performance, and maintainability standards."
        return 0
    fi

    log "INFO" "Generated ${#inline_comments[@]} professional inline comments:"
    echo

    # Professional comment preview with categorization
    local security_count=0
    local performance_count=0
    local reliability_count=0
    local quality_count=0
    local standards_count=0

    for comment in "${inline_comments[@]}"; do
        local file_path=$(echo "$comment" | cut -d':' -f1)
        local line_num=$(echo "$comment" | cut -d':' -f2)
        local comment_text=$(echo "$comment" | cut -d':' -f3)
        
        # Count by category
        case "$comment_text" in
            *"🔐"*) ((security_count++)) ;;
            *"⚡"*) ((performance_count++)) ;;
            *"🛡️"*) ((reliability_count++)) ;;
            *"🧹"*) ((quality_count++)) ;;
            *"📋"*) ((standards_count++)) ;;
        esac
        
        echo "📍 $file_path:$line_num"
        echo "   $comment_text"
        echo
    done

    # Professional summary with statistics
    echo "📊 Analysis Summary:"
    [ $security_count -gt 0 ] && echo "  🔐 Security Issues: $security_count"
    [ $performance_count -gt 0 ] && echo "  ⚡ Performance Opportunities: $performance_count"
    [ $reliability_count -gt 0 ] && echo "  🛡️ Reliability Improvements: $reliability_count"
    [ $quality_count -gt 0 ] && echo "  🧹 Code Quality Enhancements: $quality_count"
    [ $standards_count -gt 0 ] && echo "  📋 Standards Compliance: $standards_count"
    echo

    if gum confirm "Post these professional inline comments to PR #$pr_number?"; then
        local repo_info
        repo_info=$(gh repo view --json owner,name --jq '{owner: .owner.login, name: .name}')
        local owner=$(echo "$repo_info" | jq -r '.owner')
        local repo=$(echo "$repo_info" | jq -r '.name')

        log "PROGRESS" "Submitting ${#inline_comments[@]} professional inline comments..."
        
        # Build professional comments array for batch submission
        local comments_array="[]"
        for comment in "${inline_comments[@]}"; do
            local file_path=$(echo "$comment" | cut -d':' -f1)
            local line_num=$(echo "$comment" | cut -d':' -f2)
            local comment_text=$(echo "$comment" | cut -d':' -f3-)
            
            log "INFO" "  Processing: $file_path:$line_num"
            
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
        
        log "PROGRESS" "Submitting comprehensive code review..."
        
        # Professional review summary with metrics
        local review_summary="🔍 **Professional AI Code Review**

## 📊 Analysis Summary
- **Files Analyzed**: $files_processed
- **Total Suggestions**: ${#inline_comments[@]}
- **Security Issues**: $security_count 🔐
- **Performance Opportunities**: $performance_count ⚡
- **Reliability Improvements**: $reliability_count 🛡️
- **Code Quality Enhancements**: $quality_count 🧹
- **Standards Compliance**: $standards_count 📋

## 🎯 Review Methodology
This review employed a comprehensive analysis framework covering:
- Security vulnerability assessment
- Performance optimization opportunities
- Reliability and error handling evaluation
- Code quality and maintainability review
- Best practices and standards compliance

## 💡 Next Steps
Each inline comment provides specific, actionable recommendations with implementation examples. Please review each suggestion and implement the high-priority items before merging.

**Priority Guidelines:**
- 🔐 Security issues should be addressed immediately
- ⚡ Performance issues may impact user experience
- 🛡️ Reliability improvements prevent production issues
- 🧹 Quality enhancements improve long-term maintainability
- 📋 Standards compliance ensures consistency

---

*Generated by Professional AI Code Review System*"
        
        local api_response
        api_response=$(gh api "repos/$owner/$repo/pulls/$pr_number/reviews" \
            --method POST \
            --field body="$review_summary" \
            --field event="COMMENT" \
            --raw-field comments="$comments_array" 2>&1)
        
        if [ $? -eq 0 ]; then
            log "SUCCESS" "Professional code review submitted successfully!"
            echo
            echo "📋 Review Statistics:"
            echo "  • Total Comments: ${#inline_comments[@]}"
            echo "  • Files Analyzed: $files_processed"
            echo "  • Analysis Framework: 5-tier comprehensive review"
            echo
            log "INFO" "View inline comments in the 'Files changed' tab of the PR"
            log "INFO" "Each comment includes specific implementation guidance"
        else
            log "ERROR" "Failed to submit code review"
            echo "Error details:"
            echo "$api_response"
            return 1
        fi
    else
        log "INFO" "Code review submission cancelled by user"
    fi
}

# Professional help and usage information
show_usage() {
    cat << EOF
🚀 Git Relax - Professional Git Workflow Automation

DESCRIPTION:
  A professional tool for automating git workflows with AI assistance.
  Designed for global development teams with emphasis on code quality,
  security, and maintainability.

COMMANDS:
  cm, commit     Generate professional commit messages
  pr, pull       Create comprehensive pull requests  
  rv, review     Perform AI-powered code reviews

USAGE:
  git-relax <command> [options]

EXAMPLES:
  git-relax cm                    # Generate commit message for staged changes
  git-relax pr                    # Create pull request with AI assistance
  git-relax rv                    # Review current PR with comprehensive analysis
  git-relax rv 123               # Review specific PR number with inline comments

FEATURES:
  ✅ Conventional commit message generation
  ✅ Professional PR templates with comprehensive sections
  ✅ Multi-tier security and performance code analysis
  ✅ Inline comments with specific implementation guidance
  ✅ Professional logging and error handling
  ✅ Global compatibility with internationalization support

PREREQUISITES:
  • git - Version control system
  • gum - Interactive CLI components (https://github.com/charmbracelet/gum)
  • gh  - GitHub CLI tool (https://cli.github.com/)
  • mods - AI CLI tool (https://github.com/charmbracelet/mods)

SUPPORT:
  For issues or contributions, please visit the project repository.
  This tool follows professional development standards and best practices.

EOF
}

# Main execution logic with professional error handling
main() {
    local command="$1"
    local arg="$2"
    
    # Initialize professional logging
    log "INFO" "Git Relax Professional v2.0 - Global Development Tool"
    
    # Validate prerequisites before execution
    validate_prerequisites
    
    case "$command" in
        "cm"|"commit")
            log "INFO" "Executing commit message generation workflow"
            generate_commit_message
            ;;
        "pr"|"pull")
            log "INFO" "Executing pull request creation workflow"
            generate_pr_info
            ;;
        "rv"|"review")
            log "INFO" "Executing professional code review workflow"
            generate_code_review "$arg"
            ;;
        "help"|"--help"|"-h")
            show_usage
            ;;
        "")
            log "ERROR" "No command specified"
            show_usage
            exit 1
            ;;
        *)
            log "ERROR" "Unknown command: $command"
            echo
            show_usage
            exit 1
            ;;
    esac
}

# Execute main function with all arguments
main "$@"

pub const COMMIT: &str = r#"Generate a commit message from this diff.
Format: <type>(<scope>): <description>
Types: feat|fix|docs|refactor|test|chore
Rules: lowercase, imperative mood, max 50 chars, no period
Output ONLY the message."#;

pub const PR_TITLE: &str = r#"Generate a PR title from this diff.
Format: <type>(<scope>): <description>
Types: feat|fix|docs|refactor|test|chore
Rules: lowercase, imperative mood, max 50 chars
Output ONLY the title."#;

pub const PR_BODY: &str = r#"Generate a PR description from this diff.
Format:
## Summary
<1-2 sentences>

## Changes
<bullet points>

Be concise. Output ONLY the description."#;

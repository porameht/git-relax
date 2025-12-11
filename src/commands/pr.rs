use anyhow::{anyhow, Result};
use cliclack::{confirm, log, spinner};
use console::style;
use std::process::Command;

use crate::llm::{prompts, LlmClient};

pub async fn run(base: Option<String>) -> Result<()> {
    let base = base.unwrap_or_else(|| "main".into());
    let diff = git(&["diff", &format!("{}..HEAD", base)])?;

    if diff.trim().is_empty() {
        log::warning(format!("No changes compared to {}", base))?;
        return Ok(());
    }

    let sp = spinner();
    sp.start("Generating PR...");

    let llm = LlmClient::new()?;
    let title = llm
        .chat(prompts::PR_TITLE, &diff)
        .await?
        .trim()
        .to_lowercase();
    let body = llm.chat(prompts::PR_BODY, &diff).await?.trim().to_string();

    sp.stop(format!("{}", style("PR generated!").green()));

    println!("\n{} {}\n", style("Title:").cyan().bold(), title);
    println!("{}", style(&body).dim());
    println!();

    if confirm("Create PR?").initial_value(true).interact()? {
        if !has_upstream() {
            let sp = spinner();
            sp.start("Pushing to remote...");
            let status = Command::new("git")
                .args(["push", "-u", "origin", "HEAD"])
                .status()?;
            if !status.success() {
                return Err(anyhow!("git push failed"));
            }
            sp.stop(format!("{}", style("Pushed!").green()));
        }

        let sp = spinner();
        sp.start("Creating PR...");

        let out = Command::new("gh")
            .args([
                "pr", "create", "--title", &title, "--body", &body, "--base", &base,
            ])
            .output()?;

        if !out.status.success() {
            return Err(anyhow!(
                "gh pr create failed: {}",
                String::from_utf8_lossy(&out.stderr)
            ));
        }

        let url = String::from_utf8_lossy(&out.stdout).trim().to_string();
        sp.stop(format!("{}", style("Created!").green()));
        log::success(format!("🔗 {}", url))?;
    }

    Ok(())
}

fn git(args: &[&str]) -> Result<String> {
    let out = Command::new("git").args(args).output()?;
    Ok(String::from_utf8_lossy(&out.stdout).to_string())
}

fn has_upstream() -> bool {
    Command::new("git")
        .args(["rev-parse", "--abbrev-ref", "@{u}"])
        .output()
        .map(|o| o.status.success())
        .unwrap_or(false)
}

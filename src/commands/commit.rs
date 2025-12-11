use anyhow::{anyhow, Result};
use cliclack::{confirm, input, log, spinner};
use console::style;
use std::process::Command;

use crate::llm::{prompts, LlmClient};

pub async fn run() -> Result<()> {
    let diff = git(&["diff", "--cached"])?;
    if diff.trim().is_empty() {
        log::warning("No staged changes. Use 'git add' first.")?;
        return Ok(());
    }

    let sp = spinner();
    sp.start("Generating commit message...");

    let llm = LlmClient::new()?;
    let message = llm.chat(prompts::COMMIT, &diff).await?.trim().to_lowercase();

    sp.stop(format!("{} {}", style("Generated:").green(), message));

    let final_msg: String = input("Edit message")
        .default_input(&message)
        .interact()?;

    if confirm("Commit?").initial_value(true).interact()? {
        let status = Command::new("git")
            .args(["commit", "-m", &final_msg])
            .status()?;

        if status.success() {
            log::success("Committed!")?;
        } else {
            return Err(anyhow!("git commit failed"));
        }
    }

    Ok(())
}

fn git(args: &[&str]) -> Result<String> {
    let out = Command::new("git").args(args).output()?;
    Ok(String::from_utf8_lossy(&out.stdout).to_string())
}

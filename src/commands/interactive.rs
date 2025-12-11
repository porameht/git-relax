use anyhow::Result;
use cliclack::{intro, outro, select};

use super::{commit, pr};

pub async fn run() -> Result<()> {
    intro("🧘 Git Relax")?;

    let action = select("What would you like to do?")
        .item("commit", "📝 Commit", "Generate AI commit message")
        .item("pr", "🔀 Pull Request", "Create PR with AI description")
        .interact()?;

    match action {
        "commit" => commit::run().await?,
        "pr" => pr::run(None).await?,
        _ => {}
    }

    outro("Done!")?;
    Ok(())
}

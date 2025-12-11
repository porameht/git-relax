use anyhow::Result;
use cliclack::{intro, outro, select};

use super::{cm, pr};

pub async fn run() -> Result<()> {
    intro("🧘 Git Relax")?;

    let action = select("What would you like to do?")
        .item("cm", "📝 Commit", "Generate AI commit message")
        .item("pr", "🔀 Pull Request", "Create PR with AI description")
        .interact()?;

    match action {
        "cm" => cm::run().await?,
        "pr" => pr::run(None).await?,
        _ => {}
    }

    outro("Done!")?;
    Ok(())
}

use anyhow::Result;
use clap::{Parser, Subcommand};

mod commands;
mod llm;

#[derive(Parser)]
#[command(name = "git-relax")]
#[command(about = "🧘 AI-powered commit & PR generator")]
#[command(after_help = "Environment:\n  OPENROUTER_API_KEY  OpenRouter API key (recommended)\n  OPENAI_API_KEY      OpenAI API key\n  LLM_MODEL           Model override (optional)")]
struct Cli {
    #[command(subcommand)]
    command: Option<Commands>,
}

#[derive(Subcommand)]
enum Commands {
    /// Generate commit message from staged changes
    #[command(alias = "cm")]
    Commit,

    /// Create PR with AI-generated description
    #[command(alias = "pr")]
    Pull {
        /// Base branch (default: main)
        #[arg(short, long)]
        base: Option<String>,
    },
}

#[tokio::main]
async fn main() -> Result<()> {
    dotenvy::dotenv().ok();

    match Cli::parse().command {
        Some(Commands::Commit) => commands::commit::run().await,
        Some(Commands::Pull { base }) => commands::pr::run(base).await,
        None => commands::interactive::run().await,
    }
}

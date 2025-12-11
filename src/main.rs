use anyhow::Result;
use clap::{Parser, Subcommand};
use std::env;

mod commands;
mod llm;

#[derive(Parser)]
#[command(name = "git-relax")]
#[command(about = "🧘 AI-powered commit & PR generator")]
#[command(
    after_help = "Environment:\n  OPENROUTER_API_KEY  OpenRouter API key (recommended)\n  OPENAI_API_KEY      OpenAI API key\n  LLM_MODEL           Model override (optional)"
)]
struct Cli {
    #[command(subcommand)]
    command: Option<Commands>,
}

#[derive(Parser)]
#[command(name = "grlcm")]
#[command(about = "🧘 AI-powered commit message generator")]
struct GrlcmCli;

#[derive(Parser)]
#[command(name = "grlpr")]
#[command(about = "🧘 AI-powered PR description generator")]
struct GrlprCli {
    /// Base branch (default: main)
    #[arg(short, long)]
    base: Option<String>,
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

fn get_binary_name() -> String {
    env::args()
        .next()
        .and_then(|p| p.rsplit('/').next().map(String::from))
        .unwrap_or_default()
}

#[tokio::main]
async fn main() -> Result<()> {
    dotenvy::dotenv().ok();

    let bin_name = get_binary_name();

    match bin_name.as_str() {
        "grlcm" => {
            GrlcmCli::parse();
            commands::cm::run().await
        }
        "grlpr" => {
            let cli = GrlprCli::parse();
            commands::pr::run(cli.base).await
        }
        _ => match Cli::parse().command {
            Some(Commands::Commit) => commands::cm::run().await,
            Some(Commands::Pull { base }) => commands::pr::run(base).await,
            None => commands::interactive::run().await,
        },
    }
}

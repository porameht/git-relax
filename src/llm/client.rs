use anyhow::{anyhow, Result};
use reqwest::Client;
use serde::{Deserialize, Serialize};
use std::env;

pub struct LlmClient {
    client: Client,
    api_key: String,
    model: String,
    base_url: String,
}

#[derive(Serialize)]
struct ChatRequest {
    model: String,
    messages: Vec<Message>,
}

#[derive(Serialize)]
struct Message {
    role: &'static str,
    content: String,
}

#[derive(Deserialize)]
struct ChatResponse {
    choices: Vec<Choice>,
}

#[derive(Deserialize)]
struct Choice {
    message: MessageContent,
}

#[derive(Deserialize)]
struct MessageContent {
    content: String,
}

impl LlmClient {
    pub fn new() -> Result<Self> {
        // OpenRouter (default) or OpenAI-compatible
        let (api_key, model, base_url) = if let Ok(key) = env::var("OPENROUTER_API_KEY") {
            (
                key,
                env::var("LLM_MODEL").unwrap_or_else(|_| "google/gemini-2.0-flash-001".into()),
                "https://openrouter.ai/api/v1/chat/completions".into(),
            )
        } else if let Ok(key) = env::var("OPENAI_API_KEY") {
            (
                key,
                env::var("LLM_MODEL").unwrap_or_else(|_| "gpt-4o-mini".into()),
                "https://api.openai.com/v1/chat/completions".into(),
            )
        } else {
            return Err(anyhow!("Set OPENROUTER_API_KEY or OPENAI_API_KEY"));
        };

        Ok(Self { client: Client::new(), api_key, model, base_url })
    }

    pub async fn chat(&self, system: &str, user: &str) -> Result<String> {
        let resp = self.client
            .post(&self.base_url)
            .header("Authorization", format!("Bearer {}", self.api_key))
            .json(&ChatRequest {
                model: self.model.clone(),
                messages: vec![
                    Message { role: "system", content: system.into() },
                    Message { role: "user", content: user.into() },
                ],
            })
            .send()
            .await?;

        if !resp.status().is_success() {
            return Err(anyhow!("API error: {}", resp.text().await?));
        }

        let result: ChatResponse = resp.json().await?;
        result.choices.first()
            .map(|c| c.message.content.clone())
            .ok_or_else(|| anyhow!("No response"))
    }
}

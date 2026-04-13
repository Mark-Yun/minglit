import { LLMAdapter } from "../llm_adapter.ts";

interface OpenAIChatResponse {
  choices: Array<{
    message: {
      content: string | null;
    };
  }>;
}

export class OpenAILLM implements LLMAdapter {
  readonly model = "gpt-4o-mini";
  readonly provider = "openai";

  private readonly baseUrl = "https://api.openai.com/v1/chat/completions";

  constructor(private readonly apiKey: string) {}

  async complete(
    prompt: string,
    options?: { maxTokens?: number; temperature?: number },
  ): Promise<string> {
    const response = await fetch(this.baseUrl, {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${this.apiKey}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        model: this.model,
        messages: [{ role: "user", content: prompt }],
        max_tokens: options?.maxTokens ?? 256,
        temperature: options?.temperature ?? 0.7,
      }),
    });

    if (!response.ok) {
      throw new Error(`OpenAI API Error: ${response.status} ${response.statusText}`);
    }

    const json: OpenAIChatResponse = await response.json();
    const content = json.choices[0]?.message?.content;
    if (content == null) {
      throw new Error("OpenAI returned empty content");
    }
    return content;
  }
}

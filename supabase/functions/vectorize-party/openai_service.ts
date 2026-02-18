export class OpenAIService {
  private baseUrl = "https://api.openai.com/v1/embeddings";

  constructor(private apiKey: string) {}

  async generateEmbedding(text: string): Promise<number[]> {
    const response = await fetch(this.baseUrl, {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${this.apiKey}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        model: "text-embedding-3-small",
        input: text,
      }),
    });

    if (!response.ok) {
      throw new Error(`OpenAI API Error: ${response.status} ${response.statusText}`);
    }

    const json = await response.json();
    return json.data[0].embedding;
  }
}
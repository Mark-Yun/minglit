export class OpenAIService {
  private baseUrl = "https://api.openai.com/v1/embeddings";

  constructor(private apiKey: string) {}

  async generateEmbeddings(texts: string[]): Promise<number[][]> {
    if (texts.length === 0) return [];

    const response = await fetch(this.baseUrl, {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${this.apiKey}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        model: "text-embedding-3-small",
        input: texts, // OpenAI supports array input for batching
      }),
    });

    if (!response.ok) {
      throw new Error(`OpenAI API Error: ${response.status} ${response.statusText}`);
    }

    const json = await response.json();
    // deno-lint-ignore no-explicit-any
    return json.data.map((item: any) => item.embedding);
  }
}
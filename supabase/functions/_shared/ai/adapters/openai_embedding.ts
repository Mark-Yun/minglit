import { EmbeddingAdapter } from "../embedding_adapter.ts";

interface OpenAIEmbeddingResponse {
  data: Array<{ embedding: number[] }>;
}

const REQUEST_TIMEOUT_MS = 30_000;

export class OpenAIEmbedding implements EmbeddingAdapter {
  readonly dimension = 1536;
  readonly model = "text-embedding-3-small";
  readonly provider = "openai";

  private readonly baseUrl = "https://api.openai.com/v1/embeddings";

  constructor(private readonly apiKey: string) {}

  async generateEmbeddings(texts: string[]): Promise<number[][]> {
    if (texts.length === 0) return [];

    const controller = new AbortController();
    const timeoutId = setTimeout(() => controller.abort(), REQUEST_TIMEOUT_MS);

    const response = await fetch(this.baseUrl, {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${this.apiKey}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        model: this.model,
        input: texts,
      }),
      signal: controller.signal,
    }).finally(() => clearTimeout(timeoutId));

    if (!response.ok) {
      throw new Error(`OpenAI API Error: ${response.status} ${response.statusText}`);
    }

    const json: OpenAIEmbeddingResponse = await response.json();
    return json.data.map((item) => item.embedding);
  }
}

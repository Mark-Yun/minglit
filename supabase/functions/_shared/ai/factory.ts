import { EmbeddingAdapter } from "./embedding_adapter.ts";
import { LLMAdapter } from "./llm_adapter.ts";
import { OpenAIEmbedding } from "./adapters/openai_embedding.ts";
import { OpenAILLM } from "./adapters/openai_llm.ts";

export function createEmbeddingAdapter(): EmbeddingAdapter {
  const provider = Deno.env.get("EMBEDDING_PROVIDER") ?? "openai";
  switch (provider) {
    case "openai":
      return new OpenAIEmbedding(Deno.env.get("OPENAI_API_KEY")!);
    default:
      throw new Error(`Unknown embedding provider: ${provider}`);
  }
}

export function createLLMAdapter(): LLMAdapter {
  const provider = Deno.env.get("LLM_PROVIDER") ?? "openai";
  switch (provider) {
    case "openai":
      return new OpenAILLM(Deno.env.get("OPENAI_API_KEY")!);
    default:
      throw new Error(`Unknown LLM provider: ${provider}`);
  }
}

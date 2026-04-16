import { EmbeddingAdapter } from "./embedding_adapter.ts";
import { LLMAdapter } from "./llm_adapter.ts";
import { OpenAIEmbedding } from "./adapters/openai_embedding.ts";
import { OpenAILLM } from "./adapters/openai_llm.ts";

export function createEmbeddingAdapter(): EmbeddingAdapter {
  const provider = Deno.env.get("EMBEDDING_PROVIDER") ?? "openai";
  switch (provider) {
    case "openai": {
      const apiKey = Deno.env.get("OPENAI_API_KEY");
      // Fix #1493: 환경변수명 노출 방지 — 제네릭 메시지로 교체
      if (!apiKey) throw new Error("AI provider configuration missing");
      return new OpenAIEmbedding(apiKey);
    }
    default:
      throw new Error(`Unknown embedding provider: ${provider}`);
  }
}

export function createLLMAdapter(): LLMAdapter {
  const provider = Deno.env.get("LLM_PROVIDER") ?? "openai";
  switch (provider) {
    case "openai": {
      const apiKey = Deno.env.get("OPENAI_API_KEY");
      // Fix #1493: 환경변수명 노출 방지 — 제네릭 메시지로 교체
      if (!apiKey) throw new Error("AI provider configuration missing");
      return new OpenAILLM(apiKey);
    }
    default:
      throw new Error(`Unknown LLM provider: ${provider}`);
  }
}

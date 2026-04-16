import { assertInstanceOf, assertThrows } from "@std/assert";
import { withEnv } from "../../_test_utils/mock_http.ts";
import { createEmbeddingAdapter, createLLMAdapter } from "./factory.ts";
import { OpenAIEmbedding } from "./adapters/openai_embedding.ts";
import { OpenAILLM } from "./adapters/openai_llm.ts";

Deno.test("createEmbeddingAdapter - default provider returns OpenAIEmbedding", async () => {
  await withEnv({ EMBEDDING_PROVIDER: undefined, OPENAI_API_KEY: "test-key" }, () => {
    const adapter = createEmbeddingAdapter();
    assertInstanceOf(adapter, OpenAIEmbedding);
  });
});

Deno.test("createLLMAdapter - default provider returns OpenAILLM", async () => {
  await withEnv({ LLM_PROVIDER: undefined, OPENAI_API_KEY: "test-key" }, () => {
    const adapter = createLLMAdapter();
    assertInstanceOf(adapter, OpenAILLM);
  });
});

Deno.test("createEmbeddingAdapter - unknown provider throws", async () => {
  await withEnv({ EMBEDDING_PROVIDER: "unknown", OPENAI_API_KEY: "test-key" }, () => {
    assertThrows(
      () => createEmbeddingAdapter(),
      Error,
      "Unknown embedding provider: unknown",
    );
  });
});

Deno.test("createLLMAdapter - unknown provider throws", async () => {
  await withEnv({ LLM_PROVIDER: "unknown", OPENAI_API_KEY: "test-key" }, () => {
    assertThrows(
      () => createLLMAdapter(),
      Error,
      "Unknown LLM provider: unknown",
    );
  });
});

Deno.test("createEmbeddingAdapter - missing OPENAI_API_KEY throws", async () => {
  await withEnv({ EMBEDDING_PROVIDER: undefined, OPENAI_API_KEY: undefined }, () => {
    assertThrows(
      () => createEmbeddingAdapter(),
      Error,
      // Fix #1493: 에러 메시지에서 환경변수명 노출 제거 — 일반적인 설정 오류 문구로 변경
      "AI provider configuration missing",
    );
  });
});

Deno.test("createLLMAdapter - missing OPENAI_API_KEY throws", async () => {
  await withEnv({ LLM_PROVIDER: undefined, OPENAI_API_KEY: undefined }, () => {
    assertThrows(
      () => createLLMAdapter(),
      Error,
      // Fix #1493: 에러 메시지에서 환경변수명 노출 제거 — 일반적인 설정 오류 문구로 변경
      "AI provider configuration missing",
    );
  });
});

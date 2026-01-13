import { assertEquals, assertRejects } from "https://deno.land/std@0.224.0/assert/mod.ts";
import { OpenAIService } from "./openai_service.ts";

Deno.test("OpenAIService - generateEmbedding returns vector on success", async () => {
  const mockFetch = (_input: RequestInfo | URL, _init?: RequestInit) => {
    return Promise.resolve(new Response(JSON.stringify({
      data: [{ embedding: [0.1, 0.2, 0.3] }]
    })));
  };

  // Mock global fetch
  const originalFetch = globalThis.fetch;
  globalThis.fetch = mockFetch;

  try {
    const service = new OpenAIService("fake-api-key");
    const vector = await service.generateEmbedding("Test Party Title");
    assertEquals(vector, [0.1, 0.2, 0.3]);
  } finally {
    globalThis.fetch = originalFetch;
  }
});

Deno.test("OpenAIService - throws error on API failure", async () => {
  const mockFetch = () => Promise.resolve(new Response("Internal Server Error", { status: 500, statusText: "Internal Server Error" }));
  
  const originalFetch = globalThis.fetch;
  globalThis.fetch = mockFetch;

  try {
    const service = new OpenAIService("fake-api-key");
    await assertRejects(
      () => service.generateEmbedding("Fail"),
      Error,
      "OpenAI API Error: 500 Internal Server Error"
    );
  } finally {
    globalThis.fetch = originalFetch;
  }
});

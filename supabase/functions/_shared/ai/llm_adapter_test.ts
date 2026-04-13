import { assertEquals, assertRejects } from "@std/assert";
import { createFetchMock, withMockedFetch } from "../../_test_utils/mock_http.ts";
import { OpenAILLM } from "./adapters/openai_llm.ts";
import type { LLMAdapter } from "./llm_adapter.ts";

function makeChatResponse(content: string): string {
  return JSON.stringify({
    choices: [{ message: { content } }],
  });
}

Deno.test("OpenAILLM - satisfies LLMAdapter interface", () => {
  const adapter: LLMAdapter = new OpenAILLM("test-api-key");
  assertEquals(adapter.model, "gpt-4o-mini");
  assertEquals(adapter.provider, "openai");
});

Deno.test("OpenAILLM - returns completion from API response", async () => {
  const adapter = new OpenAILLM("test-api-key");

  const { fetchMock } = createFetchMock([
    {
      matcher: "api.openai.com/v1/chat/completions",
      handler: () =>
        new Response(makeChatResponse("Hello from AI!"), {
          status: 200,
          headers: { "Content-Type": "application/json" },
        }),
    },
  ]);

  const result = await withMockedFetch(fetchMock, () =>
    adapter.complete("Say hello")
  );

  assertEquals(result, "Hello from AI!");
});

Deno.test("OpenAILLM - sends maxTokens and temperature from options", async () => {
  const adapter = new OpenAILLM("test-api-key");
  let capturedBody: Record<string, unknown> | null = null;

  const { fetchMock } = createFetchMock([
    {
      matcher: "api.openai.com/v1/chat/completions",
      handler: async (req) => {
        capturedBody = await req.json() as Record<string, unknown>;
        return new Response(makeChatResponse("ok"), {
          status: 200,
          headers: { "Content-Type": "application/json" },
        });
      },
    },
  ]);

  await withMockedFetch(
    fetchMock,
    () => adapter.complete("prompt", { maxTokens: 512, temperature: 0.2 }),
  );

  assertEquals(capturedBody?.["max_tokens"], 512);
  assertEquals(capturedBody?.["temperature"], 0.2);
});

Deno.test("OpenAILLM - uses default maxTokens and temperature when options omitted", async () => {
  const adapter = new OpenAILLM("test-api-key");
  let capturedBody: Record<string, unknown> | null = null;

  const { fetchMock } = createFetchMock([
    {
      matcher: "api.openai.com/v1/chat/completions",
      handler: async (req) => {
        capturedBody = await req.json() as Record<string, unknown>;
        return new Response(makeChatResponse("ok"), {
          status: 200,
          headers: { "Content-Type": "application/json" },
        });
      },
    },
  ]);

  await withMockedFetch(fetchMock, () => adapter.complete("prompt"));

  assertEquals(capturedBody?.["max_tokens"], 256);
  assertEquals(capturedBody?.["temperature"], 0.7);
});

Deno.test("OpenAILLM - throws on API error", async () => {
  const adapter = new OpenAILLM("test-api-key");

  const { fetchMock } = createFetchMock([
    {
      matcher: "api.openai.com/v1/chat/completions",
      handler: () =>
        new Response("Service Unavailable", {
          status: 503,
          statusText: "Service Unavailable",
        }),
    },
  ]);

  await assertRejects(
    () => withMockedFetch(fetchMock, () => adapter.complete("hello")),
    Error,
    "OpenAI API Error: 503 Service Unavailable",
  );
});

Deno.test("OpenAILLM - sends correct Authorization header", async () => {
  const adapter = new OpenAILLM("my-llm-key");
  let capturedAuth: string | null = null;

  const { fetchMock } = createFetchMock([
    {
      matcher: "api.openai.com/v1/chat/completions",
      handler: (req) => {
        capturedAuth = req.headers.get("Authorization");
        return new Response(makeChatResponse("ok"), {
          status: 200,
          headers: { "Content-Type": "application/json" },
        });
      },
    },
  ]);

  await withMockedFetch(fetchMock, () => adapter.complete("test"));
  assertEquals(capturedAuth, "Bearer my-llm-key");
});

Deno.test("OpenAILLM - sends user message without system message", async () => {
  const adapter = new OpenAILLM("test-api-key");
  let capturedBody: Record<string, unknown> | null = null;

  const { fetchMock } = createFetchMock([
    {
      matcher: "api.openai.com/v1/chat/completions",
      handler: async (req) => {
        capturedBody = await req.json() as Record<string, unknown>;
        return new Response(makeChatResponse("ok"), {
          status: 200,
          headers: { "Content-Type": "application/json" },
        });
      },
    },
  ]);

  await withMockedFetch(fetchMock, () => adapter.complete("my prompt"));

  const messages = (capturedBody?.["messages"] as unknown) as Array<{ role: string; content: string }>;
  assertEquals(messages.length, 1);
  assertEquals(messages[0].role, "user");
  assertEquals(messages[0].content, "my prompt");
});

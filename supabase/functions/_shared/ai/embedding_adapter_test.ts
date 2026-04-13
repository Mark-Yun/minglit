import { assertEquals, assertRejects } from "@std/assert";
import { createFetchMock, withMockedFetch } from "../../_test_utils/mock_http.ts";
import { OpenAIEmbedding } from "./adapters/openai_embedding.ts";
import type { EmbeddingAdapter } from "./embedding_adapter.ts";

function makeEmbedding(value: number, size = 1536): number[] {
  return new Array(size).fill(value);
}

Deno.test("OpenAIEmbedding - satisfies EmbeddingAdapter interface", () => {
  const adapter: EmbeddingAdapter = new OpenAIEmbedding("test-api-key");
  assertEquals(adapter.dimension, 1536);
  assertEquals(adapter.model, "text-embedding-3-small");
  assertEquals(adapter.provider, "openai");
});

Deno.test("OpenAIEmbedding - returns embeddings for text array", async () => {
  const adapter = new OpenAIEmbedding("test-api-key");
  const expected = [makeEmbedding(0.1), makeEmbedding(0.2)];

  const { fetchMock } = createFetchMock([
    {
      matcher: "api.openai.com/v1/embeddings",
      handler: () =>
        new Response(
          JSON.stringify({
            data: expected.map((embedding) => ({ embedding })),
          }),
          { status: 200, headers: { "Content-Type": "application/json" } },
        ),
    },
  ]);

  const result = await withMockedFetch(fetchMock, () =>
    adapter.generateEmbeddings(["hello", "world"])
  );

  assertEquals(result, expected);
});

Deno.test("OpenAIEmbedding - returns empty array for empty input", async () => {
  const adapter = new OpenAIEmbedding("test-api-key");

  // Empty input short-circuits before fetch; mock ensures no accidental network call
  const { fetchMock } = createFetchMock([]);
  const result = await withMockedFetch(fetchMock, () =>
    adapter.generateEmbeddings([])
  );
  assertEquals(result, []);
});

Deno.test("OpenAIEmbedding - throws on API error", async () => {
  const adapter = new OpenAIEmbedding("test-api-key");

  const { fetchMock } = createFetchMock([
    {
      matcher: "api.openai.com/v1/embeddings",
      handler: () =>
        new Response("Unauthorized", { status: 401, statusText: "Unauthorized" }),
    },
  ]);

  await assertRejects(
    () => withMockedFetch(fetchMock, () => adapter.generateEmbeddings(["hello"])),
    Error,
    "OpenAI API Error: 401 Unauthorized",
  );
});

Deno.test("OpenAIEmbedding - sends correct Authorization header", async () => {
  const adapter = new OpenAIEmbedding("my-secret-key");
  let capturedAuth: string | null = null;

  const { fetchMock } = createFetchMock([
    {
      matcher: "api.openai.com/v1/embeddings",
      handler: (req) => {
        capturedAuth = req.headers.get("Authorization");
        return new Response(
          JSON.stringify({ data: [{ embedding: makeEmbedding(0.5) }] }),
          { status: 200, headers: { "Content-Type": "application/json" } },
        );
      },
    },
  ]);

  await withMockedFetch(fetchMock, () => adapter.generateEmbeddings(["test"]));
  assertEquals(capturedAuth, "Bearer my-secret-key");
});

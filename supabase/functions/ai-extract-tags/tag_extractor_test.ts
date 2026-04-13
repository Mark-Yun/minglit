import { assertEquals, assertNotEquals } from "@std/assert";
import {
  buildTagExtractionPrompt,
  extractDescriptionText,
  parseTagResponse,
} from "./tag_extractor.ts";

Deno.test("buildTagExtractionPrompt - includes title and description", () => {
  const prompt = buildTagExtractionPrompt("네트워킹 파티", "직장인 대상 강남 모임");
  assertEquals(prompt.includes("네트워킹 파티"), true);
  assertEquals(prompt.includes("직장인 대상 강남 모임"), true);
  assertEquals(prompt.includes('["네트워킹", "직장인", "강남"]'), true);
});

Deno.test("parseTagResponse - parses valid JSON array", () => {
  const tags = parseTagResponse('["네트워킹", "직장인", "강남"]');
  assertEquals(tags, ["네트워킹", "직장인", "강남"]);
});

Deno.test("parseTagResponse - extracts JSON array from surrounding text", () => {
  const tags = parseTagResponse(
    '물론이죠! 여기 태그입니다:\n["네트워킹", "파티"] 이상입니다.',
  );
  assertEquals(tags, ["네트워킹", "파티"]);
});

Deno.test("parseTagResponse - returns null for non-JSON response (parse failure)", () => {
  const tags = parseTagResponse("태그를 추출할 수 없습니다.");
  assertEquals(tags, null);
});

Deno.test("parseTagResponse - filters tags longer than 20 chars", () => {
  const tags = parseTagResponse(
    '["정상태그", "이것은너무긴태그입니다이십자초과합니다확실히"]',
  );
  assertEquals(tags, ["정상태그"]);
});

Deno.test("parseTagResponse - filters empty strings", () => {
  const tags = parseTagResponse('["태그", "", "  "]');
  assertEquals(tags, ["태그"]);
});

Deno.test("parseTagResponse - returns null for non-array JSON", () => {
  const tags = parseTagResponse('{"key": "value"}');
  assertEquals(tags, null);
});

Deno.test("parseTagResponse - returns empty array for empty JSON array", () => {
  const tags = parseTagResponse("[]");
  assertEquals(tags, []);
  assertNotEquals(tags, null);
});

Deno.test("extractDescriptionText - plain string", () => {
  const text = extractDescriptionText("직장인 대상 강남 모임");
  assertEquals(text, "직장인 대상 강남 모임");
});

Deno.test("extractDescriptionText - Quill Delta ops normalizes whitespace", () => {
  const delta = {
    ops: [
      { insert: "직장인 대상 " },
      { insert: "강남 모임" },
    ],
  };
  const text = extractDescriptionText(delta);
  // join(" ") 후 trim() 결과를 whitespace 정규화하여 비교
  assertEquals(text.replace(/\s+/g, " ").trim(), "직장인 대상 강남 모임");
});

Deno.test("extractDescriptionText - Quill Delta ops filters embed (non-string inserts)", () => {
  const delta = {
    ops: [
      { insert: "텍스트 앞" },
      { insert: { image: "https://example.com/img.png" } }, // embed — 제외
      { insert: " 텍스트 뒤" },
    ],
  };
  const text = extractDescriptionText(delta);
  assertEquals(text.replace(/\s+/g, " ").trim(), "텍스트 앞 텍스트 뒤");
});

Deno.test("extractDescriptionText - null/undefined returns empty string", () => {
  assertEquals(extractDescriptionText(null), "");
  assertEquals(extractDescriptionText(undefined), "");
});

Deno.test("extractDescriptionText - unknown object is JSON-stringified", () => {
  const text = extractDescriptionText({ custom: "format" });
  assertEquals(text, '{"custom":"format"}');
});

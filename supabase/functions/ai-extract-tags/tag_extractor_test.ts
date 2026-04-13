import { assertEquals } from "@std/assert";
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

Deno.test("parseTagResponse - returns empty array for non-JSON response", () => {
  const tags = parseTagResponse("태그를 추출할 수 없습니다.");
  assertEquals(tags, []);
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

Deno.test("parseTagResponse - returns empty array for non-array JSON", () => {
  const tags = parseTagResponse('{"key": "value"}');
  assertEquals(tags, []);
});

Deno.test("extractDescriptionText - plain string", () => {
  const text = extractDescriptionText("직장인 대상 강남 모임");
  assertEquals(text, "직장인 대상 강남 모임");
});

Deno.test("extractDescriptionText - Quill Delta ops", () => {
  const delta = {
    ops: [
      { insert: "직장인 대상 " },
      { insert: "강남 모임" },
    ],
  };
  const text = extractDescriptionText(delta);
  assertEquals(text, "직장인 대상  강남 모임");
});

Deno.test("extractDescriptionText - null/undefined returns empty string", () => {
  assertEquals(extractDescriptionText(null), "");
  assertEquals(extractDescriptionText(undefined), "");
});

Deno.test("extractDescriptionText - unknown object is JSON-stringified", () => {
  const text = extractDescriptionText({ custom: "format" });
  assertEquals(text, '{"custom":"format"}');
});

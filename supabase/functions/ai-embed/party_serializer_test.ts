import { assertEquals, assertStringIncludes } from "@std/assert";
import { serializeParty } from "./party_serializer.ts";

// Fix #1493: serializeParty PII 스크러빙 검증 — location.address 제외, name만 포함

Deno.test("serializeParty - location.address excluded (PII scrubbing)", () => {
  const party = {
    title: "강남 소셜 파티",
    location: {
      name: "서울 강남구",
      address: "서울특별시 강남구 테헤란로 123",
    },
  };
  const result = serializeParty(party);

  assertStringIncludes(result, "Location: 서울 강남구");
  assertEquals(result.includes("테헤란로"), false, "location.address가 포함되어서는 안 됨");
  assertEquals(result.includes("123"), false, "상세 주소 번지가 포함되어서는 안 됨");
});

Deno.test("serializeParty - title and tags included", () => {
  const party = {
    title: "테스트 파티",
    tags: ["소셜", "20대"],
    location: { name: "서울 마포구", address: "서울 마포구 어딘가 99" },
  };
  const result = serializeParty(party);

  assertStringIncludes(result, "Title: 테스트 파티");
  assertStringIncludes(result, "Tags: 소셜, 20대");
  assertStringIncludes(result, "Location: 서울 마포구");
  assertEquals(result.includes("어딘가"), false, "상세 주소는 제외");
});

Deno.test("serializeParty - empty location name omitted", () => {
  const party = {
    title: "주소 없는 파티",
    location: { name: "", address: "서울특별시 어딘가" },
  };
  const result = serializeParty(party);

  assertEquals(result.includes("Location:"), false, "name이 빈 경우 Location 라인 없어야 함");
});

Deno.test("serializeParty - string location treated as city name", () => {
  const party = {
    title: "레거시 파티",
    location: "부산 해운대구",
  };
  const result = serializeParty(party);

  assertStringIncludes(result, "Location: 부산 해운대구");
});

Deno.test("serializeParty - no location field", () => {
  const party = { title: "위치 없는 파티" };
  const result = serializeParty(party);

  assertStringIncludes(result, "Title: 위치 없는 파티");
  assertEquals(result.includes("Location:"), false);
});

/**
 * Tag extraction helpers: prompt building and response parsing.
 * Separated for unit-testability.
 */

export function buildTagExtractionPrompt(
  title: string,
  description: string,
): string {
  return `다음 이벤트에서 관련 태그를 최대 5개 추출해줘.
태그는 한글로, 2~4글자의 짧은 단어로 만들어줘.
기존 인기 태그: 소개팅, 미팅, 네트워킹, 운동, 러닝, 등산, 맛집, 와인, 커피, 파티, 클럽, 루프탑, 스터디, 독서, 영화, 음악, 공연, 전시, 여행, 캠핑, 야외, 소규모, 대규모, 20대, 30대
가능하면 기존 태그를 재사용하되, 적절한 게 없으면 새 태그를 만들어도 돼.

제목: ${title}
설명: ${description}

응답은 반드시 JSON 배열 형식으로만 해줘. 예: ["네트워킹", "직장인", "강남"]`;
}

/**
 * Parse a JSON array of tag strings from an LLM response.
 *
 * Returns null when no valid JSON array is found (parse failure),
 * so callers can distinguish "no tags" (empty array) from "bad response"
 * and handle accordingly.
 */
export function parseTagResponse(response: string): string[] | null {
  const match = response.match(/\[[\s\S]*?\]/);
  if (!match) return null;

  try {
    const parsed = JSON.parse(match[0]);
    if (!Array.isArray(parsed)) return null;
    return parsed
      .filter((item: unknown): item is string => typeof item === "string")
      .map((tag: string) => tag.trim())
      .filter((tag: string) => tag.length > 0 && tag.length <= 20);
  } catch {
    return null;
  }
}

/**
 * Extracts plain text from a Quill Delta ops structure or returns the
 * description as-is if it is already a plain string.
 */
export function extractDescriptionText(
  description: unknown,
): string {
  if (!description) return "";
  if (typeof description === "string") return description;

  const delta = description as { ops?: Array<{ insert?: unknown }> };
  if (delta.ops && Array.isArray(delta.ops)) {
    return delta.ops
      // Fix: embed ops (non-string inserts like images/videos) を除外
      .filter((op) => typeof op.insert === "string")
      .map((op) => op.insert as string)
      .join(" ")
      .trim();
  }

  return JSON.stringify(description);
}

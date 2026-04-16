// deno-lint-ignore-file no-explicit-any
export function serializeParty(party: any): string {
  const parts: string[] = [];

  if (party.title) parts.push(`Title: ${party.title}`);
  
  if (party.description) {
    let descText = "";
    if (party.description.ops && Array.isArray(party.description.ops)) {
      descText = party.description.ops.map((op: any) => op.insert || "").join(" ");
    } else if (typeof party.description === 'string') {
        descText = party.description;
    } else {
        descText = JSON.stringify(party.description);
    }
    parts.push(`Description: ${descText}`);
  }

  if (party.tags && Array.isArray(party.tags)) {
    parts.push(`Tags: ${party.tags.join(", ")}`);
  }

  if (party.location) {
      if (typeof party.location === 'object') {
          // Fix #1493: location.address PII 스크러빙 — 상세 주소 제외, 이름(시/구 수준)만 포함
          const locationName = (party.location.name || '').trim();
          if (locationName) {
              parts.push(`Location: ${locationName}`);
          }
      } else if (typeof party.location === 'string') {
          // Fix #1493: 문자열 위치는 이미 시/구 수준의 이름만 저장된다고 가정
          // (상세 주소 없음 — Supabase JSONB 객체가 아닌 레거시 데이터 경우)
          const locationStr = party.location.trim();
          if (locationStr) {
              parts.push(`Location: ${locationStr}`);
          }
      }
  }

  return parts.join("\n");
}
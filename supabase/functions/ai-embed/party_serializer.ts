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
          parts.push(`Location: ${party.location.name || ''}`.trim());
      } else {
          parts.push(`Location: ${party.location}`);
      }
  }

  return parts.join("\n");
}
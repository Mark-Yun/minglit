export function serializeParty(party: any): string {
  const parts: string[] = [];

  if (party.title) parts.push(`Title: ${party.title}`);
  
  if (party.description) {
    let descText = "";
    // Handle Quill Delta (ops)
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
          parts.push(`Location: ${party.location.name || ''} ${party.location.address || ''}`.trim());
      } else {
          parts.push(`Location: ${party.location}`);
      }
  }

  return parts.join("\n");
}
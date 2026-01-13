import { assertEquals } from "https://deno.land/std@0.224.0/assert/mod.ts";
import { serializeParty } from "./party_serializer.ts";

Deno.test("serializeParty - converts party object to text string", () => {
  const party = {
    title: "Awesome Party",
    description: { ops: [{ insert: "Fun time!" }] }, // Quill Delta format
    tags: ["social", "drink"],
    location: { name: "Gangnam", address: "Seoul" },
  };

  const text = serializeParty(party);
  
  // Expect a string that contains key information
  assertEquals(text.includes("Awesome Party"), true);
  assertEquals(text.includes("Fun time!"), true);
  assertEquals(text.includes("social"), true);
  assertEquals(text.includes("Gangnam"), true);
});

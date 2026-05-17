// _shared/domains/event/participant_test.ts
// pure unit tests — mock 0, IO 0

import { assertEquals } from "jsr:@std/assert@1";
import { isCheckedIn } from "./participant.ts";

Deno.test("isCheckedIn — checked_in 만 true, 나머지 → false", () => {
  assertEquals(isCheckedIn("checked_in"), true);
  for (const s of ["ticket_issued", "no_show", "", "checked_out", "pending"]) {
    assertEquals(isCheckedIn(s), false, `${s} must NOT be checked_in`);
  }
});

// _shared/_testing/fake_supabase_test.ts — sanity tests for the fake itself

import { assertEquals, assertRejects } from "jsr:@std/assert@1";
import { fakeSupabase } from "./fake_supabase.ts";

Deno.test("fakeSupabase :: select.eq.single → scripted row", async () => {
  const sb = fakeSupabase().on("events", "select", {
    data: { id: "ev-1", status: "scheduled" },
  });
  const { data, error } = await sb.from("events").select("id, status").eq("id", "ev-1").single();
  assertEquals(error, null);
  assertEquals(data, { id: "ev-1", status: "scheduled" });
});

Deno.test("fakeSupabase :: maybeSingle on array → first element", async () => {
  const sb = fakeSupabase().on("tickets", "select", {
    data: [{ id: "tk-1" }, { id: "tk-2" }],
  });
  const { data } = await sb.from("tickets").select("id").eq("event_id", "ev-1").maybeSingle();
  assertEquals(data, { id: "tk-1" });
});

Deno.test("fakeSupabase :: insert → captures payload", async () => {
  const sb = fakeSupabase().on("event_applications", "insert", {
    data: { id: "app-1" },
  });
  await sb.from("event_applications").insert({ event_id: "ev-1", user_id: "u-1" });
  const calls = sb.callsFor("event_applications", "insert");
  assertEquals(calls.length, 1);
  assertEquals(calls[0].payload, { event_id: "ev-1", user_id: "u-1" });
});

Deno.test("fakeSupabase :: update.eq → captures patch + filter", async () => {
  const sb = fakeSupabase().on("event_applications", "update", { error: null });
  await sb.from("event_applications").update({ status: "cancelled" }).eq("id", "app-1");
  const [call] = sb.callsFor("event_applications", "update");
  assertEquals(call.payload, { status: "cancelled" });
  assertEquals(call.filters, [{ kind: "eq", col: "id", val: "app-1" }]);
});

Deno.test("fakeSupabase :: delete.eq → captured", async () => {
  const sb = fakeSupabase().on("event_applications", "delete", { error: null });
  await sb.from("event_applications").delete().eq("id", "app-1");
  assertEquals(sb.callsFor("event_applications", "delete").length, 1);
});

Deno.test("fakeSupabase :: rpc with args", async () => {
  const sb = fakeSupabase().on("get_current_policy", "rpc", {
    data: { grace_period_hours: 2, cutoff_days: 7 },
  });
  const { data } = await sb.rpc("get_current_policy", { p_key: "refund" });
  assertEquals(data, { grace_period_hours: 2, cutoff_days: 7 });
});

Deno.test("fakeSupabase :: error path → returned as { error }", async () => {
  const sb = fakeSupabase().on("events", "select", {
    error: { message: "not found", code: "PGRST116" },
  });
  const { data, error } = await sb.from("events").select("*").eq("id", "x").single();
  assertEquals(data, null);
  assertEquals(error?.code, "PGRST116");
});

Deno.test("fakeSupabase :: strict mode throws on unscripted call", () => {
  const sb = fakeSupabase();
  assertRejects(
    () => sb.from("events").select("*").eq("id", "x").single().then((r) => r),
    Error,
    "no script for select",
  );
});

Deno.test("fakeSupabase :: non-strict returns empty on unscripted call", async () => {
  const sb = fakeSupabase({ strict: false });
  const { data, error } = await sb.from("anything").select("*");
  assertEquals(data, null);
  assertEquals(error, null);
});

Deno.test("fakeSupabase :: match function filters scripts", async () => {
  const sb = fakeSupabase()
    .scripted({
      table: "events",
      op: "select",
      match: (s) => s.filters.some((f) => f.col === "id" && f.val === "ev-1"),
      returns: { data: { id: "ev-1" } },
    })
    .scripted({
      table: "events",
      op: "select",
      match: (s) => s.filters.some((f) => f.col === "id" && f.val === "ev-2"),
      returns: { data: { id: "ev-2" } },
    });
  const a = await sb.from("events").select("*").eq("id", "ev-2").single();
  assertEquals(a.data, { id: "ev-2" });
  const b = await sb.from("events").select("*").eq("id", "ev-1").single();
  assertEquals(b.data, { id: "ev-1" });
});

Deno.test("fakeSupabase :: scripts consumed in order", async () => {
  const sb = fakeSupabase()
    .on("events", "select", { data: { v: 1 } })
    .on("events", "select", { data: { v: 2 } });
  const a = await sb.from("events").select("*").eq("id", "x").single();
  const b = await sb.from("events").select("*").eq("id", "y").single();
  assertEquals(a.data, { v: 1 });
  assertEquals(b.data, { v: 2 });
});

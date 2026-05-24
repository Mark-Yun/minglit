import { assertEquals } from "@std/assert";
import {
  isApplicationApprovableForPartnerApproval,
  mapBulkApprovalRpcResult,
  mapSingleApprovalRpcResult,
} from "./application_approval_policy.ts";

Deno.test("isApplicationApprovableForPartnerApproval — pending statuses only", () => {
  assertEquals(isApplicationApprovableForPartnerApproval("pending"), true);
  assertEquals(
    isApplicationApprovableForPartnerApproval("pending_review"),
    true,
  );
  for (const status of ["approved", "paid", "cancelled", "rejected"]) {
    assertEquals(isApplicationApprovableForPartnerApproval(status), false);
  }
});

Deno.test("mapSingleApprovalRpcResult — approved passes", () => {
  assertEquals(mapSingleApprovalRpcResult([{ result_status: "approved" }]), {
    ok: true,
    approved: 1,
  });
});

Deno.test("mapSingleApprovalRpcResult — event_full/already/not_found/errors map to stable responses", () => {
  assertEquals(mapSingleApprovalRpcResult({ result_status: "event_full" }), {
    ok: false,
    status: 409,
    message: "정원이 초과되었습니다.",
    details: { code: "EVENT_FULL" },
  });
  assertEquals(
    mapSingleApprovalRpcResult({ result_status: "already_processed" }),
    {
      ok: false,
      status: 409,
      message: "Application already processed",
    },
  );
  assertEquals(mapSingleApprovalRpcResult({ result_status: "not_found" }), {
    ok: false,
    status: 404,
    message: "Application not found",
  });
  assertEquals(mapSingleApprovalRpcResult({ result_status: "weird" }), {
    ok: false,
    status: 500,
    message: "Event capacity data is invalid",
    details: { code: "INVALID_EVENT_CAPACITY" },
  });
});

Deno.test("mapBulkApprovalRpcResult — invalid/not_found map to errors", () => {
  assertEquals(
    mapBulkApprovalRpcResult({ result_status: "invalid_capacity" }),
    {
      ok: false,
      status: 500,
      message: "Event capacity data is invalid",
      details: { code: "INVALID_EVENT_CAPACITY" },
    },
  );
  assertEquals(mapBulkApprovalRpcResult({ result_status: "not_found" }), {
    ok: false,
    status: 404,
    message: "Event not found",
  });
});

Deno.test("mapBulkApprovalRpcResult — counts default to zero", () => {
  assertEquals(
    mapBulkApprovalRpcResult([{
      result_status: "ok",
      approved_count: 5,
      skipped_due_to_capacity: 2,
      remaining_slots_before_approval: 7,
    }]),
    {
      ok: true,
      approved: 5,
      skippedDueToCapacity: 2,
      remainingSlotsBeforeApproval: 7,
    },
  );
  assertEquals(mapBulkApprovalRpcResult({ result_status: "no_pending" }), {
    ok: true,
    approved: 0,
    skippedDueToCapacity: 0,
    remainingSlotsBeforeApproval: 0,
  });
});

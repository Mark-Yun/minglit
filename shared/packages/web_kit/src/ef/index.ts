// @minglit/web-kit/ef — typed Edge Function 클라이언트
// 함수명·인증 요구의 SSoT: supabase/functions/auth-manifest.json
// 기준: docs/architecture/web-client.md §1 (EF-only mutation gateway)
export {
  callEdgeFunction,
  type CallEdgeFunctionOptions,
  type SessionSource,
} from "./call";
export {
  MinglitError,
  type MinglitErrorEnvelope,
  type MinglitErrorKind,
} from "./errors";

// ── 웹 MVP 코어 EF wrappers ──
export * from "./functions/apply-event";
export * from "./functions/user-create-order";
export * from "./functions/user-cancel-order";
export * from "./functions/user-request-refund";
export * from "./functions/payment-verify";
export * from "./functions/payment-cancel";
export * from "./functions/identity-verify";
export * from "./functions/partner-manage-party";
export * from "./functions/partner-manage-event";
export * from "./functions/partner-review-applications";
export * from "./functions/settlement-query";
export * from "./functions/partner-manage-settlement";
export * from "./functions/recurrence-rules";

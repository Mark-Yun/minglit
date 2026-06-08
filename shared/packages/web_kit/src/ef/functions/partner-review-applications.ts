// partner-review-applications — 파트너 일괄 심사 (approve + reject 단일 트랜잭션)
// manifest: caller=user (파트너 권한은 서버에서 requirePartnerPermission 으로 검사)
// 역산 출처: supabase/functions/partner-review-applications/index.ts
//           + migrations/20260505000005_batch_review_applications_rpc.sql (uuid[] 반환)
import { z } from "zod";
import { callEdgeFunction, type SessionSource } from "../call";

export interface PartnerReviewRejectionItem {
  application_id: string;
  /** 빈 문자열 불가 — 서버가 trim 후 검증 */
  reason: string;
}

export interface PartnerReviewApplicationsRequest {
  event_id: string;
  /** 승인할 application_id 목록 (uuid) */
  approvals?: string[];
  rejections?: PartnerReviewRejectionItem[];
  // 주의: approvals 와 rejections 둘 다 비면 서버가 400 반환
}

export const partnerReviewApplicationsResponseSchema = z.object({
  approved: z.array(z.string()),
  rejected: z.array(z.string()),
  /** 정원 초과로 승인 건너뜀 */
  skipped_due_to_capacity: z.array(z.string()),
  /** 이미 처리된 건 (중복 처리 race) */
  skipped_already_processed: z.array(z.string()),
  remaining_slots_after: z.number(),
});
export type PartnerReviewApplicationsResponse = z.infer<
  typeof partnerReviewApplicationsResponseSchema
>;

export function partnerReviewApplications(
  supabase: SessionSource,
  body: PartnerReviewApplicationsRequest,
  options?: { signal?: AbortSignal },
): Promise<PartnerReviewApplicationsResponse> {
  return callEdgeFunction(supabase, "partner-review-applications", body, {
    schema: partnerReviewApplicationsResponseSchema,
    signal: options?.signal,
  });
}

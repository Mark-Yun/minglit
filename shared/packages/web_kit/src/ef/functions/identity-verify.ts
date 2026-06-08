// identity-verify — PortOne V2 본인인증 결과 검증 → 유저 프로필 업데이트 (CI/DI 암호화 저장)
// manifest: caller=user
// 역산 출처: supabase/functions/identity-verify/index.ts
import { z } from "zod";
import { callEdgeFunction, type SessionSource } from "../call";

export interface IdentityVerifyRequest {
  /** `@portone/browser-sdk` requestIdentityVerification 결과의 identityVerificationId */
  identity_verification_id: string;
}

export const identityVerifyResponseSchema = z.object({
  success: z.literal(true),
  /** 갱신된 유저 id */
  user: z.string(),
});
export type IdentityVerifyResponse = z.infer<
  typeof identityVerifyResponseSchema
>;

export function identityVerify(
  supabase: SessionSource,
  body: IdentityVerifyRequest,
  options?: { signal?: AbortSignal },
): Promise<IdentityVerifyResponse> {
  return callEdgeFunction(supabase, "identity-verify", body, {
    schema: identityVerifyResponseSchema,
    signal: options?.signal,
  });
}

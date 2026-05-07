-- Fix #2250: Create column-restricted view for partner-readable user profile fields.
--
-- The existing "Partners can read applicant profiles" RLS on user_profiles
-- (20260505000001) grants row-level access to ALL columns, which allows partners
-- to read phone_number, birth_date, gender, ci_encrypted, di_encrypted etc. via
-- the PostgREST API. This violates:
--   - PIPA §17 (제3자 제공 동의 — 초과 항목 제공)
--   - PIPA §29 (안전조치 — 파트너 단말에 민감 정보 노출)
--   - PM #1141 결정: 파트너에게는 닉네임/연령대/인증정보만 제공 (성별 제외)
--
-- This migration creates a column-restricted view so that future queries can
-- use `partner_visible_user_profiles` to get only the allowed fields at DB level.
-- The immediate fix is the Dart-layer column selection in getApplicationById().
--
-- Allowed columns per PM #1141:
--   id               — FK join key
--   username         — 닉네임 (nickname)
--   birth_year       — 연령대 (year-based age group, not exact birth_date)
--   is_verified      — 자격 인증 정보
--   profile_image_url — 프로필 이미지 (비식별)

CREATE OR REPLACE VIEW public.partner_visible_user_profiles AS
  SELECT
    id,
    username,
    -- Fix #2250: user_profiles stores birth_date (DATE), not birth_year.
    -- Expose only the derived year (연령대) — exact DOB excluded per PM #1141 & PIPA §17.
    EXTRACT(YEAR FROM birth_date)::int AS birth_year,
    is_verified,
    profile_image_url
  FROM public.user_profiles;

-- Allow authenticated users to SELECT the view.
-- Row-level access is governed by user_profiles RLS policies (security invoker).
GRANT SELECT ON public.partner_visible_user_profiles TO authenticated;

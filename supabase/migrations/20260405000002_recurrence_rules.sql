-- feat(db): recurrence_rules 테이블 + events 컬럼 추가
-- Issue: #1033 (파트너 이벤트 반복 생성 피처 — Task 1: DB Migration)
-- Plan: docs/features/recurring-events/plan.md
--
-- 파트너가 반복 규칙(recurrence rule)을 설정하면 시스템이 최대 1개월 앞까지
-- 이벤트를 자동 배치 생성한다.
--
-- 변경 내용:
--   1. recurrence_rules 테이블 생성 (스키마, FK, CHECK, Partial Unique Index)
--   2. events 테이블 컬럼 추가 (recurrence_rule_id, is_recurrence_exception)
--   3. Partial unique index: uq_events_recurrence_date (중복 생성 방지)
--   4. RLS 정책 (파트너가 자기 파티의 규칙만 CRUD 가능)
--   5. moddatetime 트리거: updated_at 자동 갱신
--   6. pg_cron 등록: 매일 UTC 00:00 recurrence-cron EF 호출

set search_path to public, extensions;

-- ============================================================
-- Section 1: recurrence_rules 테이블
-- ============================================================

CREATE TABLE public.recurrence_rules (
  id                   uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  party_id             uuid        NOT NULL REFERENCES public.parties(id) ON DELETE CASCADE,
  pattern              text        NOT NULL CHECK (pattern IN ('weekly', 'biweekly', 'monthly')),
  days_of_week         int[]       NOT NULL DEFAULT '{}',
  month_day            int         CHECK (month_day >= 1 AND month_day <= 31),
  start_time           time        NOT NULL,
  end_time             time        NOT NULL,
  end_date             date,
  status               text        NOT NULL DEFAULT 'active'
                                   CHECK (status IN ('active', 'paused', 'cancelled')),
  last_generated_date  date,
  created_at           timestamptz NOT NULL DEFAULT now(),
  updated_at           timestamptz NOT NULL DEFAULT now()
);

COMMENT ON TABLE  public.recurrence_rules IS '파트너가 설정한 이벤트 반복 규칙. 크론잡이 매일 1개월치 이벤트를 자동 생성.';
COMMENT ON COLUMN public.recurrence_rules.pattern IS '반복 패턴: weekly(매주), biweekly(격주), monthly(매월)';
COMMENT ON COLUMN public.recurrence_rules.days_of_week IS 'weekly/biweekly 패턴의 요일 배열 (0=일요일, 6=토요일)';
COMMENT ON COLUMN public.recurrence_rules.month_day IS 'monthly 패턴의 날짜 (1~31). V1은 날짜 기반만 지원.';
COMMENT ON COLUMN public.recurrence_rules.status IS '규칙 상태: active(진행), paused(중단), cancelled(취소)';
COMMENT ON COLUMN public.recurrence_rules.last_generated_date IS '마지막으로 이벤트를 생성한 날짜. 크론잡이 이 날짜 이후부터 생성 시작.';

-- ============================================================
-- Section 2: Partial Unique Index — Party 1:1 제약
-- 하나의 Party에 active/paused 규칙은 최대 1개만 허용
-- ============================================================

CREATE UNIQUE INDEX uq_recurrence_rules_party_active
  ON public.recurrence_rules (party_id)
  WHERE status IN ('active', 'paused');

-- ============================================================
-- Section 3: events 테이블 컬럼 추가
-- ============================================================

ALTER TABLE public.events
  ADD COLUMN recurrence_rule_id      uuid    REFERENCES public.recurrence_rules(id) ON DELETE SET NULL,
  ADD COLUMN is_recurrence_exception boolean NOT NULL DEFAULT false;

COMMENT ON COLUMN public.events.recurrence_rule_id IS '반복 규칙으로 생성된 이벤트의 원본 규칙 ID. 수동 생성 이벤트는 NULL.';
COMMENT ON COLUMN public.events.is_recurrence_exception IS '반복 규칙의 예외 이벤트 여부 (수동 수정된 회차)';

-- ============================================================
-- Section 4: Partial Unique Index — 중복 생성 방지
-- (recurrence_rule_id, start_time 날짜) 조합 유일 보장
-- ============================================================

CREATE UNIQUE INDEX uq_events_recurrence_date
  ON public.events (recurrence_rule_id, (start_time::date))
  WHERE recurrence_rule_id IS NOT NULL;

-- ============================================================
-- Section 5: recurrence_rules 인덱스
-- ============================================================

CREATE INDEX idx_recurrence_rules_party_id ON public.recurrence_rules(party_id);
CREATE INDEX idx_recurrence_rules_status   ON public.recurrence_rules(status);
CREATE INDEX idx_events_recurrence_rule_id ON public.events(recurrence_rule_id)
  WHERE recurrence_rule_id IS NOT NULL;

-- ============================================================
-- Section 6: RLS
-- 파트너가 자기 파티의 규칙만 CRUD 가능
-- service_role은 전체 접근 가능 (EF 크론잡 사용)
-- ============================================================

ALTER TABLE public.recurrence_rules ENABLE ROW LEVEL SECURITY;

-- 파트너: 자기 파티에 속한 규칙만 조회
CREATE POLICY "partner_read_own_recurrence_rules"
  ON public.recurrence_rules
  FOR SELECT
  USING (
    public.is_super_admin()
    OR public.has_partner_permission(
      (SELECT partner_id FROM public.parties WHERE id = party_id),
      'PARTY_MANAGE'
    )
  );

-- 파트너: 자기 파티에 규칙 INSERT
CREATE POLICY "partner_insert_recurrence_rules"
  ON public.recurrence_rules
  FOR INSERT
  WITH CHECK (
    public.has_partner_permission(
      (SELECT partner_id FROM public.parties WHERE id = party_id),
      'PARTY_MANAGE'
    )
  );

-- 파트너: 자기 파티의 규칙 UPDATE (status 변경: pause/resume/cancel)
CREATE POLICY "partner_update_recurrence_rules"
  ON public.recurrence_rules
  FOR UPDATE
  USING (
    public.has_partner_permission(
      (SELECT partner_id FROM public.parties WHERE id = party_id),
      'PARTY_MANAGE'
    )
  )
  WITH CHECK (
    public.has_partner_permission(
      (SELECT partner_id FROM public.parties WHERE id = party_id),
      'PARTY_MANAGE'
    )
  );

-- 파트너: 자기 파티의 규칙 DELETE (cancelled 상태만)
-- Note: 논리 삭제(status=cancelled)를 권장하나 물리 삭제도 허용
CREATE POLICY "partner_delete_recurrence_rules"
  ON public.recurrence_rules
  FOR DELETE
  USING (
    public.is_super_admin()
    OR public.has_partner_permission(
      (SELECT partner_id FROM public.parties WHERE id = party_id),
      'PARTY_MANAGE'
    )
  );

-- ============================================================
-- Section 7: GRANT
-- ============================================================

GRANT SELECT, INSERT, UPDATE, DELETE ON public.recurrence_rules TO authenticated;

-- ============================================================
-- Section 8: moddatetime 트리거 — updated_at 자동 갱신
-- ============================================================

CREATE TRIGGER handle_updated_at
  BEFORE UPDATE ON public.recurrence_rules
  FOR EACH ROW EXECUTE PROCEDURE moddatetime(updated_at);

-- ============================================================
-- Section 9: pg_cron 등록 — 매일 UTC 00:00 recurrence-cron EF 호출
-- ============================================================

SELECT cron.unschedule(jobid)
FROM cron.job
WHERE jobname = 'recurrence-cron-daily';

SELECT cron.schedule(
  'recurrence-cron-daily',
  '0 0 * * *',
  $$
    SELECT net.http_post(
      url := (
        SELECT decrypted_secret FROM vault.decrypted_secrets
        WHERE name = 'supabase_url' LIMIT 1
      ) || '/functions/v1/recurrence-cron',
      headers := (
        jsonb_build_object(
          'Content-Type', 'application/json',
          'Authorization', 'Bearer ' || (
            SELECT decrypted_secret FROM vault.decrypted_secrets
            WHERE name = 'publishable_key' LIMIT 1
          )
        )
      ),
      body := '{}'::jsonb
    ) AS request_id;
  $$
);

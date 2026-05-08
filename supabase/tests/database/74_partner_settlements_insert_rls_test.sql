-- Fix #2322: partner_settlements INSERT RLS 회귀 방지 테스트
-- upsertBankAccount() 경로 — SETTLEMENT_EDIT 권한 보유자만 INSERT 가능
BEGIN;
SELECT plan(4);

SELECT tests.create_supabase_user('owner_user', 'settlement_insert_owner@test.com');
SELECT tests.create_supabase_user('outsider_user', 'settlement_insert_outsider@test.com');

SELECT tests.authenticate_as_service_role();

WITH partner AS (
  INSERT INTO public.partners (name, introduction)
  VALUES ('Settlement Insert Test Partner', 'Test')
  RETURNING id
)
SELECT set_config('tests.partner_id', id::text, true) FROM partner;

-- owner 권한 부여 (sync_partner_member_permissions 트리거가 SETTLEMENT_EDIT 포함 권한 배열 설정)
INSERT INTO public.partner_member_permissions (partner_id, user_id, role)
VALUES (
  current_setting('tests.partner_id')::uuid,
  tests.get_supabase_uid('owner_user'),
  'owner'
);

-- Test 1: owner (SETTLEMENT_EDIT) — bank-only upsert INSERT 성공
-- Fix #2322: INSERT 정책이 없으면 이 테스트가 실패함
SELECT tests.authenticate_as('owner_user');
SELECT lives_ok(
  format(
    $$INSERT INTO public.partner_settlements (partner_id, bank_name, account_number, account_holder)
      VALUES (%L, 'Kakaobank', '111-222-333', 'Test Owner')
      ON CONFLICT (partner_id) DO UPDATE
        SET bank_name      = EXCLUDED.bank_name,
            account_number = EXCLUDED.account_number,
            account_holder = EXCLUDED.account_holder$$,
    current_setting('tests.partner_id')
  ),
  'owner with SETTLEMENT_EDIT can upsert (INSERT path) bank account into partner_settlements'
);

-- Test 2: upsert UPDATE 경로도 성공 (레코드가 이미 존재하므로 ON CONFLICT 동작)
SELECT lives_ok(
  format(
    $$INSERT INTO public.partner_settlements (partner_id, bank_name, account_number, account_holder)
      VALUES (%L, 'Kookmin', '444-555-666', 'Test Owner Updated')
      ON CONFLICT (partner_id) DO UPDATE
        SET bank_name      = EXCLUDED.bank_name,
            account_number = EXCLUDED.account_number,
            account_holder = EXCLUDED.account_holder$$,
    current_setting('tests.partner_id')
  ),
  'owner with SETTLEMENT_EDIT can upsert (UPDATE path) bank account into partner_settlements'
);

-- Test 3: INSERT 후 SELECT로 저장 확인
SELECT results_eq(
  format(
    $$SELECT bank_name FROM public.partner_settlements
      WHERE partner_id = %L$$,
    current_setting('tests.partner_id')
  ),
  $$VALUES ('Kookmin')$$,
  'upserted bank_name is persisted and readable by owner'
);

-- Test 4: outsider (파트너 멤버 아님) — INSERT 차단
SELECT tests.authenticate_as('outsider_user');
SELECT throws_ok(
  format(
    $$INSERT INTO public.partner_settlements (partner_id, bank_name, account_number, account_holder)
      VALUES (%L, 'Hana', '777-888-999', 'Outsider')$$,
    current_setting('tests.partner_id')
  ),
  '42501',
  NULL,
  'outsider cannot insert into partner_settlements'
);

SELECT * FROM finish();
ROLLBACK;

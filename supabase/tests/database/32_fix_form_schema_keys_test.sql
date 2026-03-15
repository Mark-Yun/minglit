BEGIN;
SELECT plan(8);

SELECT tests.authenticate_as_service_role();

-- ============================================================
-- Setup: Insert verifications with various form_schema states
-- ============================================================

-- 1) Missing 'key' — single field
INSERT INTO public.verifications (id, category, internal_name, display_name, form_schema)
VALUES (
  '00000000-0000-0000-0000-ffffffffffff',
  'career',
  'test_no_key_single',
  'Test No Key Single',
  '[{"type": "image", "label": "재직증명서"}]'::jsonb
);

-- 2) Missing 'key' — multiple fields
INSERT INTO public.verifications (id, category, internal_name, display_name, form_schema)
VALUES (
  '00000000-0000-0000-0000-fffffffffffe',
  'academic',
  'test_no_key_multi',
  'Test No Key Multi',
  '[{"type": "text", "label": "학교명"}, {"type": "image", "label": "학생증"}]'::jsonb
);

-- 3) Already has 'key' — should NOT be modified
INSERT INTO public.verifications (id, category, internal_name, display_name, form_schema)
VALUES (
  '00000000-0000-0000-0000-fffffffffffd',
  'asset',
  'test_has_key',
  'Test Has Key',
  '[{"key": "company", "type": "text", "label": "회사명", "required": true}]'::jsonb
);

-- 4) Empty form_schema — should NOT be modified
INSERT INTO public.verifications (id, category, internal_name, display_name, form_schema)
VALUES (
  '00000000-0000-0000-0000-fffffffffffc',
  'etc',
  'test_empty_schema',
  'Test Empty Schema',
  '[]'::jsonb
);

-- ============================================================
-- Apply the migration logic
-- ============================================================
UPDATE public.verifications
SET form_schema = (
  SELECT coalesce(
    jsonb_agg(
      CASE
        WHEN elem ? 'key' THEN elem
        ELSE jsonb_set(elem, '{key}', to_jsonb('field_' || (idx - 1)::text))
      END
      ORDER BY idx
    ),
    '[]'::jsonb
  )
  FROM jsonb_array_elements(form_schema) WITH ORDINALITY AS t(elem, idx)
)
WHERE EXISTS (
  SELECT 1
  FROM jsonb_array_elements(form_schema) AS elem
  WHERE NOT (elem ? 'key')
);

-- ============================================================
-- Tests
-- ============================================================

-- Test 1: Single missing key gets 'field_0'
SELECT is(
  (SELECT form_schema->0->>'key' FROM public.verifications WHERE id = '00000000-0000-0000-0000-ffffffffffff'),
  'field_0',
  'Single field without key gets field_0'
);

-- Test 2: Multiple missing keys get sequential field_N
SELECT is(
  (SELECT form_schema->0->>'key' FROM public.verifications WHERE id = '00000000-0000-0000-0000-fffffffffffe'),
  'field_0',
  'First field of multi gets field_0'
);

SELECT is(
  (SELECT form_schema->1->>'key' FROM public.verifications WHERE id = '00000000-0000-0000-0000-fffffffffffe'),
  'field_1',
  'Second field of multi gets field_1'
);

-- Test 3: Existing key preserved
SELECT is(
  (SELECT form_schema->0->>'key' FROM public.verifications WHERE id = '00000000-0000-0000-0000-fffffffffffd'),
  'company',
  'Existing key is preserved unchanged'
);

-- Test 4: Other fields preserved after key injection
SELECT is(
  (SELECT form_schema->0->>'type' FROM public.verifications WHERE id = '00000000-0000-0000-0000-ffffffffffff'),
  'image',
  'type field preserved after key injection'
);

SELECT is(
  (SELECT form_schema->0->>'label' FROM public.verifications WHERE id = '00000000-0000-0000-0000-ffffffffffff'),
  '재직증명서',
  'label field preserved after key injection'
);

-- Test 5: Empty form_schema unchanged
SELECT is(
  (SELECT jsonb_array_length(form_schema) FROM public.verifications WHERE id = '00000000-0000-0000-0000-fffffffffffc'),
  0,
  'Empty form_schema remains empty'
);

-- Test 6: No record has form_schema entries without 'key' anymore
-- (This would catch any records we missed)
SELECT is(
  (SELECT count(*)::integer
   FROM public.verifications v,
        jsonb_array_elements(v.form_schema) AS elem
   WHERE NOT (elem ? 'key')
  ),
  0,
  'No form_schema entries without key remain in entire table'
);

SELECT * FROM finish();
ROLLBACK;

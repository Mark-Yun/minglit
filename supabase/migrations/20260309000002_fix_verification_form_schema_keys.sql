-- Fix: Add missing 'key' field to form_schema entries in verifications table.
-- Root cause of issue #42: VerificationFormField.fromJson crashes when 'key' is null.
-- All dev DB records have form_schema entries like {"type":"image","label":"재직증명서"}
-- without the required 'key' field.

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

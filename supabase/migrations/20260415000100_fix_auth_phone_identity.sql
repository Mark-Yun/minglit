-- Fix phone NULL → use phone_number from user metadata (unique per user).
-- phone column has a unique constraint, so empty string '' causes duplicates.
UPDATE auth.users
SET phone = COALESCE(raw_user_meta_data->>'phone_number', id::text)
WHERE phone IS NULL;

-- Fix duplicate identities: keep only the FIRST identity per user (by created_at).
-- Delete the second (seed-created) identity for users with multiple.
DELETE FROM auth.identities
WHERE id IN (
  SELECT id FROM (
    SELECT id, ROW_NUMBER() OVER (PARTITION BY user_id, provider ORDER BY created_at ASC) as rn
    FROM auth.identities
  ) ranked
  WHERE rn > 1
);

-- Cleanup: drop temp diagnostic function
DROP FUNCTION IF EXISTS public.temp_auth_diag();

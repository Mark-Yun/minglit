-- Fix #1957: atomic set_social_interaction RPC
--
-- Replaces the client-side 2-step (delete opposite + upsert) with a single
-- server-side function that runs in one transaction and serialises concurrent
-- calls for the same user+target via an advisory lock.
--
-- This eliminates the TOCTOU race where two concurrent toggle-on requests both
-- saw an empty result and deleted each other's rows, as well as the cross-intent
-- (like vs dislike) race where both could land simultaneously.

CREATE OR REPLACE FUNCTION public.set_social_interaction(
  p_target_id        text,
  p_target_type      text,
  p_interaction_type text,
  p_active           boolean
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id uuid := auth.uid();
  v_opposite public.social_interaction_type;
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'User not authenticated';
  END IF;

  -- Advisory lock scoped to this transaction.
  -- Serialises concurrent calls for the same (user, target) so that a
  -- simultaneous like + dislike cannot both land.
  -- Key = lower 63 bits of MD5(user_id || ':' || target_id).
  PERFORM pg_advisory_xact_lock(
    ('x' || left(md5(v_user_id::text || ':' || p_target_id), 16))::bit(64)::bigint
  );

  IF p_active THEN
    -- Like and dislike are mutually exclusive: remove the opposite first.
    IF p_interaction_type IN ('like', 'dislike') THEN
      v_opposite := CASE p_interaction_type
        WHEN 'like' THEN 'dislike'::public.social_interaction_type
        ELSE              'like'::public.social_interaction_type
      END;
      DELETE FROM public.social_interactions
      WHERE user_id        = v_user_id
        AND target_id      = p_target_id::uuid
        AND interaction_type = v_opposite;
    END IF;

    -- Idempotent insert: concurrent same-intent calls after the lock are no-ops.
    INSERT INTO public.social_interactions
      (user_id, target_id, target_type, interaction_type)
    VALUES (
      v_user_id,
      p_target_id::uuid,
      p_target_type::public.social_target_type,
      p_interaction_type::public.social_interaction_type
    )
    ON CONFLICT (user_id, target_id, interaction_type) DO NOTHING;
  ELSE
    DELETE FROM public.social_interactions
    WHERE user_id        = v_user_id
      AND target_id      = p_target_id::uuid
      AND interaction_type = p_interaction_type::public.social_interaction_type;
  END IF;
END;
$$;

GRANT EXECUTE ON FUNCTION public.set_social_interaction(text, text, text, boolean)
  TO authenticated;

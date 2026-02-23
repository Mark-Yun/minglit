-- Migration 31: Refactor produce_event() to write to q_global_events
-- Adds an overloaded produce_event() with explicit parameters (RETURNS void)
-- The original produce_event() RETURNS trigger is preserved for backward compatibility

CREATE OR REPLACE FUNCTION public.produce_event(
  p_event_type public.event_type_name,
  p_source_table text,
  p_source_id uuid,
  p_row_data jsonb
) RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions, pgmq, temp
AS $$
DECLARE
  v_event_id uuid := gen_random_uuid();
BEGIN
  PERFORM pgmq.send(
    'q_global_events',
    jsonb_build_object(
      'event_id', v_event_id,
      'event_type', p_event_type::text,
      'occurred_at', extract(epoch from now())::bigint,
      'schema_version', 1,
      'data', p_row_data,
      'metadata', jsonb_build_object(
        'source_table', p_source_table,
        'source_id', p_source_id
      )
    )
  );

  INSERT INTO public.processed_events (id, processed_at)
  VALUES (v_event_id, now())
  ON CONFLICT (id) DO NOTHING;
END;
$$;

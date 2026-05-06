-- Fix #2235: replace failed migration 20260505000011.
-- 000011 (ticket_templates CHECK constraint) was never applied because 000010 failed first.
-- This migration backfills violating ticket_templates rows, then adds the constraint idempotently.

UPDATE public.ticket_templates
SET target_entry_group_ids = target_entry_group_ids[1:1]
WHERE array_length(target_entry_group_ids, 1) > 1;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'ticket_templates_target_entry_group_single'
      AND conrelid = 'public.ticket_templates'::regclass
  ) THEN
    ALTER TABLE public.ticket_templates
      ADD CONSTRAINT ticket_templates_target_entry_group_single
      CHECK (array_length(target_entry_group_ids, 1) <= 1);
  END IF;
END $$;

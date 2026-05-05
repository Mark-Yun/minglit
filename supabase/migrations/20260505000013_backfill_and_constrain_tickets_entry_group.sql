-- Fix #2235: replace failed migration 20260505000010.
-- 000010 (tickets CHECK constraint) blocked all deploys because dev DB had rows
-- with array_length(target_entry_group_ids, 1) > 1. The constraint was added without
-- a prior backfill, causing ALTER TABLE to fail (SQLSTATE 23514).
-- 000010 was deleted from the repo (it was never successfully applied to any DB).
-- This migration backfills the violating rows first, then adds the constraint idempotently.

-- Backfill: truncate to first element, preserving group-specific targeting over global.
UPDATE public.tickets
SET target_entry_group_ids = target_entry_group_ids[1:1]
WHERE array_length(target_entry_group_ids, 1) > 1;

-- Idempotent constraint addition (handles both dev where 000010 never ran,
-- and any future env where a prior version of this constraint might already exist).
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'tickets_target_entry_group_single'
      AND conrelid = 'public.tickets'::regclass
  ) THEN
    ALTER TABLE public.tickets
      ADD CONSTRAINT tickets_target_entry_group_single
      CHECK (array_length(target_entry_group_ids, 1) <= 1);
  END IF;
END $$;

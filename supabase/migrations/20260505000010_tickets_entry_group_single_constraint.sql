-- Fix #2102: enforce Ticket → EntryGroup 1:1 via CHECK constraint.
-- Option A: minimal additive change — keeps existing uuid[] type so all ANY() callers
-- stay unchanged. Allows 0 (global ticket) or 1 (group-specific ticket).
-- array_length('{}', 1) returns NULL, so NULL <= 1 is NULL (not false) → empty array allowed.

ALTER TABLE public.tickets
  ADD CONSTRAINT tickets_target_entry_group_single
  CHECK (array_length(target_entry_group_ids, 1) <= 1);

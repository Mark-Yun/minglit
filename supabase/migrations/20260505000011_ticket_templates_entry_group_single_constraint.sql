-- Issue #2102: extend Ticket→EntryGroup 1:1 invariant to the template source.
-- Without this, partner-manage-party EF can store 2+ groups in ticket_templates
-- which then propagates to tickets on event creation and trips the tickets CHECK.
-- Allows 0 (global template) or 1 (group-specific template).

ALTER TABLE public.ticket_templates
  ADD CONSTRAINT ticket_templates_target_entry_group_single
  CHECK (array_length(target_entry_group_ids, 1) <= 1);

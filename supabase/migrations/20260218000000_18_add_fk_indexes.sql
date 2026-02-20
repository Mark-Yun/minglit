-- 18. Add Missing FK Indexes
set search_path to public, extensions;
-- Adds indexes on foreign key columns that lack them.
-- Improves JOIN performance and CASCADE delete efficiency.
-- All statements are idempotent (IF NOT EXISTS).

-- ============================================================
-- 03_partners
-- ============================================================

-- partner_member_permissions
CREATE INDEX IF NOT EXISTS idx_partner_member_permissions_partner_id
  ON public.partner_member_permissions(partner_id);
CREATE INDEX IF NOT EXISTS idx_partner_member_permissions_user_id
  ON public.partner_member_permissions(user_id);

-- partner_applications
CREATE INDEX IF NOT EXISTS idx_partner_applications_user_id
  ON public.partner_applications(user_id);

-- locations
CREATE INDEX IF NOT EXISTS idx_locations_partner_id
  ON public.locations(partner_id);

-- verifications
CREATE INDEX IF NOT EXISTS idx_verifications_partner_id
  ON public.verifications(partner_id);

-- ============================================================
-- 04_events
-- ============================================================

-- parties
CREATE INDEX IF NOT EXISTS idx_parties_partner_id
  ON public.parties(partner_id);
CREATE INDEX IF NOT EXISTS idx_parties_location_id
  ON public.parties(location_id);

-- events
CREATE INDEX IF NOT EXISTS idx_events_party_id
  ON public.events(party_id);
CREATE INDEX IF NOT EXISTS idx_events_location_id
  ON public.events(location_id);

-- entry_group_templates
CREATE INDEX IF NOT EXISTS idx_entry_group_templates_party_id
  ON public.entry_group_templates(party_id);

-- entry_groups
CREATE INDEX IF NOT EXISTS idx_entry_groups_event_id
  ON public.entry_groups(event_id);

-- ticket_templates
CREATE INDEX IF NOT EXISTS idx_ticket_templates_party_id
  ON public.ticket_templates(party_id);

-- tickets
CREATE INDEX IF NOT EXISTS idx_tickets_event_id
  ON public.tickets(event_id);

-- ============================================================
-- 05_commerce
-- ============================================================

-- event_applications
CREATE INDEX IF NOT EXISTS idx_event_applications_event_id
  ON public.event_applications(event_id);
CREATE INDEX IF NOT EXISTS idx_event_applications_ticket_id
  ON public.event_applications(ticket_id);
CREATE INDEX IF NOT EXISTS idx_event_applications_user_id
  ON public.event_applications(user_id);

-- verification_submissions
CREATE INDEX IF NOT EXISTS idx_verification_submissions_partner_id
  ON public.verification_submissions(partner_id);
CREATE INDEX IF NOT EXISTS idx_verification_submissions_user_id
  ON public.verification_submissions(user_id);
CREATE INDEX IF NOT EXISTS idx_verification_submissions_verification_id
  ON public.verification_submissions(verification_id);
CREATE INDEX IF NOT EXISTS idx_verification_submissions_reviewed_by
  ON public.verification_submissions(reviewed_by);

-- user_verifications
CREATE INDEX IF NOT EXISTS idx_user_verifications_verification_id
  ON public.user_verifications(verification_id);

-- partner_verified_users
CREATE INDEX IF NOT EXISTS idx_partner_verified_users_submission_id
  ON public.partner_verified_users(submission_id);

-- event_participants
CREATE INDEX IF NOT EXISTS idx_event_participants_ticket_id
  ON public.event_participants(ticket_id);
CREATE INDEX IF NOT EXISTS idx_event_participants_user_id
  ON public.event_participants(user_id);
CREATE INDEX IF NOT EXISTS idx_event_participants_application_id
  ON public.event_participants(application_id);

-- verification_comments
CREATE INDEX IF NOT EXISTS idx_verification_comments_submission_id
  ON public.verification_comments(submission_id);
CREATE INDEX IF NOT EXISTS idx_verification_comments_author_id
  ON public.verification_comments(author_id);

-- ============================================================
-- 08_matching
-- ============================================================

-- match_rules (event_id already indexed)
CREATE INDEX IF NOT EXISTS idx_match_rules_source_group_id
  ON public.match_rules(source_group_id);
CREATE INDEX IF NOT EXISTS idx_match_rules_target_group_id
  ON public.match_rules(target_group_id);

-- match_votes (candidate_id not indexed)
CREATE INDEX IF NOT EXISTS idx_match_votes_candidate_id
  ON public.match_votes(candidate_id);

-- ============================================================
-- 11_notifications
-- ============================================================

-- fcm_tokens
CREATE INDEX IF NOT EXISTS idx_fcm_tokens_user_id
  ON public.fcm_tokens(user_id);

-- ============================================================
-- 13_file_management
-- ============================================================

-- minglit_files
CREATE INDEX IF NOT EXISTS idx_minglit_files_storage_object_id
  ON public.minglit_files(storage_object_id);

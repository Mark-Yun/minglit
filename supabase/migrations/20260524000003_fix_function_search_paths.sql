-- Issue #2744: fix Security Advisor function_search_path_mutable WARNs.
--
-- Keep function bodies, grants, volatility, and SECURITY DEFINER/INVOKER flags
-- unchanged. This migration only pins each function's runtime search_path.

ALTER FUNCTION admin.validate_retention_policy_legal_min()
  SET search_path = pg_catalog, admin, public;

ALTER FUNCTION public.cast_match_vote(uuid, uuid, uuid, integer)
  SET search_path = public;

ALTER FUNCTION public.check_party_tags_limit()
  SET search_path = public;

ALTER FUNCTION public.check_tag_name_sensitivity()
  SET search_path = public;

ALTER FUNCTION public.check_user_interest_tags_limit()
  SET search_path = public;

ALTER FUNCTION public.commit_match_likes(uuid, uuid, uuid[], integer)
  SET search_path = public;

ALTER FUNCTION public.fn_clear_recurrence_date_on_rule_delete()
  SET search_path = public;

ALTER FUNCTION public.get_matched_user_contact(uuid, uuid)
  SET search_path = public;

ALTER FUNCTION public.handle_event_reschedule()
  SET search_path = public;

ALTER FUNCTION public.handle_fcm_token_update()
  SET search_path = public;

ALTER FUNCTION public.handle_new_application_files()
  SET search_path = public;

ALTER FUNCTION public.handle_new_match_vote()
  SET search_path = public;

ALTER FUNCTION public.handle_new_user_settings()
  SET search_path = public;

ALTER FUNCTION public.handle_new_user()
  SET search_path = public;

ALTER FUNCTION public.handle_storage_object_created()
  SET search_path = public;

ALTER FUNCTION public.handle_updated_at()
  SET search_path = public;

ALTER FUNCTION public.has_partner_permission(uuid, text)
  SET search_path = public;

ALTER FUNCTION public.is_super_admin()
  SET search_path = public;

ALTER FUNCTION public.normalize_for_filter(text)
  SET search_path = public;

ALTER FUNCTION public.search_events_pgroonga(text)
  SET search_path = public, extensions;

ALTER FUNCTION public.search_parties_pgroonga(text)
  SET search_path = public, extensions;

ALTER FUNCTION public.sync_max_participants()
  SET search_path = public;

ALTER FUNCTION public.sync_partner_member_permissions()
  SET search_path = public;

ALTER FUNCTION public.update_event_participation_stats()
  SET search_path = public;

ALTER FUNCTION public.update_single_settlement_ready_status(uuid)
  SET search_path = public;

ALTER FUNCTION public.update_tag_usage_count()
  SET search_path = public;

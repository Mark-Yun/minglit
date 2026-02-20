-- 22. Bulk Eligibility Data RPC Function
set search_path to public, extensions;

create or replace function public.get_bulk_eligibility_data(
  p_user_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_profile jsonb;
  v_verifications jsonb;
begin
  select jsonb_build_object(
    'gender', up.gender,
    'birth_year', extract(year from up.birth_date)::int,
    'is_verified', up.is_verified
  ) into v_profile
  from public.user_profiles up
  where up.id = p_user_id;

  if v_profile is null then
    return jsonb_build_object(
      'user_profile', null,
      'approved_verifications', '[]'::jsonb
    );
  end if;

  select coalesce(jsonb_agg(
    jsonb_build_object(
      'partner_id', pvu.partner_id,
      'verification_id', pvu.verification_id,
      'verified_at', pvu.verified_at,
      'valid_until', pvu.valid_until
    )
  ), '[]'::jsonb) into v_verifications
  from public.partner_verified_users pvu
  where pvu.user_id = p_user_id
    and (pvu.valid_until is null or pvu.valid_until > now());

  return jsonb_build_object(
    'user_profile', v_profile,
    'approved_verifications', v_verifications
  );
end;
$$;

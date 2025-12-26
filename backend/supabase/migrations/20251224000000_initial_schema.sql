-- 1. Enum 타입 정의
create type public.gender as enum ('male', 'female');
create type public.partner_role as enum ('owner', 'manager', 'staff');
create type public.verification_status as enum ('pending', 'approved', 'rejected', 'needs_correction', 'resubmitted');
create type public.verification_category as enum ('career', 'asset', 'marriage', 'academic', 'vehicle', 'etc');
create type public.partner_application_status as enum ('pending', 'approved', 'rejected', 'needs_correction');
create type public.business_type as enum ('individual', 'corporate');

-- 2. 사용자 프로필 테이블
create table public.user_profiles (
  id uuid references auth.users on delete cascade primary key,
  username text unique,
  name text,
  phone_number text unique,
  birth_date date,
  gender gender,
  is_verified boolean default false,
  ci text,
  di text unique,
  created_at timestamp with time zone default now(),
  updated_at timestamp with time zone default now()
);

-- 3. 시스템 전역 권한 테이블 (슈퍼어드민 등)
create table public.app_roles (
  user_id uuid references auth.users on delete cascade primary key,
  role text not null check (role in ('super_admin', 'moderator')),
  created_at timestamp with time zone default now()
);

-- 4. 파트너 테이블 (공개 정보)
create table public.partners (
  id uuid default gen_random_uuid() primary key,
  name text not null,
  introduction text,
  address text,
  contact_phone text,
  contact_email text,
  representative_name text,
  biz_name text,
  biz_number text,
  profile_image_url text,
  is_active boolean default true,
  created_at timestamp with time zone default now(),
  updated_at timestamp with time zone default now()
);

-- 5. 파트너 정산 정보 테이블 (민감 정보)
create table public.partner_settlements (
  partner_id uuid references public.partners(id) on delete cascade primary key,
  biz_type business_type not null,
  biz_name text not null,
  biz_number text not null,
  representative_name text not null,
  bank_name text not null,
  account_number text not null,
  account_holder text not null,
  tax_email text,
  biz_registration_path text,
  bankbook_path text,
  updated_at timestamp with time zone default now()
);

-- 6. 파트너 멤버 및 권한 관리 테이블 (이름 변경: partner_members -> partner_member_permissions)
create table public.partner_member_permissions (
  id uuid default gen_random_uuid() primary key,
  partner_id uuid references public.partners(id) on delete cascade not null,
  user_id uuid references auth.users(id) on delete cascade not null,
  role partner_role default 'staff' not null,
  permissions text[] not null default '{}',
  joined_at timestamp with time zone default now(),
  unique(partner_id, user_id)
);

-- 7. 파트너 가입 신청 테이블
create table public.partner_applications (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references auth.users(id) on delete cascade not null,
  status partner_application_status default 'pending' not null,
  brand_name text not null,
  introduction text,
  address text,
  contact_phone text,
  contact_email text,
  biz_type business_type not null,
  biz_name text not null,
  biz_number text not null,
  representative_name text not null,
  bank_name text not null,
  account_number text not null,
  account_holder text not null,
  tax_email text,
  biz_registration_path text not null,
  bankbook_path text not null,
  admin_comment text,
  created_at timestamp with time zone default now(),
  updated_at timestamp with time zone default now()
);

-- 8. 인증 항목 마스터 테이블
create table public.verifications (
  id uuid default gen_random_uuid() primary key,
  category verification_category not null,
  title text not null,
  description text,
  required_docs jsonb,
  partner_id uuid references public.partners(id) on delete cascade,
  created_at timestamp with time zone default now()
);

-- 9. 유저별 최신 인증 데이터 (원본)
create table public.user_verifications (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references auth.users(id) on delete cascade not null,
  verification_id uuid references public.verifications(id) on delete cascade not null,
  claim_data jsonb not null,
  proof_images text[] not null,
  updated_at timestamp with time zone default now(),
  unique(user_id, verification_id)
);

-- 10. 인증 심사 요청 테이블
create table public.verification_requests (
  id uuid default gen_random_uuid() primary key,
  partner_id uuid references public.partners(id) on delete cascade not null,
  user_id uuid references auth.users(id) on delete cascade not null,
  verification_id uuid references public.verifications(id) on delete cascade not null,
  status verification_status default 'pending' not null,
  claim_snapshot jsonb not null,
  rejection_reason text,
  created_at timestamp with time zone default now(),
  updated_at timestamp with time zone default now()
);

-- 11. 심사 코멘트
create table public.verification_comments (
  id uuid default gen_random_uuid() primary key,
  request_id uuid references public.verification_requests(id) on delete cascade not null,
  author_id uuid references auth.users(id) not null,
  content jsonb not null,
  created_at timestamp with time zone default now()
);

-- 12. 파트너별 최종 승인 결과 테이블
create table public.partner_verified_users (
  partner_id uuid references public.partners(id) on delete cascade not null,
  user_id uuid references auth.users(id) on delete cascade not null,
  verification_id uuid references public.verifications(id) on delete cascade not null,
  verified_snapshot jsonb not null,
  verified_at timestamp with time zone default now(),
  primary key (partner_id, user_id, verification_id)
);

-- 13. 파티 테이블
create table public.parties (
  id uuid default gen_random_uuid() primary key,
  partner_id uuid references public.partners(id) on delete cascade not null,
  title text not null,
  required_verification_ids uuid[] not null,
  created_at timestamp with time zone default now(),
  updated_at timestamp with time zone default now()
);

-- 14. [보안 함수] --

create or replace function public.is_super_admin()
returns boolean as $$
  select exists (
    select 1 from public.app_roles 
    where user_id = auth.uid() and role = 'super_admin'
  );
$$ language sql security definer;

create or replace function public.has_partner_permission(p_id uuid, p_key text)
returns boolean as $$
begin
  if public.is_super_admin() then return true; end if;

  return exists (
    select 1 from public.partner_member_permissions
    where partner_id = p_id 
    and user_id = auth.uid()
    and p_key = any(permissions)
  );
end;
$$ language plpgsql security definer;

-- 15. [RLS 비활성화 - 개발 모드]
alter table public.user_profiles disable row level security;
alter table public.partners disable row level security;
alter table public.partner_settlements disable row level security;
alter table public.partner_member_permissions disable row level security;
alter table public.partner_applications disable row level security;
alter table public.verifications disable row level security;
alter table public.user_verifications disable row level security;
alter table public.verification_requests disable row level security;
alter table public.verification_comments disable row level security;
alter table public.partner_verified_users disable row level security;
alter table public.parties disable row level security;

-- 16. [트리거 및 함수] --

create or replace function public.handle_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

create trigger set_user_profiles_updated_at before update on public.user_profiles for each row execute procedure public.handle_updated_at();
create trigger set_partners_updated_at before update on public.partners for each row execute procedure public.handle_updated_at();
create trigger set_partner_settlements_updated_at before update on public.partner_settlements for each row execute procedure public.handle_updated_at();
create trigger set_partner_applications_updated_at before update on public.partner_applications for each row execute procedure public.handle_updated_at();
create trigger set_verification_requests_updated_at before update on public.verification_requests for each row execute procedure public.handle_updated_at();
create trigger set_parties_updated_at before update on public.parties for each row execute procedure public.handle_updated_at();

-- 역할 변경 시 권한 자동 동기화
create or replace function public.sync_partner_member_permissions()
returns trigger as $$
begin
  if (new.role = 'owner') then
    new.permissions := array[
      'PARTNER_EDIT', 'SETTLEMENT_VIEW', 'SETTLEMENT_EDIT', 
      'MEMBER_MANAGE', 'PARTY_MANAGE', 'VERIFY_LIST_VIEW', 
      'USER_DATA_VIEW', 'VERIFY_REVIEW', 'COMMENT_MANAGE'
    ];
  elsif (new.role = 'manager') then
    new.permissions := array[
      'PARTNER_EDIT', 'PARTY_MANAGE', 'VERIFY_LIST_VIEW', 
      'USER_DATA_VIEW', 'VERIFY_REVIEW', 'COMMENT_MANAGE'
    ];
  elsif (new.role = 'staff') then
    new.permissions := array[
      'VERIFY_LIST_VIEW', 'COMMENT_MANAGE', 'PARTY_MANAGE'
    ];
  end if;
  return new;
end;
$$ language plpgsql;

create trigger trigger_sync_permissions
before insert or update of role on public.partner_member_permissions
for each row execute procedure public.sync_partner_member_permissions();

-- 가입 승인 시 자동화
create or replace function public.on_partner_application_approved()
returns trigger as $$
declare
  new_partner_id uuid;
begin
  if (old.status != 'approved' and new.status = 'approved') then
    insert into public.partners (name, introduction, address, contact_phone, contact_email, representative_name, biz_name, biz_number)
    values (new.brand_name, new.introduction, new.address, new.contact_phone, new.contact_email, new.representative_name, new.biz_name, new.biz_number)
    returning id into new_partner_id;

    insert into public.partner_settlements (partner_id, biz_type, biz_name, biz_number, representative_name, bank_name, account_number, account_holder, tax_email, biz_registration_path, bankbook_path)
    values (new_partner_id, new.biz_type, new.biz_name, new.biz_number, new.representative_name, new.bank_name, new.account_number, new.account_holder, new.tax_email, new.biz_registration_path, new.bankbook_path);

    insert into public.partner_member_permissions (partner_id, user_id, role)
    values (new_partner_id, new.user_id, 'owner');
  end if;
  return new;
end;
$$ language plpgsql;

create trigger trigger_partner_application_approved
after update on public.partner_applications
for each row execute procedure public.on_partner_application_approved();

-- 인증 승인 트리거
create or replace function public.on_verification_approved_snapshot()
returns trigger as $$
begin
  if (old.status != 'approved' and new.status = 'approved') then
    insert into public.partner_verified_users (partner_id, user_id, verification_id, verified_snapshot, verified_at)
    values (new.partner_id, new.user_id, new.verification_id, new.claim_snapshot, now())
    on conflict (partner_id, user_id, verification_id) 
    do update set verified_snapshot = excluded.verified_snapshot, verified_at = now();
  end if;
  return new;
end;
$$ language plpgsql;

create trigger trigger_verification_approved_snapshot
after update on public.verification_requests
for each row execute procedure public.on_verification_approved_snapshot();

-- 17. Storage 설정 --
insert into storage.buckets (id, name, public)
values ('verification-proofs', 'verification-proofs', false) on conflict (id) do nothing;
insert into storage.buckets (id, name, public)
values ('partner-proofs', 'partner-proofs', false) on conflict (id) do nothing;

create policy "Allow Authenticated" on storage.objects for all using (auth.role() = 'authenticated') with check (auth.role() = 'authenticated');

-- 1. Enum 타입 정의
create type public.gender as enum ('male', 'female');
create type public.partner_role as enum ('owner', 'manager', 'staff');
create type public.verification_status as enum ('pending', 'approved', 'rejected');
create type public.verification_category as enum ('career', 'asset', 'marriage', 'academic', 'vehicle', 'etc');

-- 2. 사용자 프로필 테이블 (공통)
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
  company_name text,
  display_company_name text,
  is_job_verified boolean default false,
  is_super_admin boolean default false,
  created_at timestamp with time zone default now(),
  updated_at timestamp with time zone default now()
);

-- 3. 파트너(매장) 테이블
create table public.partners (
  id uuid default gen_random_uuid() primary key,
  name text not null,
  business_number text unique,
  address text,
  contact_phone text,
  is_active boolean default true,
  created_at timestamp with time zone default now(),
  updated_at timestamp with time zone default now()
);

-- 4. 파트너 멤버(직원) 테이블
create table public.partner_members (
  id uuid default gen_random_uuid() primary key,
  partner_id uuid references public.partners(id) on delete cascade not null,
  user_id uuid references auth.users(id) on delete cascade not null,
  role partner_role default 'staff' not null,
  joined_at timestamp with time zone default now(),
  unique(partner_id, user_id)
);

-- 5. 통합 인증 요청 테이블
create table public.verification_requests (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references auth.users(id) on delete cascade not null,
  category verification_category not null,
  claim_data jsonb not null,
  proof_images text[] not null,
  status verification_status default 'pending',
  rejection_reason text,
  verified_at timestamp with time zone,
  reviewer_id uuid references auth.users(id),
  created_at timestamp with time zone default now(),
  updated_at timestamp with time zone default now()
);

-- 6. 사용자 스펙/뱃지 테이블
create table public.user_specs (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references auth.users(id) on delete cascade not null,
  category verification_category not null,
  display_text text not null,
  spec_data jsonb,
  created_at timestamp with time zone default now(),
  updated_at timestamp with time zone default now(),
  unique(user_id, category)
);

-- 7. [보안 해제] DB 테이블 RLS 비활성화 (개발 편의)
alter table public.user_profiles disable row level security;
alter table public.partners disable row level security;
alter table public.partner_members disable row level security;
alter table public.verification_requests disable row level security;
alter table public.user_specs disable row level security;

-- 8. 트리거 및 함수 설정 --

create or replace function public.handle_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

create trigger set_user_profiles_updated_at before update on public.user_profiles for each row execute procedure public.handle_updated_at();
create trigger set_partners_updated_at before update on public.partners for each row execute procedure public.handle_updated_at();
create trigger set_verification_requests_updated_at before update on public.verification_requests for each row execute procedure public.handle_updated_at();
create trigger set_user_specs_updated_at before update on public.user_specs for each row execute procedure public.handle_updated_at();

-- 인증 승인 처리 트리거
create or replace function public.on_verification_approved()
returns trigger as $$
declare
  v_display_text text;
begin
  if (old.status != 'approved' and new.status = 'approved') then
    v_display_text := coalesce(new.claim_data->>'display_name', new.claim_data->>'display_text', 'Verified');
    if (new.category = 'career') then
      update public.user_profiles
      set 
        company_name = new.claim_data->>'company_name',
        display_company_name = new.claim_data->>'display_name',
        is_job_verified = true,
        updated_at = now()
      where id = new.user_id;
    end if;
    insert into public.user_specs (user_id, category, display_text, spec_data)
    values (new.user_id, new.category, v_display_text, new.claim_data)
    on conflict (user_id, category) 
    do update set 
      display_text = excluded.display_text,
      spec_data = excluded.spec_data,
      updated_at = now();
    new.verified_at = now();
  end if;
  return new;
end;
$$ language plpgsql;

create trigger trigger_verification_approved
before update on public.verification_requests
for each row execute procedure public.on_verification_approved();

-- 9. Storage 설정 (Private 유지 + Signed URL 접근) --
insert into storage.buckets (id, name, public)
values ('verification-proofs', 'verification-proofs', false) -- 다시 Private으로 변경
on conflict (id) do update set public = false;

-- Storage는 최소한의 보안 유지를 위해 정책 설정
-- 모든 인증된 사용자가 업로드/조회 가능하도록 설정 (Signed URL 생성을 위함)
create policy "Authenticated Access" on storage.objects for all using (auth.role() = 'authenticated') with check (auth.role() = 'authenticated');
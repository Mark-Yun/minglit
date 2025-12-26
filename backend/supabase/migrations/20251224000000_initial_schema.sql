-- 1. Enum 타입 정의
create type public.gender as enum ('male', 'female');
create type public.partner_role as enum ('owner', 'manager', 'staff');
create type public.verification_status as enum ('pending', 'approved', 'rejected', 'needs_correction', 'resubmitted');
create type public.verification_category as enum ('career', 'asset', 'marriage', 'academic', 'vehicle', 'etc');

-- 2. 사용자 프로필 테이블 (기본 정보)
create table public.user_profiles (
  id uuid references auth.users on delete cascade primary key,
  username text unique,
  name text,
  phone_number text unique,
  birth_date date,
  gender gender,
  is_verified boolean default false, -- 본인인증 여부
  ci text,
  di text unique,
  is_super_admin boolean default false,
  created_at timestamp with time zone default now(),
  updated_at timestamp with time zone default now()
);

-- 3. 파트너(매장/법인) 테이블
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

-- 5. 인증 항목 마스터 테이블
create table public.verifications (
  id uuid default gen_random_uuid() primary key,
  category verification_category not null,
  title text not null,
  description text,
  required_docs jsonb, -- 필요한 서류 안내
  partner_id uuid references public.partners(id) on delete cascade, -- NULL이면 공통, 값이 있으면 파트너 전용
  created_at timestamp with time zone default now()
);

-- 6. 유저별 최신 인증 데이터 (원본)
create table public.user_verifications (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references auth.users(id) on delete cascade not null,
  verification_id uuid references public.verifications(id) on delete cascade not null,
  claim_data jsonb not null, -- 제출 데이터
  proof_images text[] not null, -- Storage 경로들
  updated_at timestamp with time zone default now(),
  unique(user_id, verification_id)
);

-- 7. 인증 심사 요청 테이블 (심사 프로세스)
create table public.verification_requests (
  id uuid default gen_random_uuid() primary key,
  partner_id uuid references public.partners(id) on delete cascade not null,
  user_id uuid references auth.users(id) on delete cascade not null,
  verification_id uuid references public.verifications(id) on delete cascade not null,
  status verification_status default 'pending' not null,
  claim_snapshot jsonb not null, -- 요청 시점의 데이터 스냅샷
  created_at timestamp with time zone default now(),
  updated_at timestamp with time zone default now()
);

-- 8. 심사 코멘트 (소통)
create table public.verification_comments (
  id uuid default gen_random_uuid() primary key,
  request_id uuid references public.verification_requests(id) on delete cascade not null,
  author_id uuid references auth.users(id) not null,
  content jsonb not null, -- 텍스트뿐만 아니라 다양한 데이터 지원
  created_at timestamp with time zone default now()
);

-- 9. 파트너별 최종 승인 결과 테이블 (최종 스냅샷 보관소)
create table public.partner_verified_users (
  partner_id uuid references public.partners(id) on delete cascade not null,
  user_id uuid references auth.users(id) on delete cascade not null,
  verification_id uuid references public.verifications(id) on delete cascade not null,
  verified_snapshot jsonb not null, -- 승인 시점의 데이터 영구 보존
  verified_at timestamp with time zone default now(),
  primary key (partner_id, user_id, verification_id)
);

-- 10. 파티 테이블
create table public.parties (
  id uuid default gen_random_uuid() primary key,
  partner_id uuid references public.partners(id) on delete cascade not null,
  title text not null,
  required_verification_ids uuid[] not null, -- 필요한 인증 ID 배열
  created_at timestamp with time zone default now(),
  updated_at timestamp with time zone default now()
);

-- 11. [보안] RLS 설정 (개발 편의를 위해 일단 비활성화)
alter table public.user_profiles disable row level security;
alter table public.partners disable row level security;
alter table public.partner_members disable row level security;
alter table public.verifications disable row level security;
alter table public.user_verifications disable row level security;
alter table public.verification_requests disable row level security;
alter table public.verification_comments disable row level security;
alter table public.partner_verified_users disable row level security;
alter table public.parties disable row level security;

-- 12. 트리거 및 함수 설정 --

-- 업데이트 시간 자동 갱신 함수
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
create trigger set_parties_updated_at before update on public.parties for each row execute procedure public.handle_updated_at();

-- [핵심] 인증 승인 시 최종 결과 테이블로 스냅샷 복사 트리거
create or replace function public.on_verification_approved_snapshot()
returns trigger as $$
begin
  -- 상태가 'approved'로 변경될 때만 동작
  if (old.status != 'approved' and new.status = 'approved') then
    insert into public.partner_verified_users (partner_id, user_id, verification_id, verified_snapshot, verified_at)
    values (new.partner_id, new.user_id, new.verification_id, new.claim_snapshot, now())
    on conflict (partner_id, user_id, verification_id) 
    do update set 
      verified_snapshot = excluded.verified_snapshot,
      verified_at = now();
  end if;
  return new;
end;
$$ language plpgsql;

create trigger trigger_verification_approved_snapshot
after update on public.verification_requests
for each row execute procedure public.on_verification_approved_snapshot();

-- 13. Storage 설정 --
insert into storage.buckets (id, name, public)
values ('verification-proofs', 'verification-proofs', false)
on conflict (id) do nothing;

-- Storage 정책 (인증된 사용자 모두 허용 - 개발용)
create policy "Allow Authenticated" on storage.objects for all using (auth.role() = 'authenticated') with check (auth.role() = 'authenticated');

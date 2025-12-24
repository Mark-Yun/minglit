-- 1. Enum 타입 정의
create type public.gender as enum ('male', 'female');
create type public.partner_role as enum ('owner', 'manager', 'staff');

-- 2. 사용자 프로필 테이블 (공통)
create table public.user_profiles (
  id uuid references auth.users on delete cascade primary key,
  email text,
  username text unique,
  name text,
  phone_number text unique,
  birth_date date,
  gender gender,
  is_verified boolean default false,
  ci text, -- 연계정보 (외부 본인인증 키)
  di text unique, -- 중복가입확인정보 (1인 1계정 방지)
  avatar_url text,
  is_super_admin boolean default false, -- 시스템 관리자 여부
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
  user_id uuid references public.user_profiles(id) on delete cascade not null,
  role partner_role default 'staff' not null,
  joined_at timestamp with time zone default now(),
  unique(partner_id, user_id)
);

-- 5. RLS (Row Level Security) 설정 --

-- user_profiles 정책
alter table public.user_profiles enable row level security;
create policy "Users can view their own profile" on public.user_profiles for select using (auth.uid() = id);
create policy "Users can update their own profile" on public.user_profiles for update using (auth.uid() = id);
create policy "System can insert profiles" on public.user_profiles for insert with check (auth.uid() = id);

-- partners 정책
alter table public.partners enable row level security;
-- 파트너 정보는 해당 파트너 소속 멤버만 볼 수 있음
create policy "Members can view their own partner info" on public.partners for select 
  using (exists (select 1 from public.partner_members where partner_id = public.partners.id and user_id = auth.uid()));

-- partner_members 정책
alter table public.partner_members enable row level security;
create policy "Members can view their own membership" on public.partner_members for select using (user_id = auth.uid());
create policy "Owners/Managers can view all members in their partner" on public.partner_members for select
  using (exists (select 1 from public.partner_members where partner_id = public.partner_members.partner_id and user_id = auth.uid() and role in ('owner', 'manager')));

-- 6. 트리거: 업데이트 시간 자동 갱신 함수
create or replace function public.handle_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

-- 트리거 적용
create trigger set_user_profiles_updated_at before update on public.user_profiles for each row execute procedure public.handle_updated_at();
create trigger set_partners_updated_at before update on public.partners for each row execute procedure public.handle_updated_at();

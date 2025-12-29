-- Trigger: Auto Create User Profile on SignUp
-- auth.users에 insert가 발생하면, public.user_profiles에도 기본값을 insert 한다.
-- Security Definer: 이 함수는 정의한 사람(postgres admin)의 권한으로 실행되므로 RLS를 우회해서 insert 가능.

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  insert into public.user_profiles (
    id, 
    username, 
    name, 
    phone_number, 
    gender, 
    birth_date, 
    is_verified, 
    created_at, 
    updated_at
  )
  values (
    new.id,
    coalesce(
      new.raw_user_meta_data->>'username', 
      split_part(new.email, '@', 1) || '_' || substr(new.id::text, 1, 4)
    ),
    coalesce(new.raw_user_meta_data->>'name', 'New User'),
    coalesce(new.raw_user_meta_data->>'phone_number', new.phone), -- auth.users.phone도 참조
    (new.raw_user_meta_data->>'gender')::public.gender,
    (new.raw_user_meta_data->>'birth_date')::date,
    coalesce((new.raw_user_meta_data->>'is_verified')::boolean, false),
    now(),
    now()
  );
  return new;
end;
$$;

-- 기존 트리거가 있다면 삭제하고 재생성 (멱등성 보장)
drop trigger if exists on_auth_user_created on auth.users;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- 01. CORE: Extensions, Enums, Utils

-- Ensure extensions schema is in search_path for all subsequent migrations
alter database postgres set search_path to public, extensions;
set search_path to public, extensions;

-- 1. Extensions
create extension if not exists postgis;
create extension if not exists moddatetime schema extensions;
create extension if not exists vector schema extensions;
create extension if not exists supabase_vault cascade;
create extension if not exists pgmq cascade;
create extension if not exists pg_cron;
create extension if not exists pg_net;

-- 2. Enum Types
create type public.gender as enum ('male', 'female');
create type public.partner_role as enum ('owner', 'manager', 'staff');
create type public.verification_status as enum ('pending', 'approved', 'rejected', 'needs_correction', 'cancelled');
create type public.verification_category as enum ('career', 'asset', 'marriage', 'academic', 'vehicle', 'etc');
create type public.partner_application_status as enum ('pending', 'approved', 'rejected', 'needs_correction');
create type public.business_type as enum ('individual', 'corporate');
create type public.user_action_type as enum ('view', 'like', 'dislike', 'purchase');

-- Pipeline Enums
create type public.event_queue_name as enum ('q_global_events', 'q_notifications', 'q_vectors');
create type public.event_type_name as enum ('party_created', 'user_interaction');

-- 3. Utility Functions
create or replace function public.handle_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

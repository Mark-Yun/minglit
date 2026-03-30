-- Adds ticket signing public key to system_settings and exposes it via RPC.
-- The corresponding private key must be stored in Supabase Vault
-- and used by the ticket-minting Edge Function.

-- 1. Insert ticket signing public key placeholder
-- Replace the placeholder value with the actual Base64-encoded Ed25519 public key
-- after generating the key pair for the ticket-minting Edge Function.
insert into public.system_settings (key, value, description)
values (
  'ticket_signing_public_key',
  '"FILL_THIS_WITH_BASE64_ED25519_PUBLIC_KEY"'::jsonb,
  'Ed25519 public key (Base64) for ticket QR signature verification'
)
on conflict (key) do nothing;

-- 2. RPC function to serve the public key to authenticated users
create or replace function public.get_ticket_public_key()
returns text
language sql
stable
security definer
set search_path = public
as $$
  select value #>> '{}'
  from public.system_settings
  where key = 'ticket_signing_public_key';
$$;

-- Grant execute to authenticated users (partners need it for check-in)
grant execute on function public.get_ticket_public_key() to authenticated;

-- Add metadata jsonb column to parties and events tables
-- Extensible key-value settings for both tables

alter table public.parties
add column metadata jsonb default '{}'::jsonb;

comment on column public.parties.metadata is
  'Extensible key-value settings. Keys defined in Dart MetadataKey registry.';

alter table public.events
add column metadata jsonb default '{}'::jsonb;

comment on column public.events.metadata is
  'Extensible key-value settings. Keys defined in Dart MetadataKey registry.';

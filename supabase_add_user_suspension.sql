-- Adds a persistent suspension flag for admin customer management
-- Run in Supabase SQL editor.

alter table public.users
add column if not exists is_suspended boolean not null default false;

create index if not exists users_is_suspended_idx on public.users(is_suspended);

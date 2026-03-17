create extension if not exists pgcrypto;

create table if not exists public.employees (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  name text not null,
  nip text not null,
  position text not null,
  department text not null,
  email text not null,
  phone text not null default '',
  address text not null default '',
  is_active boolean not null default true,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create unique index if not exists employees_user_nip_idx
  on public.employees (user_id, nip);

alter table public.employees enable row level security;

create policy "users_can_select_own_employees"
on public.employees
for select
to authenticated, anon
using (auth.uid() = user_id);

create policy "users_can_insert_own_employees"
on public.employees
for insert
to authenticated, anon
with check (auth.uid() = user_id);

create policy "users_can_update_own_employees"
on public.employees
for update
to authenticated, anon
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

create policy "users_can_delete_own_employees"
on public.employees
for delete
to authenticated, anon
using (auth.uid() = user_id);

create extension if not exists pgcrypto;

create table if not exists public.employees (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  name text not null,
  photo_url text not null default '',
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

alter table public.employees
  add column if not exists photo_url text not null default '';

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'employee-photos',
  'employee-photos',
  true,
  5242880,
  array['image/jpeg', 'image/png', 'image/webp']
)
on conflict (id) do nothing;

drop policy if exists "employee_photos_public_read"
on storage.objects;

create policy "employee_photos_public_read"
on storage.objects
for select
to public
using (bucket_id = 'employee-photos');

drop policy if exists "employee_photos_owner_insert"
on storage.objects;

create policy "employee_photos_owner_insert"
on storage.objects
for insert
to authenticated, anon
with check (
  bucket_id = 'employee-photos'
  and auth.uid()::text = (storage.foldername(name))[1]
);

drop policy if exists "employee_photos_owner_update"
on storage.objects;

create policy "employee_photos_owner_update"
on storage.objects
for update
to authenticated, anon
using (
  bucket_id = 'employee-photos'
  and auth.uid()::text = (storage.foldername(name))[1]
)
with check (
  bucket_id = 'employee-photos'
  and auth.uid()::text = (storage.foldername(name))[1]
);

drop policy if exists "employee_photos_owner_delete"
on storage.objects;

create policy "employee_photos_owner_delete"
on storage.objects
for delete
to authenticated, anon
using (
  bucket_id = 'employee-photos'
  and auth.uid()::text = (storage.foldername(name))[1]
);

create unique index if not exists employees_user_nip_idx
  on public.employees (user_id, nip);

alter table public.employees enable row level security;

create or replace function public.employee_dashboard_totals()
returns jsonb
language sql
security definer
set search_path = public
as $$
  select jsonb_build_object(
    'total_employees', count(*),
    'active_employees', count(*) filter (where is_active),
    'inactive_employees', count(*) filter (where not is_active)
  )
  from public.employees;
$$;

grant execute on function public.employee_dashboard_totals() to anon, authenticated;

create or replace function public.employee_users_list()
returns jsonb
language sql
security definer
set search_path = public
as $$
  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'user_id', user_id,
        'total_employees', total_employees,
        'last_input_at', last_input_at
      )
      order by last_input_at desc, user_id
    ),
    '[]'::jsonb
  )
  from (
    select
      user_id::text as user_id,
      count(*)::int as total_employees,
      max(created_at) as last_input_at
    from public.employees
    group by user_id
  ) employee_users;
$$;

grant execute on function public.employee_users_list() to anon, authenticated;

drop policy if exists "users_can_select_own_employees"
on public.employees;

create policy "users_can_select_own_employees"
on public.employees
for select
to authenticated, anon
using (auth.uid() = user_id);

drop policy if exists "users_can_insert_own_employees"
on public.employees;

create policy "users_can_insert_own_employees"
on public.employees
for insert
to authenticated, anon
with check (auth.uid() = user_id);

drop policy if exists "users_can_update_own_employees"
on public.employees;

create policy "users_can_update_own_employees"
on public.employees
for update
to authenticated, anon
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

drop policy if exists "users_can_delete_own_employees"
on public.employees;

create policy "users_can_delete_own_employees"
on public.employees
for delete
to authenticated, anon
using (auth.uid() = user_id);

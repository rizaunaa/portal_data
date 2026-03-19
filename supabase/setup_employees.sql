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

create table if not exists public.employee_data_access_requests (
  id uuid primary key default gen_random_uuid(),
  requester_user_id uuid not null references auth.users (id) on delete cascade,
  target_user_id uuid not null references auth.users (id) on delete cascade,
  status text not null default 'pending' check (status in ('pending', 'approved', 'rejected')),
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  responded_at timestamptz
);

create unique index if not exists employee_data_access_requests_unique_pair_idx
  on public.employee_data_access_requests (requester_user_id, target_user_id);

alter table public.employees enable row level security;
alter table public.employee_data_access_requests enable row level security;

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
        'last_input_at', last_input_at,
        'request_status', request_status,
        'can_view_data', can_view_data,
        'is_current_user', is_current_user
      )
      order by last_input_at desc, user_id
    ),
    '[]'::jsonb
  )
  from (
    select
      user_id::text as user_id,
      count(*)::int as total_employees,
      max(created_at) as last_input_at,
      (
        select status
        from public.employee_data_access_requests requests
        where requests.requester_user_id = auth.uid()
          and requests.target_user_id = employees.user_id
        limit 1
      ) as request_status,
      exists (
        select 1
        from public.employee_data_access_requests requests
        where requests.requester_user_id = auth.uid()
          and requests.target_user_id = employees.user_id
          and requests.status = 'approved'
      ) as can_view_data,
      auth.uid() = employees.user_id as is_current_user
    from public.employees employees
    group by user_id
  ) employee_users;
$$;

grant execute on function public.employee_users_list() to anon, authenticated;

create or replace function public.request_employee_data_access(target_user_id_input text)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  current_user_id uuid;
  target_user_id_uuid uuid;
begin
  current_user_id := auth.uid();
  if current_user_id is null then
    raise exception 'User belum login.';
  end if;

  target_user_id_uuid := target_user_id_input::uuid;
  if target_user_id_uuid = current_user_id then
    raise exception 'Tidak bisa meminta akses ke user sendiri.';
  end if;

  insert into public.employee_data_access_requests (
    requester_user_id,
    target_user_id,
    status,
    created_at,
    updated_at,
    responded_at
  )
  values (
    current_user_id,
    target_user_id_uuid,
    'pending',
    timezone('utc', now()),
    timezone('utc', now()),
    null
  )
  on conflict (requester_user_id, target_user_id)
  do update set
    status = 'pending',
    updated_at = timezone('utc', now()),
    responded_at = null;
end;
$$;

grant execute on function public.request_employee_data_access(text) to anon, authenticated;

create or replace function public.incoming_employee_access_requests()
returns jsonb
language sql
security definer
set search_path = public
as $$
  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'id', id,
        'requester_user_id', requester_user_id::text,
        'target_user_id', target_user_id::text,
        'status', status,
        'created_at', created_at
      )
      order by created_at desc
    ),
    '[]'::jsonb
  )
  from public.employee_data_access_requests
  where target_user_id = auth.uid()
    and status = 'pending';
$$;

grant execute on function public.incoming_employee_access_requests() to anon, authenticated;

create or replace function public.respond_employee_data_access_request(
  request_id_input uuid,
  approve_input boolean
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  update public.employee_data_access_requests
  set
    status = case when approve_input then 'approved' else 'rejected' end,
    updated_at = timezone('utc', now()),
    responded_at = timezone('utc', now())
  where id = request_id_input
    and target_user_id = auth.uid();

  if not found then
    raise exception 'Request tidak ditemukan atau tidak bisa diproses.';
  end if;
end;
$$;

grant execute on function public.respond_employee_data_access_request(uuid, boolean) to anon, authenticated;

create or replace function public.shared_employee_data(owner_user_id_input text)
returns setof public.employees
language sql
security definer
set search_path = public
as $$
  select employees.*
  from public.employees employees
  where employees.user_id = owner_user_id_input::uuid
    and exists (
      select 1
      from public.employee_data_access_requests requests
      where requests.requester_user_id = auth.uid()
        and requests.target_user_id = owner_user_id_input::uuid
        and requests.status = 'approved'
    );
$$;

grant execute on function public.shared_employee_data(text) to anon, authenticated;

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

drop policy if exists "users_can_manage_own_access_requests"
on public.employee_data_access_requests;

create policy "users_can_manage_own_access_requests"
on public.employee_data_access_requests
for all
to authenticated, anon
using (
  auth.uid() = requester_user_id
  or auth.uid() = target_user_id
)
with check (
  auth.uid() = requester_user_id
  or auth.uid() = target_user_id
);

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

create table if not exists public.inventory_items (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  photo_url text not null default '',
  item_name text not null,
  item_code text not null,
  category text not null default '',
  brand text not null default '',
  quantity integer not null default 0 check (quantity >= 0),
  unit text not null default 'unit',
  item_condition text not null default 'baik',
  location text not null default '',
  notes text not null default '',
  is_active boolean not null default true,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  email text not null default '',
  full_name text not null default '',
  username text not null,
  role text not null default 'staff' check (role in ('admin', 'staff')),
  photo_url text not null default '',
  settings jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

alter table public.employees
  add column if not exists photo_url text not null default '';

alter table public.inventory_items
  add column if not exists photo_url text not null default '';

alter table public.profiles
  add column if not exists email text not null default '';

alter table public.profiles
  add column if not exists full_name text not null default '';

alter table public.profiles
  add column if not exists username text not null default '';

alter table public.profiles
  add column if not exists role text not null default 'staff';

alter table public.profiles
  add column if not exists photo_url text not null default '';

alter table public.profiles
  add column if not exists settings jsonb not null default '{}'::jsonb;

alter table public.profiles
  add column if not exists updated_at timestamptz not null default timezone('utc', now());

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

create unique index if not exists inventory_items_user_code_idx
  on public.inventory_items (user_id, item_code);

create unique index if not exists profiles_username_idx
  on public.profiles (lower(username));

create or replace function public.validate_employee_uniqueness()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if exists (
    select 1
    from public.employees employees
    where employees.user_id = new.user_id
      and employees.id <> coalesce(new.id, '00000000-0000-0000-0000-000000000000'::uuid)
      and btrim(employees.nip) = btrim(new.nip)
  ) then
    raise exception 'NIP sudah terdaftar. Gunakan NIP yang berbeda.';
  end if;

  if exists (
    select 1
    from public.employees employees
    where employees.user_id = new.user_id
      and employees.id <> coalesce(new.id, '00000000-0000-0000-0000-000000000000'::uuid)
      and lower(btrim(employees.email)) = lower(btrim(new.email))
  ) then
    raise exception 'Email sudah terdaftar. Gunakan email yang berbeda.';
  end if;

  if btrim(coalesce(new.phone, '')) <> ''
    and exists (
      select 1
      from public.employees employees
      where employees.user_id = new.user_id
        and employees.id <> coalesce(new.id, '00000000-0000-0000-0000-000000000000'::uuid)
        and btrim(coalesce(employees.phone, '')) = btrim(new.phone)
    ) then
    raise exception 'Nomor HP sudah terdaftar. Gunakan nomor HP yang berbeda.';
  end if;

  return new;
end;
$$;

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

create table if not exists public.portal_realtime_events (
  id bigint generated always as identity primary key,
  topic text not null,
  action text not null,
  source_table text not null,
  actor_user_id uuid,
  created_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.global_chat_messages (
  id uuid primary key default gen_random_uuid(),
  sender_user_id uuid not null references auth.users (id) on delete cascade,
  sender_name text not null,
  message text not null check (char_length(btrim(message)) > 0),
  created_at timestamptz not null default timezone('utc', now())
);

create index if not exists global_chat_messages_created_at_idx
  on public.global_chat_messages (created_at asc);

alter table public.employees enable row level security;
alter table public.inventory_items enable row level security;
alter table public.profiles enable row level security;
alter table public.employee_data_access_requests enable row level security;
alter table public.portal_realtime_events enable row level security;
alter table public.global_chat_messages enable row level security;

do $$
begin
  if not exists (
    select 1
    from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'employees'
  ) then
    alter publication supabase_realtime add table public.employees;
  end if;
end;
$$;

do $$
begin
  if not exists (
    select 1
    from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'global_chat_messages'
  ) then
    alter publication supabase_realtime add table public.global_chat_messages;
  end if;
end;
$$;

do $$
begin
  if not exists (
    select 1
    from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'inventory_items'
  ) then
    alter publication supabase_realtime add table public.inventory_items;
  end if;
end;
$$;

do $$
begin
  if not exists (
    select 1
    from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'employee_data_access_requests'
  ) then
    alter publication supabase_realtime add table public.employee_data_access_requests;
  end if;
end;
$$;

do $$
begin
  if not exists (
    select 1
    from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'portal_realtime_events'
  ) then
    alter publication supabase_realtime add table public.portal_realtime_events;
  end if;
end;
$$;

create or replace function public.emit_portal_realtime_event()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  actor_id uuid;
  action_name text;
begin
  action_name := tg_op;

  if tg_table_name = 'employees' then
    actor_id := coalesce(new.user_id, old.user_id);
  elsif tg_table_name = 'inventory_items' then
    actor_id := coalesce(new.user_id, old.user_id);
  elsif tg_table_name = 'employee_data_access_requests' then
    actor_id := coalesce(new.requester_user_id, old.requester_user_id);
  else
    actor_id := null;
  end if;

  insert into public.portal_realtime_events (
    topic,
    action,
    source_table,
    actor_user_id
  )
  values (
    'portal_sync',
    lower(action_name),
    tg_table_name,
    actor_id
  );

  if tg_op = 'DELETE' then
    return old;
  end if;

  return new;
end;
$$;

drop trigger if exists employees_emit_portal_realtime_event
on public.employees;

create trigger employees_emit_portal_realtime_event
after insert or update or delete on public.employees
for each row execute function public.emit_portal_realtime_event();

drop trigger if exists inventory_items_emit_portal_realtime_event
on public.inventory_items;

create trigger inventory_items_emit_portal_realtime_event
after insert or update or delete on public.inventory_items
for each row execute function public.emit_portal_realtime_event();

drop trigger if exists employees_validate_uniqueness
on public.employees;

create trigger employees_validate_uniqueness
before insert or update on public.employees
for each row execute function public.validate_employee_uniqueness();

drop trigger if exists employee_access_emit_portal_realtime_event
on public.employee_data_access_requests;

create trigger employee_access_emit_portal_realtime_event
after insert or update or delete on public.employee_data_access_requests
for each row execute function public.emit_portal_realtime_event();

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

create or replace function public.cancel_employee_data_access_request(target_user_id_input text)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  current_user_id uuid;
begin
  current_user_id := auth.uid();
  if current_user_id is null then
    raise exception 'User belum login.';
  end if;

  delete from public.employee_data_access_requests
  where requester_user_id = current_user_id
    and target_user_id = target_user_id_input::uuid
    and status = 'pending';
end;
$$;

grant execute on function public.cancel_employee_data_access_request(text) to anon, authenticated;

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
        'created_at', created_at,
        'responded_at', responded_at
      )
      order by coalesce(responded_at, created_at) desc, created_at desc
    ),
    '[]'::jsonb
  )
  from public.employee_data_access_requests
  where target_user_id = auth.uid();
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

create or replace function public.revoke_employee_data_access_decision(
  request_id_input uuid
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  delete from public.employee_data_access_requests
  where id = request_id_input
    and target_user_id = auth.uid()
    and status in ('approved', 'rejected');

  if not found then
    raise exception 'Keputusan akses tidak ditemukan atau tidak bisa dibatalkan.';
  end if;
end;
$$;

grant execute on function public.revoke_employee_data_access_decision(uuid) to anon, authenticated;

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

drop policy if exists "users_can_select_own_inventory_items"
on public.inventory_items;

create policy "users_can_select_own_inventory_items"
on public.inventory_items
for select
to authenticated, anon
using (auth.uid() = user_id);

drop policy if exists "users_can_select_own_profile"
on public.profiles;

create policy "users_can_select_own_profile"
on public.profiles
for select
to authenticated, anon
using (auth.uid() = id);

drop policy if exists "users_can_insert_own_employees"
on public.employees;

create policy "users_can_insert_own_employees"
on public.employees
for insert
to authenticated, anon
with check (auth.uid() = user_id);

drop policy if exists "users_can_insert_own_inventory_items"
on public.inventory_items;

create policy "users_can_insert_own_inventory_items"
on public.inventory_items
for insert
to authenticated, anon
with check (auth.uid() = user_id);

drop policy if exists "users_can_insert_own_profile"
on public.profiles;

create policy "users_can_insert_own_profile"
on public.profiles
for insert
to authenticated, anon
with check (auth.uid() = id);

drop policy if exists "users_can_update_own_employees"
on public.employees;

create policy "users_can_update_own_employees"
on public.employees
for update
to authenticated, anon
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

drop policy if exists "users_can_update_own_inventory_items"
on public.inventory_items;

create policy "users_can_update_own_inventory_items"
on public.inventory_items
for update
to authenticated, anon
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

drop policy if exists "users_can_update_own_profile"
on public.profiles;

create policy "users_can_update_own_profile"
on public.profiles
for update
to authenticated, anon
using (auth.uid() = id)
with check (auth.uid() = id);

drop policy if exists "users_can_delete_own_employees"
on public.employees;

create policy "users_can_delete_own_employees"
on public.employees
for delete
to authenticated, anon
using (auth.uid() = user_id);

drop policy if exists "users_can_delete_own_inventory_items"
on public.inventory_items;

create policy "users_can_delete_own_inventory_items"
on public.inventory_items
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

drop policy if exists "portal_realtime_events_select_all"
on public.portal_realtime_events;

create policy "portal_realtime_events_select_all"
on public.portal_realtime_events
for select
to authenticated, anon
using (true);

drop policy if exists "global_chat_messages_select_all"
on public.global_chat_messages;

create policy "global_chat_messages_select_all"
on public.global_chat_messages
for select
to authenticated, anon
using (true);

drop policy if exists "global_chat_messages_insert_own"
on public.global_chat_messages;

create policy "global_chat_messages_insert_own"
on public.global_chat_messages
for insert
to authenticated, anon
with check (
  auth.uid() = sender_user_id
  and char_length(btrim(message)) > 0
);

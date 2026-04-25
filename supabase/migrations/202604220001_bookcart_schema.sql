create extension if not exists pgcrypto;

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = timezone('utc', now());
  return new;
end;
$$;

create table if not exists public.users (
  id uuid primary key references auth.users (id) on delete cascade,
  name text not null default 'Book Cart User',
  phone text not null default '',
  email text not null default '',
  location text not null default 'Kolkata, West Bengal',
  latitude double precision,
  longitude double precision,
  location_updated_at timestamptz,
  profile_image_base64 text,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.books (
  id uuid primary key default gen_random_uuid(),
  image_base64 text,
  title text not null default '',
  author text not null default '',
  category text not null default '',
  price text not null default '',
  description text not null default '',
  seller_id uuid not null references public.users (id) on delete cascade,
  seller_name text not null default 'Seller',
  seller_email text not null default '',
  seller_phone text not null default '',
  seller_location text not null default 'Kolkata, West Bengal',
  seller_latitude double precision,
  seller_longitude double precision,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.chats (
  id text primary key,
  book_id uuid not null references public.books (id) on delete cascade,
  book_title text not null default 'Book listing',
  book_price text not null default '',
  buyer_id uuid not null references public.users (id) on delete cascade,
  seller_id uuid not null references public.users (id) on delete cascade,
  buyer_name text not null default 'Buyer',
  seller_name text not null default 'Seller',
  participant_ids uuid[] not null default '{}'::uuid[],
  last_message text not null default '',
  last_sender_id uuid references public.users (id) on delete set null,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.chat_messages (
  id uuid primary key default gen_random_uuid(),
  chat_id text not null references public.chats (id) on delete cascade,
  text text not null,
  sender_id uuid not null references public.users (id) on delete cascade,
  created_at timestamptz not null default timezone('utc', now())
);

create index if not exists books_created_at_idx
  on public.books (created_at desc);

create index if not exists books_seller_id_idx
  on public.books (seller_id);

create index if not exists chats_updated_at_idx
  on public.chats (updated_at desc);

create index if not exists chats_buyer_id_idx
  on public.chats (buyer_id);

create index if not exists chats_seller_id_idx
  on public.chats (seller_id);

create index if not exists chats_participant_ids_gin_idx
  on public.chats using gin (participant_ids);

create index if not exists chat_messages_chat_id_created_at_idx
  on public.chat_messages (chat_id, created_at);

drop trigger if exists users_set_updated_at on public.users;
create trigger users_set_updated_at
before update on public.users
for each row
execute function public.set_updated_at();

drop trigger if exists books_set_updated_at on public.books;
create trigger books_set_updated_at
before update on public.books
for each row
execute function public.set_updated_at();

drop trigger if exists chats_set_updated_at on public.chats;
create trigger chats_set_updated_at
before update on public.chats
for each row
execute function public.set_updated_at();

create or replace function public.sync_auth_user_to_public_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.users (
    id,
    name,
    phone,
    email,
    location,
    latitude,
    longitude,
    location_updated_at,
    profile_image_base64
  )
  values (
    new.id,
    coalesce(nullif(trim(new.raw_user_meta_data ->> 'name'), ''), 'Book Cart User'),
    coalesce(new.raw_user_meta_data ->> 'phone', ''),
    coalesce(new.email, ''),
    coalesce(
      nullif(trim(new.raw_user_meta_data ->> 'location'), ''),
      'Kolkata, West Bengal'
    ),
    nullif(new.raw_user_meta_data ->> 'latitude', '')::double precision,
    nullif(new.raw_user_meta_data ->> 'longitude', '')::double precision,
    nullif(new.raw_user_meta_data ->> 'locationUpdatedAt', '')::timestamptz,
    new.raw_user_meta_data ->> 'profileImageBase64'
  )
  on conflict (id) do update
  set
    name = excluded.name,
    phone = excluded.phone,
    email = excluded.email,
    location = excluded.location,
    latitude = excluded.latitude,
    longitude = excluded.longitude,
    location_updated_at = excluded.location_updated_at,
    profile_image_base64 = excluded.profile_image_base64,
    updated_at = timezone('utc', now());

  return new;
end;
$$;

drop trigger if exists on_auth_user_changed on auth.users;
create trigger on_auth_user_changed
after insert or update of email, raw_user_meta_data on auth.users
for each row
execute function public.sync_auth_user_to_public_user();

insert into storage.buckets (id, name, public)
values ('profile_images', 'profile_images', true)
on conflict (id) do update
set
  name = excluded.name,
  public = excluded.public;

alter table public.users enable row level security;
alter table public.books enable row level security;
alter table public.chats enable row level security;
alter table public.chat_messages enable row level security;

grant usage on schema public to authenticated;
grant select, insert, update, delete on public.users to authenticated;
grant select, insert, update, delete on public.books to authenticated;
grant select, insert, update, delete on public.chats to authenticated;
grant select, insert, update, delete on public.chat_messages to authenticated;

do $$
begin
  if not exists (
    select 1
    from pg_policies
    where schemaname = 'public'
      and tablename = 'users'
      and policyname = 'users_select_own'
  ) then
    create policy users_select_own
      on public.users
      for select
      to authenticated
      using (auth.uid() = id);
  end if;

  if not exists (
    select 1
    from pg_policies
    where schemaname = 'public'
      and tablename = 'users'
      and policyname = 'users_insert_own'
  ) then
    create policy users_insert_own
      on public.users
      for insert
      to authenticated
      with check (auth.uid() = id);
  end if;

  if not exists (
    select 1
    from pg_policies
    where schemaname = 'public'
      and tablename = 'users'
      and policyname = 'users_update_own'
  ) then
    create policy users_update_own
      on public.users
      for update
      to authenticated
      using (auth.uid() = id)
      with check (auth.uid() = id);
  end if;

  if not exists (
    select 1
    from pg_policies
    where schemaname = 'public'
      and tablename = 'users'
      and policyname = 'users_delete_own'
  ) then
    create policy users_delete_own
      on public.users
      for delete
      to authenticated
      using (auth.uid() = id);
  end if;

  if not exists (
    select 1
    from pg_policies
    where schemaname = 'public'
      and tablename = 'books'
      and policyname = 'books_select_authenticated'
  ) then
    create policy books_select_authenticated
      on public.books
      for select
      to authenticated
      using (true);
  end if;

  if not exists (
    select 1
    from pg_policies
    where schemaname = 'public'
      and tablename = 'books'
      and policyname = 'books_insert_own'
  ) then
    create policy books_insert_own
      on public.books
      for insert
      to authenticated
      with check (auth.uid() = seller_id);
  end if;

  if not exists (
    select 1
    from pg_policies
    where schemaname = 'public'
      and tablename = 'books'
      and policyname = 'books_update_own'
  ) then
    create policy books_update_own
      on public.books
      for update
      to authenticated
      using (auth.uid() = seller_id)
      with check (auth.uid() = seller_id);
  end if;

  if not exists (
    select 1
    from pg_policies
    where schemaname = 'public'
      and tablename = 'books'
      and policyname = 'books_delete_own'
  ) then
    create policy books_delete_own
      on public.books
      for delete
      to authenticated
      using (auth.uid() = seller_id);
  end if;

  if not exists (
    select 1
    from pg_policies
    where schemaname = 'public'
      and tablename = 'chats'
      and policyname = 'chats_select_participant'
  ) then
    create policy chats_select_participant
      on public.chats
      for select
      to authenticated
      using (auth.uid() = any(participant_ids));
  end if;

  if not exists (
    select 1
    from pg_policies
    where schemaname = 'public'
      and tablename = 'chats'
      and policyname = 'chats_insert_buyer'
  ) then
    create policy chats_insert_buyer
      on public.chats
      for insert
      to authenticated
      with check (
        auth.uid() = buyer_id
        and buyer_id <> seller_id
        and auth.uid() = any(participant_ids)
      );
  end if;

  if not exists (
    select 1
    from pg_policies
    where schemaname = 'public'
      and tablename = 'chats'
      and policyname = 'chats_update_participant'
  ) then
    create policy chats_update_participant
      on public.chats
      for update
      to authenticated
      using (auth.uid() = any(participant_ids))
      with check (auth.uid() = any(participant_ids));
  end if;

  if not exists (
    select 1
    from pg_policies
    where schemaname = 'public'
      and tablename = 'chat_messages'
      and policyname = 'chat_messages_select_participant'
  ) then
    create policy chat_messages_select_participant
      on public.chat_messages
      for select
      to authenticated
      using (
        exists (
          select 1
          from public.chats
          where chats.id = chat_messages.chat_id
            and auth.uid() = any(chats.participant_ids)
        )
      );
  end if;

  if not exists (
    select 1
    from pg_policies
    where schemaname = 'public'
      and tablename = 'chat_messages'
      and policyname = 'chat_messages_insert_sender'
  ) then
    create policy chat_messages_insert_sender
      on public.chat_messages
      for insert
      to authenticated
      with check (
        auth.uid() = sender_id
        and exists (
          select 1
          from public.chats
          where chats.id = chat_messages.chat_id
            and auth.uid() = any(chats.participant_ids)
        )
      );
  end if;
end
$$;

do $$
begin
  if not exists (
    select 1
    from pg_policies
    where schemaname = 'storage'
      and tablename = 'objects'
      and policyname = 'profile_images_select_own'
  ) then
    create policy profile_images_select_own
      on storage.objects
      for select
      to authenticated
      using (
        bucket_id = 'profile_images'
        and name like auth.uid()::text || '.%'
      );
  end if;

  if not exists (
    select 1
    from pg_policies
    where schemaname = 'storage'
      and tablename = 'objects'
      and policyname = 'profile_images_insert_own'
  ) then
    create policy profile_images_insert_own
      on storage.objects
      for insert
      to authenticated
      with check (
        bucket_id = 'profile_images'
        and name like auth.uid()::text || '.%'
      );
  end if;

  if not exists (
    select 1
    from pg_policies
    where schemaname = 'storage'
      and tablename = 'objects'
      and policyname = 'profile_images_update_own'
  ) then
    create policy profile_images_update_own
      on storage.objects
      for update
      to authenticated
      using (
        bucket_id = 'profile_images'
        and name like auth.uid()::text || '.%'
      )
      with check (
        bucket_id = 'profile_images'
        and name like auth.uid()::text || '.%'
      );
  end if;

  if not exists (
    select 1
    from pg_policies
    where schemaname = 'storage'
      and tablename = 'objects'
      and policyname = 'profile_images_delete_own'
  ) then
    create policy profile_images_delete_own
      on storage.objects
      for delete
      to authenticated
      using (
        bucket_id = 'profile_images'
        and name like auth.uid()::text || '.%'
      );
  end if;
end
$$;

create or replace function public.delete_my_account()
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  current_user_id uuid := auth.uid();
begin
  if current_user_id is null then
    raise exception 'Not authenticated';
  end if;

  delete from auth.users
  where id = current_user_id;
end;
$$;

revoke all on function public.delete_my_account() from public;
grant execute on function public.delete_my_account() to authenticated;

alter table public.users replica identity full;
alter table public.books replica identity full;
alter table public.chats replica identity full;
alter table public.chat_messages replica identity full;

do $$
begin
  if not exists (
    select 1
    from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'users'
  ) then
    alter publication supabase_realtime add table public.users;
  end if;

  if not exists (
    select 1
    from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'books'
  ) then
    alter publication supabase_realtime add table public.books;
  end if;

  if not exists (
    select 1
    from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'chats'
  ) then
    alter publication supabase_realtime add table public.chats;
  end if;

  if not exists (
    select 1
    from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'chat_messages'
  ) then
    alter publication supabase_realtime add table public.chat_messages;
  end if;
end
$$;

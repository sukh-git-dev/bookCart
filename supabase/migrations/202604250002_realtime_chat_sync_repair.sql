create or replace function public.sync_chat_from_message()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  update public.chats
  set
    last_message = new.text,
    last_sender_id = new.sender_id,
    updated_at = coalesce(new.created_at, timezone('utc', now()))
  where id = new.chat_id;

  return new;
end;
$$;

drop trigger if exists chat_messages_sync_chat on public.chat_messages;
create trigger chat_messages_sync_chat
after insert on public.chat_messages
for each row
execute function public.sync_chat_from_message();

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

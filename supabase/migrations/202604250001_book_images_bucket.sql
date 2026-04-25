insert into storage.buckets (id, name, public)
values ('book_images', 'book_images', true)
on conflict (id) do update
set
  name = excluded.name,
  public = excluded.public;

do $$
begin
  if not exists (
    select 1
    from pg_policies
    where schemaname = 'storage'
      and tablename = 'objects'
      and policyname = 'book_images_select_own'
  ) then
    create policy book_images_select_own
      on storage.objects
      for select
      to authenticated
      using (
        bucket_id = 'book_images'
        and name like auth.uid()::text || '.%'
      );
  end if;

  if not exists (
    select 1
    from pg_policies
    where schemaname = 'storage'
      and tablename = 'objects'
      and policyname = 'book_images_insert_own'
  ) then
    create policy book_images_insert_own
      on storage.objects
      for insert
      to authenticated
      with check (
        bucket_id = 'book_images'
        and name like auth.uid()::text || '.%'
      );
  end if;

  if not exists (
    select 1
    from pg_policies
    where schemaname = 'storage'
      and tablename = 'objects'
      and policyname = 'book_images_update_own'
  ) then
    create policy book_images_update_own
      on storage.objects
      for update
      to authenticated
      using (
        bucket_id = 'book_images'
        and name like auth.uid()::text || '.%'
      )
      with check (
        bucket_id = 'book_images'
        and name like auth.uid()::text || '.%'
      );
  end if;

  if not exists (
    select 1
    from pg_policies
    where schemaname = 'storage'
      and tablename = 'objects'
      and policyname = 'book_images_delete_own'
  ) then
    create policy book_images_delete_own
      on storage.objects
      for delete
      to authenticated
      using (
        bucket_id = 'book_images'
        and name like auth.uid()::text || '.%'
      );
  end if;
end
$$;

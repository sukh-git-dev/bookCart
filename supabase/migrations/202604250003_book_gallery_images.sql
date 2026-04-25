alter table public.books
add column if not exists image_urls jsonb not null default '[]'::jsonb;

update public.books
set image_urls = jsonb_build_array(image_base64)
where coalesce(jsonb_array_length(image_urls), 0) = 0
  and image_base64 is not null
  and image_base64 ~* '^https?://';

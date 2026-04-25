# BookCart Database Schema

This file is the human-readable schema reference for the BookCart app.
The executable Supabase migrations are:

- `supabase/migrations/202604220001_bookcart_schema.sql`
- `supabase/migrations/202604250001_book_images_bucket.sql`
- `supabase/migrations/202604250002_realtime_chat_sync_repair.sql`
- `supabase/migrations/202604250003_book_gallery_images.sql`

The schema below is derived from the app models and repository layer in:

- `lib/data/models/user_model.dart`
- `lib/data/models/book_model.dart`
- `lib/data/models/chat_model.dart`
- `lib/data/repository/supabase_auth_repository.dart`
- `lib/data/repository/book_repository.dart`
- `lib/data/repository/chat_repository.dart`

## Auth And Storage

Project auth model:

- Supabase Auth email/password users in `auth.users`
- Public profile rows mirrored into `public.users`
- Public storage bucket: `profile_images`
- Public storage bucket: `book_images`

Storage bucket:

- Bucket id: `profile_images`
- Public: `true`
- Object naming used by app: `<auth.uid()>.png`
- Upload mode used by app: upsert

- Bucket id: `book_images`
- Public: `true`
- Object naming used by app: `<auth.uid()>.book.<book-id-or-timestamp>.jpg`
- Upload mode used by app: upsert

## Table: `public.users`

Purpose:

- Stores the app profile for the authenticated user
- Mirrors data from `auth.users.raw_user_meta_data`
- Supplies seller contact/location info to book listings

Primary key:

- `id uuid primary key references auth.users(id) on delete cascade`

Columns:

| Column | Type | Null | Default | Notes |
|---|---|---|---|---|
| `id` | `uuid` | No | none | Matches Supabase Auth user id |
| `name` | `text` | No | `'Book Cart User'` | User display name |
| `phone` | `text` | No | `''` | Phone number |
| `email` | `text` | No | `''` | Current email |
| `location` | `text` | No | `'Kolkata, West Bengal'` | Human-readable place |
| `latitude` | `double precision` | Yes | `null` | Optional geolocation |
| `longitude` | `double precision` | Yes | `null` | Optional geolocation |
| `location_updated_at` | `timestamptz` | Yes | `null` | When location was last refreshed |
| `profile_image_base64` | `text` | Yes | `null` | Currently stores the uploaded public image URL |
| `created_at` | `timestamptz` | No | `timezone('utc', now())` | Row creation |
| `updated_at` | `timestamptz` | No | `timezone('utc', now())` | Row update |

Indexes:

- Primary key on `id`

RLS:

- Users can `select/insert/update/delete` only their own row

## Table: `public.books`

Purpose:

- Stores marketplace listings created by users

Primary key:

- `id uuid primary key default gen_random_uuid()`

Foreign keys:

- `seller_id -> public.users(id) on delete cascade`

Columns:

| Column | Type | Null | Default | Notes |
|---|---|---|---|---|
| `id` | `uuid` | No | `gen_random_uuid()` | Listing id |
| `image_base64` | `text` | Yes | `null` | Legacy primary-image column that now stores the first uploaded public image URL |
| `image_urls` | `jsonb` | No | `'[]'::jsonb` | Gallery image URLs, capped at 4 by the app |
| `title` | `text` | No | `''` | Book title |
| `author` | `text` | No | `''` | Author name |
| `category` | `text` | No | `''` | Comma-separated categories |
| `price` | `text` | No | `''` | Stored as text in app |
| `description` | `text` | No | `''` | Listing description |
| `seller_id` | `uuid` | No | none | Listing owner |
| `seller_name` | `text` | No | `'Seller'` | Denormalized seller name |
| `seller_email` | `text` | No | `''` | Denormalized seller email |
| `seller_phone` | `text` | No | `''` | Denormalized seller phone |
| `seller_location` | `text` | No | `'Kolkata, West Bengal'` | Denormalized seller location |
| `seller_latitude` | `double precision` | Yes | `null` | Seller coordinate snapshot |
| `seller_longitude` | `double precision` | Yes | `null` | Seller coordinate snapshot |
| `created_at` | `timestamptz` | No | `timezone('utc', now())` | Row creation |
| `updated_at` | `timestamptz` | No | `timezone('utc', now())` | Row update |

Indexes:

- `books_created_at_idx` on `created_at desc`
- `books_seller_id_idx` on `seller_id`

RLS:

- Any authenticated user can read books
- Only the seller can insert, update, or delete their own listings

## Table: `public.chats`

Purpose:

- Stores the conversation thread between one buyer and one seller for one book

Primary key:

- `id text primary key`

Thread id format used by app:

- `<book_id>_<seller_id>_<buyer_id>`

Foreign keys:

- `book_id -> public.books(id) on delete cascade`
- `buyer_id -> public.users(id) on delete cascade`
- `seller_id -> public.users(id) on delete cascade`
- `last_sender_id -> public.users(id) on delete set null`

Columns:

| Column | Type | Null | Default | Notes |
|---|---|---|---|---|
| `id` | `text` | No | none | Composite chat key |
| `book_id` | `uuid` | No | none | Source listing |
| `book_title` | `text` | No | `'Book listing'` | Denormalized title |
| `book_price` | `text` | No | `''` | Denormalized price |
| `buyer_id` | `uuid` | No | none | Buyer user id |
| `seller_id` | `uuid` | No | none | Seller user id |
| `buyer_name` | `text` | No | `'Buyer'` | Denormalized buyer name |
| `seller_name` | `text` | No | `'Seller'` | Denormalized seller name |
| `participant_ids` | `uuid[]` | No | `'{}'::uuid[]` | Both buyer and seller ids |
| `last_message` | `text` | No | `''` | Preview text |
| `last_sender_id` | `uuid` | Yes | `null` | Null until first message |
| `created_at` | `timestamptz` | No | `timezone('utc', now())` | Row creation |
| `updated_at` | `timestamptz` | No | `timezone('utc', now())` | Last activity |

Indexes:

- `chats_updated_at_idx` on `updated_at desc`
- `chats_buyer_id_idx` on `buyer_id`
- `chats_seller_id_idx` on `seller_id`
- `chats_participant_ids_gin_idx` on `participant_ids`

RLS:

- Only participants can read or update the thread
- Only the buyer can create the thread
- Buyer and seller must both be present in `participant_ids`

## Table: `public.chat_messages`

Purpose:

- Stores messages inside a chat thread

Primary key:

- `id uuid primary key default gen_random_uuid()`

Foreign keys:

- `chat_id -> public.chats(id) on delete cascade`
- `sender_id -> public.users(id) on delete cascade`

Columns:

| Column | Type | Null | Default | Notes |
|---|---|---|---|---|
| `id` | `uuid` | No | `gen_random_uuid()` | Message id |
| `chat_id` | `text` | No | none | Parent chat id |
| `text` | `text` | No | none | Message body |
| `sender_id` | `uuid` | No | none | Author user id |
| `created_at` | `timestamptz` | No | `timezone('utc', now())` | Send time |

Indexes:

- `chat_messages_chat_id_created_at_idx` on `(chat_id, created_at)`

RLS:

- Only chat participants can read messages
- Only the authenticated sender can insert their own messages

## Functions And Triggers

### `public.set_updated_at()`

Used by:

- `users_set_updated_at`
- `books_set_updated_at`
- `chats_set_updated_at`

Effect:

- Automatically writes `updated_at = timezone('utc', now())` before update

### `public.sync_auth_user_to_public_user()`

Trigger source:

- `auth.users`

Effect:

- Mirrors `auth.users` metadata into `public.users`
- Keeps profile row synced on signup and account metadata changes

### `public.delete_my_account()`

Purpose:

- Deletes the authenticated user from `auth.users`
- Cascades into `public.users`, `public.books`, `public.chats`, and `public.chat_messages`

## Realtime

Realtime publication expected by the app:

- `public.users`
- `public.books`
- `public.chats`
- `public.chat_messages`

Replica identity:

- `full` on all four public tables

## App-Level Data Notes

- `profile_image_base64` is a legacy column name. The app currently stores a public image URL there, not base64 text.
- `image_base64` is also treated as a legacy column name. Book listings now store the first public image URL there for backward compatibility.
- `image_urls` stores the full book gallery and is capped at 4 images in the Flutter app.
- `books.price` and `chats.book_price` are stored as `text` because the current Flutter app treats prices as strings.
- `books.category` is stored as a comma-separated string, even though the UI supports multiple categories.
- `chats.last_sender_id` starts as `null` and becomes the UUID of the last message sender.

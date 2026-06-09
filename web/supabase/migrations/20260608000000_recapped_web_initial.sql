create schema if not exists private;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text,
  avatar_url text,
  created_at timestamptz not null default now()
);

create table if not exists public.videos (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  title text not null check (char_length(title) between 1 and 140),
  description text,
  storage_path text not null unique,
  playback_url text not null,
  thumbnail_url text,
  duration_seconds integer not null default 60 check (duration_seconds > 0),
  visibility text not null default 'public' check (visibility in ('public', 'private')),
  created_at timestamptz not null default now()
);

alter table public.profiles enable row level security;
alter table public.videos enable row level security;

create policy "Profiles are publicly readable"
  on public.profiles for select
  using (true);

create policy "Users can insert their own profile"
  on public.profiles for insert
  to authenticated
  with check (id = auth.uid());

create policy "Users can update their own profile"
  on public.profiles for update
  to authenticated
  using (id = auth.uid())
  with check (id = auth.uid());

create policy "Public videos are readable"
  on public.videos for select
  using (visibility = 'public');

create policy "Users can insert their own videos"
  on public.videos for insert
  to authenticated
  with check (user_id = auth.uid());

create policy "Users can update their own videos"
  on public.videos for update
  to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

create policy "Users can delete their own videos"
  on public.videos for delete
  to authenticated
  using (user_id = auth.uid());

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'recapped-videos',
  'recapped-videos',
  true,
  524288000,
  array['video/mp4', 'video/quicktime', 'video/webm']
)
on conflict (id) do nothing;

create policy "Public videos can be viewed"
  on storage.objects for select
  using (bucket_id = 'recapped-videos');

create policy "Users can upload videos into their own folder"
  on storage.objects for insert
  to authenticated
  with check (
    bucket_id = 'recapped-videos'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

create policy "Users can update videos in their own folder"
  on storage.objects for update
  to authenticated
  using (
    bucket_id = 'recapped-videos'
    and (storage.foldername(name))[1] = auth.uid()::text
  )
  with check (
    bucket_id = 'recapped-videos'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

create policy "Users can delete videos in their own folder"
  on storage.objects for delete
  to authenticated
  using (
    bucket_id = 'recapped-videos'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

create or replace function private.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public, auth
as $$
begin
  insert into public.profiles (id, display_name, avatar_url)
  values (
    new.id,
    coalesce(new.raw_user_meta_data ->> 'full_name', new.email),
    new.raw_user_meta_data ->> 'avatar_url'
  )
  on conflict (id) do update
  set
    display_name = excluded.display_name,
    avatar_url = excluded.avatar_url;

  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function private.handle_new_user();

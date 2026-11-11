-- Run this once in Supabase: SQL Editor > New query > paste > Run.

create table if not exists public.members (
  id          uuid primary key default gen_random_uuid(),
  name        text        not null check (char_length(name) between 2 and 80),
  phone       text        not null unique check (phone ~ '^[6-9][0-9]{9}$'),
  birthday    date,
  consent     boolean     not null default false check (consent = true),
  source      text,
  created_at  timestamptz not null default now()
);

-- Row Level Security: visitors (anon key) may only ADD a member.
-- They cannot read, change or delete anyone's details.
alter table public.members enable row level security;

drop policy if exists "Anyone can join" on public.members;
create policy "Anyone can join"
  on public.members
  for insert
  to anon
  with check (consent = true);

-- You read the list from the Supabase dashboard (Table Editor) or with the
-- service_role key on a server. Never put the service_role key in index.html.

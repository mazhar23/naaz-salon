-- Run AFTER supabase.sql. Supabase: SQL Editor > New query > paste > Run.

-- 1) Who is allowed to see members
create table if not exists public.admins (
  email text primary key
);
alter table public.admins enable row level security;   -- no policies: nobody can read it directly

-- 2) Helper that checks the signed-in user's email against the admins table
create or replace function public.is_admin()
returns boolean
language sql
security definer
set search_path = public
stable
as $$
  select exists (
    select 1 from public.admins
    where lower(email) = lower(coalesce(auth.jwt() ->> 'email', ''))
  );
$$;
revoke all on function public.is_admin() from public;
grant execute on function public.is_admin() to authenticated;

-- 3) Admins can read and delete members. Visitors still can only add.
drop policy if exists "Admins can view members" on public.members;
create policy "Admins can view members"
  on public.members for select to authenticated
  using (public.is_admin());

drop policy if exists "Admins can delete members" on public.members;
create policy "Admins can delete members"
  on public.members for delete to authenticated
  using (public.is_admin());

-- 4) Add yourself. Replace with the email you will sign in with.
insert into public.admins (email) values ('YOUR_ADMIN_EMAIL')
on conflict do nothing;

-- Then create that login: Supabase dashboard > Authentication > Users > Add user
-- (email + password, tick "Auto Confirm User"). Turn OFF public sign-ups under
-- Authentication > Sign In / Providers so nobody else can create accounts.

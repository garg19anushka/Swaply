-- Run this script in your Supabase SQL Editor to fix the Profile and Avatar upload issues.

-- ==========================================
-- 1. PROFILES TABLE & POLICIES
-- ==========================================

-- Create the profiles table if it doesn't exist
create table if not exists public.profiles (
  id uuid references auth.users on delete cascade primary key,
  username text not null,
  full_name text,
  avatar_url text,
  bio text,
  campus text,
  skills_offered text[] default '{}',
  skills_wanted text[] default '{}',
  links text[] default '{}',
  total_swaps integer default 0,
  average_rating numeric default 0.0,
  rating_count integer default 0,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  updated_at timestamp with time zone
);

-- Enable Row Level Security (RLS) on profiles
alter table public.profiles enable row level security;

-- FIX: drop-before-create so this script can be re-run safely without
-- "policy already exists" errors (e.g. after a partial failure further
-- down the script on a previous run).
drop policy if exists "Public profiles are viewable by everyone." on public.profiles;
drop policy if exists "Users can insert their own profile." on public.profiles;
drop policy if exists "Users can update own profile." on public.profiles;

-- Policy: Allow public to view any profile
create policy "Public profiles are viewable by everyone."
on public.profiles for select
using ( true );

-- Policy: Allow users to insert their own profile
create policy "Users can insert their own profile."
on public.profiles for insert
with check ( auth.uid() = id );

-- Policy: Allow users to update their own profile
create policy "Users can update own profile."
on public.profiles for update
using ( auth.uid() = id );


-- ==========================================
-- 2. STORAGE (AVATARS BUCKET) POLICIES
-- ==========================================

-- (Assuming you already created the 'avatars' bucket in the dashboard)

drop policy if exists "Public Access" on storage.objects;
drop policy if exists "Authenticated users can upload avatars" on storage.objects;
drop policy if exists "Users can update their own avatars" on storage.objects;
drop policy if exists "Users can delete their own avatars" on storage.objects;

-- Policy: Allow public access to view avatars
create policy "Public Access"
on storage.objects for select
using ( bucket_id = 'avatars' );

-- Policy: Allow authenticated users to upload avatars
create policy "Authenticated users can upload avatars"
on storage.objects for insert
with check ( auth.role() = 'authenticated' AND bucket_id = 'avatars' );

-- Policy: Allow users to update their own avatars
create policy "Users can update their own avatars"
on storage.objects for update
using ( auth.uid() = owner AND bucket_id = 'avatars' );

-- Policy: Allow users to delete their own avatars
create policy "Users can delete their own avatars"
on storage.objects for delete
using ( auth.uid() = owner AND bucket_id = 'avatars' );


-- ==========================================
-- 3. REPORTS AND BLOCKS (Safety Features)
-- ==========================================

-- User Reports
create table if not exists public.user_reports (
  id uuid default gen_random_uuid() primary key,
  reporter_id uuid references auth.users(id) on delete cascade not null,
  reported_id uuid references auth.users(id) on delete cascade not null,
  reason text not null,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

alter table public.user_reports enable row level security;

drop policy if exists "Users can insert reports" on public.user_reports;
drop policy if exists "Users can view their own reports" on public.user_reports;

create policy "Users can insert reports"
on public.user_reports for insert
with check ( auth.uid() = reporter_id );

create policy "Users can view their own reports"
on public.user_reports for select
using ( auth.uid() = reporter_id );

-- User Blocks
create table if not exists public.user_blocks (
  id uuid default gen_random_uuid() primary key,
  blocker_id uuid references auth.users(id) on delete cascade not null,
  blocked_id uuid references auth.users(id) on delete cascade not null,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  unique(blocker_id, blocked_id)
);

alter table public.user_blocks enable row level security;

drop policy if exists "Users can insert blocks" on public.user_blocks;
drop policy if exists "Users can view their own blocks" on public.user_blocks;
drop policy if exists "Users can delete their blocks" on public.user_blocks;

create policy "Users can insert blocks"
on public.user_blocks for insert
with check ( auth.uid() = blocker_id );

create policy "Users can view their own blocks"
on public.user_blocks for select
using ( auth.uid() = blocker_id );

create policy "Users can delete their blocks"
on public.user_blocks for delete
using ( auth.uid() = blocker_id );


-- ==========================================
-- 4. BACKFILL: links column on profiles
-- ==========================================
-- If 'profiles' already existed before this script added 'links' above,
-- "create table if not exists" won't add the new column. This makes sure
-- it's there either way — without it, AuthService.updateProfile's
-- links-save will keep silently falling back to "update without links".
alter table public.profiles
  add column if not exists links text[] default '{}';


-- ==========================================
-- 7. POSTS TABLE: expires_at column
-- ==========================================
-- Posts expire 30 days after creation by default.
-- The Edge Function checks this column daily to send expiry notifications.
alter table public.posts
  add column if not exists expires_at timestamp with time zone
  default (now() + interval '30 days');

-- Backfill existing posts that don't have an expiry yet
update public.posts
  set expires_at = created_at + interval '30 days'
  where expires_at is null;
-- Used by SwapService (fetchActiveSwaps, fetchAllSwaps, confirmSwap,
-- completeSession). Column names must match swap_model.dart exactly,
-- in particular requester_id / responder_id (NOT user_id / partner_id).
create table if not exists public.swaps (
  id uuid default gen_random_uuid() primary key,
  swap_title text not null default 'Skill Swap',
  total_sessions integer not null default 1,
  done_sessions integer not null default 0,
  progress_label text,
  next_session_label text,
  status text not null default 'pending',
  partner_name text,
  partner_username text,
  partner_avatar_url text,
  expires_at timestamp with time zone,
  confirmed_at timestamp with time zone,
  requester_id uuid references auth.users(id) on delete cascade,
  responder_id uuid references auth.users(id) on delete cascade,
  offered_skill text,
  wanted_skill text,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- FIX: the old System A schema created 'swaps' with chat_id, initiator_id,
-- and receiver_id all as NOT NULL. System B swaps have none of these,
-- so inserting one fails with "null value in column X violates not-null
-- constraint" (Postgres code 23502).
-- Drop NOT NULL on all three so both old chat-based rows and new
-- System B rows can coexist in the same table.
alter table public.swaps alter column chat_id drop not null;
alter table public.swaps alter column initiator_id drop not null;
alter table public.swaps alter column receiver_id drop not null;

alter table public.swaps enable row level security;

-- FIX: "create table if not exists" is a no-op if 'swaps' already existed
-- in your project (with an older/partial schema) — that's why you got
-- "column requester_id does not exist" when the policies below tried to
-- reference it. These ALTER statements backfill every column SwapModel
-- and SwapService expect, regardless of whether the table was just
-- created above or already existed.
alter table public.swaps add column if not exists swap_title text not null default 'Skill Swap';
alter table public.swaps add column if not exists total_sessions integer not null default 1;
alter table public.swaps add column if not exists done_sessions integer not null default 0;
alter table public.swaps add column if not exists progress_label text;
alter table public.swaps add column if not exists next_session_label text;
alter table public.swaps add column if not exists status text not null default 'pending';
alter table public.swaps add column if not exists partner_name text;
alter table public.swaps add column if not exists partner_username text;
alter table public.swaps add column if not exists partner_avatar_url text;
alter table public.swaps add column if not exists expires_at timestamp with time zone;
alter table public.swaps add column if not exists confirmed_at timestamp with time zone;
alter table public.swaps add column if not exists requester_id uuid references auth.users(id) on delete cascade;
alter table public.swaps add column if not exists responder_id uuid references auth.users(id) on delete cascade;
alter table public.swaps add column if not exists offered_skill text;
alter table public.swaps add column if not exists wanted_skill text;
alter table public.swaps add column if not exists created_at timestamp with time zone default timezone('utc'::text, now()) not null;

-- NEW: per-role identity snapshots. partner_name/partner_username/
-- partner_avatar_url (above) can only describe ONE side's view of "the
-- other person" — they break for whichever party they weren't written
-- for. Storing both sides' info lets SwapModel compute the correct
-- "partner" for whoever is currently looking at the row.
alter table public.swaps add column if not exists requester_name text;
alter table public.swaps add column if not exists requester_username text;
alter table public.swaps add column if not exists requester_avatar_url text;
alter table public.swaps add column if not exists responder_name text;
alter table public.swaps add column if not exists responder_username text;
alter table public.swaps add column if not exists responder_avatar_url text;

-- Drop old policies first (in case this script runs more than once, or
-- earlier policies referenced columns that didn't exist yet and failed
-- partway through).
drop policy if exists "Participants can view their swaps" on public.swaps;
drop policy if exists "Participants can create swaps" on public.swaps;
drop policy if exists "Participants can update their swaps" on public.swaps;

-- Either participant can view the swap
create policy "Participants can view their swaps"
on public.swaps for select
using ( auth.uid() = requester_id or auth.uid() = responder_id );

-- Either participant can create a swap they're part of
create policy "Participants can create swaps"
on public.swaps for insert
with check ( auth.uid() = requester_id or auth.uid() = responder_id );

-- Either participant can update the swap (confirm, complete sessions, etc.)
create policy "Participants can update their swaps"
on public.swaps for update
using ( auth.uid() = requester_id or auth.uid() = responder_id );


-- ==========================================
-- 6. NOTIFICATIONS TABLE & POLICIES
-- ==========================================
-- Used by NotificationService (fetchNotifications, subscribeToNotifications,
-- markAsRead, markAllRead) and inserted into by SwapService.confirmSwap.
create table if not exists public.notifications (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references auth.users(id) on delete cascade not null,
  type text not null,
  title text not null,
  body text,
  data jsonb default '{}',
  is_read boolean default false,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

alter table public.notifications enable row level security;

-- FIX: same reasoning as the swaps table above — if 'notifications'
-- already existed with a different/partial schema, backfill the columns
-- NotificationModel and NotificationService expect.
alter table public.notifications add column if not exists user_id uuid references auth.users(id) on delete cascade;
alter table public.notifications add column if not exists type text not null default 'general';
alter table public.notifications add column if not exists title text not null default '';
alter table public.notifications add column if not exists body text;
alter table public.notifications add column if not exists data jsonb default '{}';
alter table public.notifications add column if not exists is_read boolean default false;
alter table public.notifications add column if not exists created_at timestamp with time zone default timezone('utc'::text, now()) not null;

drop policy if exists "Users can view their own notifications" on public.notifications;
drop policy if exists "Users can update their own notifications" on public.notifications;
drop policy if exists "Authenticated users can insert notifications" on public.notifications;

-- Users can view their own notifications
create policy "Users can view their own notifications"
on public.notifications for select
using ( auth.uid() = user_id );

-- Users can update (mark read) their own notifications
create policy "Users can update their own notifications"
on public.notifications for update
using ( auth.uid() = user_id );

-- Any authenticated user can insert a notification for another user
-- (e.g. SwapService notifying the other participant when a swap is
-- confirmed). Tighten this further if you want stricter control.
create policy "Authenticated users can insert notifications"
on public.notifications for insert
with check ( auth.role() = 'authenticated' );
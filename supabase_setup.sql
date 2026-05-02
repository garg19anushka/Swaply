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
  total_swaps integer default 0,
  average_rating numeric default 0.0,
  rating_count integer default 0,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  updated_at timestamp with time zone
);

-- Enable Row Level Security (RLS) on profiles
alter table public.profiles enable row level security;

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

create policy "Users can insert blocks"
on public.user_blocks for insert
with check ( auth.uid() = blocker_id );

create policy "Users can view their own blocks"
on public.user_blocks for select
using ( auth.uid() = blocker_id );

create policy "Users can delete their blocks"
on public.user_blocks for delete
using ( auth.uid() = blocker_id );

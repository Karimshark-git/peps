-- ============================================================================
-- PEPS — Canonical Supabase / PostgreSQL Schema
-- ============================================================================
-- This file describes the CURRENT state of the live PEPS Supabase database.
-- It is authoritative for fresh setup. The other files in this directory
-- (schema_peptides_extension.sql, migration_add_first_name.sql) are
-- historical migrations kept for reference only.
--
-- Auth model: `users.id` IS the auth id. It is both the PRIMARY KEY of
-- public.users AND a FOREIGN KEY to auth.users.id. There is no separate
-- `auth_uid` column (the dual-column model was consolidated). All RLS
-- policies on `users` use `id = auth.uid()`.
-- ============================================================================

-- Required extension for uuid_generate_v4()
create extension if not exists "uuid-ossp";

-- ----------------------------------------------------------------------------
-- Legacy cleanup: drop the obsolete auth_uid column if it still exists
-- (no-op on fresh databases).
-- ----------------------------------------------------------------------------
alter table if exists users drop column if exists auth_uid;


-- ============================================================================
-- TABLES
-- ============================================================================

-- USERS ----------------------------------------------------------------------
create table if not exists users (
  id uuid primary key references auth.users(id) on delete cascade,
  email text,
  first_name text,
  plan text default 'none',
  plan_status text default 'inactive',
  plan_started_at timestamp with time zone,
  created_at timestamp with time zone default now()
);

-- ONBOARDING RESPONSES -------------------------------------------------------
create table if not exists onboarding_responses (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid unique references users(id) on delete cascade,
  first_name text,
  goals text[],
  age int,
  height_cm int,
  weight_kg int,
  activity_level text,
  lifestyle_factors text[],
  medical_conditions text[],
  created_at timestamp with time zone default now()
);

-- PEPTIDES (master catalogue) ------------------------------------------------
create table if not exists peptides (
  id uuid primary key default uuid_generate_v4(),
  name text not null,
  category text,
  summary text,
  description text,
  benefits text[],
  short_benefits text[],
  dosage text,
  frequency text,
  cycle_length text,
  administration_route text,
  goals_supported text[],
  lifestyle_supported text[],
  biometric_modifiers jsonb,
  medical_flags text[],
  contraindications text[],
  reasoning_template text,
  risk_level text default 'low',
  requires_prescription boolean default true,
  is_active boolean default true
);

-- RECOMMENDATIONS ------------------------------------------------------------
create table if not exists recommendations (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid references users(id) on delete cascade,
  peptide_id uuid references peptides(id) on delete cascade,
  reasoning text,
  score numeric,
  physician_status text default 'pending',
  physician_notes text,
  reviewed_at timestamp with time zone,
  created_at timestamp with time zone default now()
);

-- WEEKLY CHECK-INS -----------------------------------------------------------
create table if not exists check_ins (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid references users(id) on delete cascade,
  week_number int not null,
  energy_score int check (energy_score >= 1 and energy_score <= 10),
  sleep_score int check (sleep_score >= 1 and sleep_score <= 10),
  recovery_score int check (recovery_score >= 1 and recovery_score <= 10),
  mood_score int check (mood_score >= 1 and mood_score <= 10),
  side_effects text,
  notes text,
  ai_summary text,
  flagged_for_physician boolean default false,
  created_at timestamp with time zone default now()
);

-- PROTOCOL CYCLES (active subscription / delivery state) ---------------------
create table if not exists protocol_cycles (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid references users(id) on delete cascade,
  plan text not null,
  status text default 'active',
  started_at timestamp with time zone default now(),
  ends_at timestamp with time zone,
  next_delivery_at timestamp with time zone,
  delivery_address text,
  created_at timestamp with time zone default now()
);

-- LAB UPLOADS ----------------------------------------------------------------
create table if not exists lab_uploads (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid references users(id) on delete cascade,
  file_path text not null,
  file_name text,
  physician_reviewed boolean default false,
  ai_summary text,
  notes text,
  uploaded_at timestamp with time zone default now()
);

-- PHYSICIAN MESSAGES ---------------------------------------------------------
create table if not exists physician_messages (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid references users(id) on delete cascade,
  sender text not null check (sender in ('user', 'physician')),
  message text not null,
  read boolean default false,
  created_at timestamp with time zone default now()
);


-- ============================================================================
-- ROW-LEVEL SECURITY
-- ============================================================================

alter table users                enable row level security;
alter table onboarding_responses enable row level security;
alter table peptides             enable row level security;
alter table recommendations      enable row level security;
alter table check_ins            enable row level security;
alter table protocol_cycles      enable row level security;
alter table lab_uploads          enable row level security;
alter table physician_messages   enable row level security;


-- USERS — own profile only ---------------------------------------------------
drop policy if exists "Users can insert own profile" on users;
drop policy if exists "Users can select own profile" on users;
drop policy if exists "Users can update own profile" on users;

create policy "Users can insert own profile" on users
  for insert with check (id = auth.uid());
create policy "Users can select own profile" on users
  for select using (id = auth.uid());
create policy "Users can update own profile" on users
  for update using (id = auth.uid()) with check (id = auth.uid());


-- ONBOARDING RESPONSES -------------------------------------------------------
drop policy if exists "Users can insert own onboarding responses" on onboarding_responses;
drop policy if exists "Users can select own onboarding responses" on onboarding_responses;
drop policy if exists "Users can update own onboarding responses" on onboarding_responses;

create policy "Users can insert own onboarding responses" on onboarding_responses
  for insert with check (user_id = auth.uid());
create policy "Users can select own onboarding responses" on onboarding_responses
  for select using (user_id = auth.uid());
create policy "Users can update own onboarding responses" on onboarding_responses
  for update using (user_id = auth.uid()) with check (user_id = auth.uid());


-- PEPTIDES — public read, admin-only write -----------------------------------
drop policy if exists "Everyone can read peptides" on peptides;

create policy "Everyone can read peptides" on peptides
  for select using (true);


-- RECOMMENDATIONS ------------------------------------------------------------
drop policy if exists "Users can insert own recommendations" on recommendations;
drop policy if exists "Users can select own recommendations" on recommendations;
drop policy if exists "Users can update own recommendations" on recommendations;

create policy "Users can insert own recommendations" on recommendations
  for insert with check (user_id = auth.uid());
create policy "Users can select own recommendations" on recommendations
  for select using (user_id = auth.uid());
create policy "Users can update own recommendations" on recommendations
  for update using (user_id = auth.uid()) with check (user_id = auth.uid());


-- CHECK-INS ------------------------------------------------------------------
drop policy if exists "Users can insert own check-ins" on check_ins;
drop policy if exists "Users can select own check-ins" on check_ins;
drop policy if exists "Users can update own check-ins" on check_ins;

create policy "Users can insert own check-ins" on check_ins
  for insert with check (user_id = auth.uid());
create policy "Users can select own check-ins" on check_ins
  for select using (user_id = auth.uid());
create policy "Users can update own check-ins" on check_ins
  for update using (user_id = auth.uid()) with check (user_id = auth.uid());


-- PROTOCOL CYCLES — insert + select only -------------------------------------
drop policy if exists "Users can insert own protocol cycles" on protocol_cycles;
drop policy if exists "Users can select own protocol cycles" on protocol_cycles;

create policy "Users can insert own protocol cycles" on protocol_cycles
  for insert with check (user_id = auth.uid());
create policy "Users can select own protocol cycles" on protocol_cycles
  for select using (user_id = auth.uid());


-- LAB UPLOADS — insert + select only -----------------------------------------
drop policy if exists "Users can insert own lab uploads" on lab_uploads;
drop policy if exists "Users can select own lab uploads" on lab_uploads;

create policy "Users can insert own lab uploads" on lab_uploads
  for insert with check (user_id = auth.uid());
create policy "Users can select own lab uploads" on lab_uploads
  for select using (user_id = auth.uid());


-- PHYSICIAN MESSAGES — insert + select only ----------------------------------
drop policy if exists "Users can insert own messages" on physician_messages;
drop policy if exists "Users can select own messages" on physician_messages;

create policy "Users can insert own messages" on physician_messages
  for insert with check (user_id = auth.uid());
create policy "Users can select own messages" on physician_messages
  for select using (user_id = auth.uid());

-- USERS TABLE
create table if not exists users (
  id uuid primary key default uuid_generate_v4(),
  auth_uid uuid unique,
  email text,
  first_name text,
  created_at timestamp with time zone default now()
);

-- ONBOARDING RESPONSES TABLE
create table if not exists onboarding_responses (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid references users(id) on delete cascade,
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

-- PEPTIDES MASTER TABLE
create table if not exists peptides (
  id uuid primary key default uuid_generate_v4(),
  name text not null,
  category text,
  description text,
  summary text,
  benefits text[],
  dosage text,
  frequency text
);

-- USER RECOMMENDATIONS TABLE
create table if not exists recommendations (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid references users(id) on delete cascade,
  peptide_id uuid references peptides(id) on delete cascade,
  reasoning text,
  created_at timestamp with time zone default now()
);


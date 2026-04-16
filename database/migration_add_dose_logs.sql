-- Migration: add dose_logs table for daily peptide dose tracking
-- Run this in your Supabase SQL editor.
--
-- Auth model: this codebase uses the consolidated id model where
-- public.users.id IS auth.uid(). Therefore RLS checks reference
-- user_id = auth.uid() directly (no auth_uid column exists).

create table if not exists public.dose_logs (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid references public.users(id) on delete cascade,
  peptide_id uuid references public.peptides(id) on delete cascade,
  recommendation_id uuid references public.recommendations(id) on delete cascade,
  taken_at timestamptz default now(),
  date date default current_date,
  notes text,
  created_at timestamptz default now()
);

alter table public.dose_logs enable row level security;

drop policy if exists "Users can insert own dose logs" on public.dose_logs;
drop policy if exists "Users can select own dose logs" on public.dose_logs;
drop policy if exists "Users can delete own dose logs" on public.dose_logs;

create policy "Users can insert own dose logs"
  on public.dose_logs for insert
  with check (user_id = auth.uid());

create policy "Users can select own dose logs"
  on public.dose_logs for select
  using (user_id = auth.uid());

create policy "Users can delete own dose logs"
  on public.dose_logs for delete
  using (user_id = auth.uid());

create index if not exists idx_dose_logs_user_id
  on public.dose_logs(user_id);
create index if not exists idx_dose_logs_date
  on public.dose_logs(date);
create index if not exists idx_dose_logs_peptide_date
  on public.dose_logs(peptide_id, date);

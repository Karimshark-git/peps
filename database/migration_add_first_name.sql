-- Migration to add first_name columns to users and onboarding_responses tables
-- Run this in your Supabase SQL editor

-- Add first_name column to users table if it doesn't exist
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS first_name text;

-- Add first_name column to onboarding_responses table if it doesn't exist
ALTER TABLE onboarding_responses 
ADD COLUMN IF NOT EXISTS first_name text;



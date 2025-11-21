-- Extension to peptides table for recommendation engine metadata
-- This migration adds columns needed for Phase 1 of the PEPS recommendation engine

ALTER TABLE peptides
ADD COLUMN IF NOT EXISTS goals_supported text[],
ADD COLUMN IF NOT EXISTS lifestyle_supported text[],
ADD COLUMN IF NOT EXISTS biometric_modifiers jsonb,
ADD COLUMN IF NOT EXISTS medical_flags text[],
ADD COLUMN IF NOT EXISTS contraindications text[],
ADD COLUMN IF NOT EXISTS reasoning_template text,
ADD COLUMN IF NOT EXISTS short_benefits text[];


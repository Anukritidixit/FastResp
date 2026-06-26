-- Migration to add GPS accuracy to sos_incidents
ALTER TABLE public.sos_incidents ADD COLUMN IF NOT EXISTS accuracy NUMERIC(10, 2);

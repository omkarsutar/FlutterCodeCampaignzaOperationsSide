-- Migration: Add android_app_id and website_url columns to brands table
-- Date: 2026-05-31
-- Description: Add mobile app ID and brand website URL fields to support referrer tracking and brand links

-- Add new columns to brands table
ALTER TABLE public.brands
ADD COLUMN android_app_id text,
ADD COLUMN website_url text;

-- Add comments for documentation
COMMENT ON COLUMN public.brands.android_app_id IS 'Android package ID for the brand app (e.g., com.numeroshastra.client)';
COMMENT ON COLUMN public.brands.website_url IS 'Brand website URL';

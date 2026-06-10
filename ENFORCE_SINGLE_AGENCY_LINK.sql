-- ============================================================================
-- FIX: Enforce Single Agency Per User
-- Purpose: Restrict the user_agency_link table so each user can only be 
--          assigned to one agency at a time.
-- Date: June 10, 2026
-- ============================================================================

BEGIN;

-- 1. Clean up existing data: Keep only the most recently created link for each user
-- This ensures the unique constraint can be applied without error.
DELETE FROM public.user_agency_link a
USING public.user_agency_link b
WHERE a.user_id = b.user_id 
  AND a.created_at < b.created_at;

-- 2. Drop the existing unique pair constraint (user_id, agency_id)
ALTER TABLE public.user_agency_link DROP CONSTRAINT IF EXISTS user_agency_unique_pair;

-- 3. Add the new unique constraint on user_id only
-- This enforces the one-to-one/zero-to-one relationship between users and agencies.
ALTER TABLE public.user_agency_link ADD CONSTRAINT user_agency_single_link UNIQUE (user_id);

-- 4. Update the view to reflect this structure (optional but good for metadata)
COMMENT ON TABLE public.user_agency_link IS 'Links users to agencies. Enforces a single agency assignment per user.';

COMMIT;

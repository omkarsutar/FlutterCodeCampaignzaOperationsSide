-- ============================================================================
-- FIX: Brands Access Policy
-- Purpose: Allow agencies to see brands if they are primary OR linked via agency_brand_links
-- Date: June 9, 2026
-- ============================================================================

BEGIN;

-- 1. Drop the restrictive select policy if it exists
DROP POLICY IF EXISTS brands_select_policy ON public.brands;

-- 2. Create the corrected select policy
CREATE POLICY brands_select_policy ON public.brands 
FOR SELECT TO authenticated 
USING (
  -- Admins see everything
  public.is_admin() 
  OR 
  -- Users linked to the brand's primary agency
  brands_primary_agency IN (
    SELECT agency_id FROM user_agency_link WHERE user_id = auth.uid()
  )
  OR 
  -- Users linked to an agency that has an explicit link to this brand
  brand_id IN (
    SELECT brand_id FROM agency_brand_links 
    WHERE agency_id IN (
      SELECT agency_id FROM user_agency_link WHERE user_id = auth.uid()
    )
  )
);

-- 3. Update policy: ONLY Primary Agency can update (Linked agencies are read-only)
DROP POLICY IF EXISTS brands_update_policy ON public.brands;
CREATE POLICY brands_update_policy ON public.brands 
FOR UPDATE TO authenticated 
USING (
  -- Admins can update
  public.is_admin() 
  OR 
  -- ONLY the Primary Agency can update
  brands_primary_agency IN (
    SELECT agency_id FROM user_agency_link WHERE user_id = auth.uid()
  )
)
WITH CHECK (
  public.is_admin() 
  OR brands_primary_agency IN (
    SELECT agency_id FROM user_agency_link WHERE user_id = auth.uid()
  )
);

COMMIT;

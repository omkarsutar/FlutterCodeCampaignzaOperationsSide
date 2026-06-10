-- ============================================================================
-- FIX: Agency User Brand Permissions
-- Purpose: Allow users linked to an agency to create and update brands 
--          associated with that agency.
-- Date: June 10, 2026
-- ============================================================================

BEGIN;

-- 1. Fix Brands INSERT Policy
-- Previous policy only allowed admins to create brands.
-- New policy allows admins OR users linked to the primary agency.
DROP POLICY IF EXISTS brands_insert_policy ON public.brands;
CREATE POLICY brands_insert_policy ON public.brands 
FOR INSERT TO authenticated 
WITH CHECK (
  public.is_admin() 
  OR 
  (brands_primary_agency IN (
    SELECT agency_id FROM public.user_agency_link WHERE user_id = auth.uid()
  ))
);

-- 2. Fix Brands UPDATE Policy
-- Ensuring consistency for updates.
DROP POLICY IF EXISTS brands_update_policy ON public.brands;
CREATE POLICY brands_update_policy ON public.brands 
FOR UPDATE TO authenticated 
USING (
  public.is_admin() 
  OR 
  (brands_primary_agency IN (
    SELECT agency_id FROM public.user_agency_link WHERE user_id = auth.uid()
  ))
)
WITH CHECK (
  public.is_admin() 
  OR 
  (brands_primary_agency IN (
    SELECT agency_id FROM public.user_agency_link WHERE user_id = auth.uid()
  ))
);

-- 3. Fix Agency Brand Links Policies
-- Non-admins also need to be able to manage the link between their agency and the brand.

-- Drop the restrictive admin-only policy
DROP POLICY IF EXISTS agency_brand_links_admin_policy ON public.agency_brand_links;

-- Create specific policies for INSERT, UPDATE, DELETE for non-admins
CREATE POLICY agency_brand_links_insert_policy ON public.agency_brand_links 
FOR INSERT TO authenticated 
WITH CHECK (
  public.is_admin() 
  OR 
  (agency_id IN (
    SELECT agency_id FROM public.user_agency_link WHERE user_id = auth.uid()
  ))
);

CREATE POLICY agency_brand_links_update_policy ON public.agency_brand_links 
FOR UPDATE TO authenticated 
USING (
  public.is_admin() 
  OR 
  (agency_id IN (
    SELECT agency_id FROM public.user_agency_link WHERE user_id = auth.uid()
  ))
)
WITH CHECK (
  public.is_admin() 
  OR 
  (agency_id IN (
    SELECT agency_id FROM public.user_agency_link WHERE user_id = auth.uid()
  ))
);

CREATE POLICY agency_brand_links_delete_policy ON public.agency_brand_links 
FOR DELETE TO authenticated 
USING (
  public.is_admin() 
  OR 
  (agency_id IN (
    SELECT agency_id FROM public.user_agency_link WHERE user_id = auth.uid()
  ))
);

COMMIT;

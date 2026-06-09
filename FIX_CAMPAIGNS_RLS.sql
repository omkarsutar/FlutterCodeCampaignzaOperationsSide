-- ============================================================================
-- FIX: Campaigns Access Policy & View Security
-- Purpose: Ensure agencies only see their own campaigns (admin excepted)
-- Date: June 9, 2026
-- ============================================================================

BEGIN;

-- 1. Ensure RLS is enabled on the underlying table
ALTER TABLE public.campaign ENABLE ROW LEVEL SECURITY;

-- 2. Drop the existing select policy to recreate it cleanly
DROP POLICY IF EXISTS campaign_select_policy ON public.campaign;

-- 3. Create/Recreate the campaign select policy
-- This policy allows access if:
-- a) User is an admin
-- b) campaign_agency_id matches an agency the user is linked to in user_agency_link
CREATE POLICY campaign_select_policy ON public.campaign 
FOR SELECT TO authenticated 
USING (
  public.is_admin() 
  OR 
  campaign_agency_id IN (
    SELECT agency_id FROM public.user_agency_link WHERE user_id = auth.uid()
  )
);

-- 4. Recreate the view with security_invoker = true
-- This is CRITICAL. If security_invoker is false (default), the view runs with 
-- the permissions of the creator (usually postgres/admin), bypassing RLS.
DROP VIEW IF EXISTS public.view_campaigns;
CREATE VIEW public.view_campaigns 
WITH (security_invoker = 'true')
AS 
SELECT 
    c.*,
    a.agency_name AS campaign_agency_id_label,
    b.brand_name AS campaign_brand_id_label,
    b.brand_address AS brand_address_label,
    b.brand_note AS brand_note_label,
    -- Concatenate mobile numbers for the label
    CASE 
        WHEN b.brand_mobile_1 <> '' AND b.brand_mobile_2 <> '' THEN b.brand_mobile_1 || ' / ' || b.brand_mobile_2
        WHEN b.brand_mobile_1 <> '' THEN b.brand_mobile_1
        ELSE b.brand_mobile_2
    END AS brand_mobile_label,
    u_created.full_name AS created_by_label,
    u_updated.full_name AS updated_by_label,
    -- Join with agency_brand_links for visit order if available
    abl.visit_order
FROM public.campaign c
LEFT JOIN public.agencies a ON c.campaign_agency_id = a.agency_id
LEFT JOIN public.brands b ON c.campaign_brand_id = b.brand_id
LEFT JOIN public.users u_created ON c.created_by = u_created.user_id
LEFT JOIN public.users u_updated ON c.updated_by = u_updated.user_id
LEFT JOIN public.agency_brand_links abl ON (c.campaign_agency_id = abl.agency_id AND c.campaign_brand_id = abl.brand_id);

COMMIT;

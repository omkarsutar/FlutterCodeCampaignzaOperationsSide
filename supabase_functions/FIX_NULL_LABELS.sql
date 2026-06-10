-- ============================================================================
-- FIX: NULL LABELS IN SECURITY INVOKER VIEWS
-- Issue: labels like brands_primary_agency_label are null when user lacks RLS access to target table
-- Solution: Use a non-security-invoker view for label lookups (public_agency_labels)
-- Date: June 9, 2026
-- ============================================================================

BEGIN;

-- 1. Create label views that bypass RLS (run as owner/postgres)
-- These views only expose ID and Name, which is safe for display purposes.
DROP VIEW IF EXISTS public.public_agency_labels CASCADE;
CREATE VIEW public.public_agency_labels AS
SELECT agency_id, agency_name, is_active FROM public.agencies;

ALTER VIEW public.public_agency_labels OWNER TO postgres;
GRANT SELECT ON TABLE public.public_agency_labels TO authenticated;
GRANT SELECT ON TABLE public.public_agency_labels TO service_role;

DROP VIEW IF EXISTS public.public_user_labels CASCADE;
CREATE VIEW public.public_user_labels AS
SELECT user_id, full_name FROM public.users;

ALTER VIEW public.public_user_labels OWNER TO postgres;
GRANT SELECT ON TABLE public.public_user_labels TO authenticated;
GRANT SELECT ON TABLE public.public_user_labels TO service_role;

-- 2. Update view_agency_brand_links to use public_agency_labels and public_user_labels
DROP VIEW IF EXISTS public.view_agency_brand_links CASCADE;
CREATE VIEW public.view_agency_brand_links
WITH (security_invoker='true') AS
 SELECT l.link_id,
    l.agency_id,
    l.brand_id,
    l.visit_order,
    l.created_at,
    l.updated_at,
    l.created_by,
    l.updated_by,
    r.agency_name AS agency_id_label,
    s.brand_name AS brand_id_label,
    s.brands_primary_agency,
    sr.agency_name AS brands_primary_agency_label,
    uc.full_name AS created_by_label,
    uu.full_name AS updated_by_label
   FROM agency_brand_links l
     LEFT JOIN public.public_agency_labels r ON l.agency_id = r.agency_id
     LEFT JOIN brands s ON l.brand_id = s.brand_id
     LEFT JOIN public.public_agency_labels sr ON s.brands_primary_agency = sr.agency_id
     LEFT JOIN public.public_user_labels uc ON l.created_by = uc.user_id
     LEFT JOIN public.public_user_labels uu ON l.updated_by = uu.user_id
  WHERE s.is_active = true 
    AND (r.is_active = true OR r.is_active IS NULL) 
    AND (sr.is_active = true OR sr.is_active IS NULL);

ALTER VIEW public.view_agency_brand_links OWNER TO postgres;
GRANT ALL ON TABLE public.view_agency_brand_links TO anon;
GRANT ALL ON TABLE public.view_agency_brand_links TO authenticated;
GRANT ALL ON TABLE public.view_agency_brand_links TO postgres;
GRANT ALL ON TABLE public.view_agency_brand_links TO service_role;

-- 3. Update view_brands to use public_agency_labels and public_user_labels
DROP VIEW IF EXISTS public.view_brands CASCADE;
CREATE VIEW public.view_brands
WITH (security_invoker='true') AS
 SELECT s.brand_id,
    s.brand_name,
    s.brands_primary_agency,
    s.brand_note,
    s.hidden_note,
    s.brand_mobile_1,
    s.brand_mobile_2,
    s.brand_person_name,
    s.is_active,
    s.brand_location_url,
    s.brand_landmark,
    s.brand_address,
    s.brand_photo_id,
    s.brand_photo_url,
    s.brand_lat,
    s.brand_long,
    s.created_at,
    s.updated_at,
    s.created_by,
    s.updated_by,
    s.android_app_id,
    s.website_url,
    r.agency_name AS brands_primary_agency_label,
    l.visit_order,
    uc.full_name AS created_by_label,
    uu.full_name AS updated_by_label
   FROM brands s
     LEFT JOIN public.public_agency_labels r ON s.brands_primary_agency = r.agency_id
     LEFT JOIN agency_brand_links l ON s.brand_id = l.brand_id AND s.brands_primary_agency = l.agency_id
     LEFT JOIN public.public_user_labels uc ON s.created_by = uc.user_id
     LEFT JOIN public.public_user_labels uu ON s.updated_by = uu.user_id
  WHERE s.is_active = true AND (r.is_active = true OR r.is_active IS NULL);

ALTER VIEW public.view_brands OWNER TO postgres;
GRANT ALL ON TABLE public.view_brands TO anon;
GRANT ALL ON TABLE public.view_brands TO authenticated;
GRANT ALL ON TABLE public.view_brands TO postgres;
GRANT ALL ON TABLE public.view_brands TO service_role;

-- 4. Update view_campaigns to use public_agency_labels and public_user_labels
DROP VIEW IF EXISTS public.view_campaigns CASCADE;
CREATE VIEW public.view_campaigns
WITH (security_invoker='true') AS
 SELECT c.campaign_id,
    c.campaign_name,
    c.campaign_name_string,
    c.collaboration_count,
    c.campaign_agency_id,
    c.campaign_brand_id,
    c.user_comment,
    c.admin_comment,
    c.status,
    c.valid_from,
    c.valid_until,
    c.created_by,
    c.updated_by,
    c.created_at,
    c.updated_at,
    c.referrer_links,
    c.campaign_type,
    r.agency_name AS campaign_agency_id_label,
    s.brand_name AS campaign_brand_id_label,
    s.brand_address AS brand_address_label,
    s.brand_note AS brand_note_label,
    s.brand_mobile_1 AS brand_mobile_label,
    uc.full_name AS created_by_label,
    uu.full_name AS updated_by_label,
    l.visit_order
   FROM campaign c
     LEFT JOIN public.public_agency_labels r ON c.campaign_agency_id = r.agency_id
     LEFT JOIN brands s ON c.campaign_brand_id = s.brand_id
     LEFT JOIN agency_brand_links l ON c.campaign_brand_id = l.brand_id AND c.campaign_agency_id = l.agency_id
     LEFT JOIN public.public_user_labels uc ON c.created_by = uc.user_id
     LEFT JOIN public.public_user_labels uu ON c.updated_by = uu.user_id;

ALTER VIEW public.view_campaigns OWNER TO postgres;
GRANT ALL ON TABLE public.view_campaigns TO anon;
GRANT ALL ON TABLE public.view_campaigns TO authenticated;
GRANT ALL ON TABLE public.view_campaigns TO postgres;
GRANT ALL ON TABLE public.view_campaigns TO service_role;

COMMIT;

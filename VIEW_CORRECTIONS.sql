-- ============================================================================
-- VIEW DEFINITION CORRECTIONS
-- Applied after schema migration
-- Date: June 8, 2026
-- ============================================================================

-- Transaction for safety
BEGIN;

-- ============================================================================
-- CRITICAL FIX: view_users (references dropped column)
-- ============================================================================

DROP VIEW IF EXISTS public.view_users CASCADE;

CREATE VIEW public.view_users AS
 SELECT u.user_id,
    u.full_name,
    u.role_id,
    u.user_language,
    u.created_at,
    u.updated_at,
    r.role_name AS role_id_label
   FROM users u
     LEFT JOIN rbac_roles r ON u.role_id = r.role_id;

ALTER VIEW public.view_users OWNER TO postgres;
GRANT ALL ON TABLE public.view_users TO anon;
GRANT ALL ON TABLE public.view_users TO authenticated;
GRANT ALL ON TABLE public.view_users TO postgres;
GRANT ALL ON TABLE public.view_users TO service_role;

-- ============================================================================
-- ENHANCEMENT: view_agency_brand_links (add missing audit fields)
-- ============================================================================

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
     LEFT JOIN agencies r ON l.agency_id = r.agency_id
     LEFT JOIN brands s ON l.brand_id = s.brand_id
     LEFT JOIN agencies sr ON s.brands_primary_agency = sr.agency_id
     LEFT JOIN users uc ON l.created_by = uc.user_id
     LEFT JOIN users uu ON l.updated_by = uu.user_id
  WHERE s.is_active = true AND (r.is_active = true OR r.is_active IS NULL) AND (sr.is_active = true OR sr.is_active IS NULL);

ALTER VIEW public.view_agency_brand_links OWNER TO postgres;
GRANT ALL ON TABLE public.view_agency_brand_links TO anon;
GRANT ALL ON TABLE public.view_agency_brand_links TO authenticated;
GRANT ALL ON TABLE public.view_agency_brand_links TO postgres;
GRANT ALL ON TABLE public.view_agency_brand_links TO service_role;

-- ============================================================================
-- ENHANCEMENT: view_brands (add missing audit fields)
-- ============================================================================

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
     LEFT JOIN agencies r ON s.brands_primary_agency = r.agency_id
     LEFT JOIN agency_brand_links l ON s.brand_id = l.brand_id AND s.brands_primary_agency = l.agency_id
     LEFT JOIN users uc ON s.created_by = uc.user_id
     LEFT JOIN users uu ON s.updated_by = uu.user_id
  WHERE s.is_active = true AND (r.is_active = true OR r.is_active IS NULL);

ALTER VIEW public.view_brands OWNER TO postgres;
GRANT ALL ON TABLE public.view_brands TO anon;
GRANT ALL ON TABLE public.view_brands TO authenticated;
GRANT ALL ON TABLE public.view_brands TO postgres;
GRANT ALL ON TABLE public.view_brands TO service_role;

-- ============================================================================
-- ENHANCEMENT: view_rbac_permissions (add missing audit fields)
-- ============================================================================

DROP VIEW IF EXISTS public.view_rbac_permissions CASCADE;

CREATE VIEW public.view_rbac_permissions AS
 SELECT p.permission_id,
    p.role_id,
    p.module_id,
    p.can_read,
    p.can_create,
    p.can_update,
    p.can_delete,
    p.created_at,
    p.updated_at,
    p.created_by,
    p.updated_by,
    r.role_name AS role_id_label,
    m.module_name AS module_id_label,
    uc.full_name AS created_by_label,
    uu.full_name AS updated_by_label
   FROM rbac_permissions p
     LEFT JOIN rbac_roles r ON p.role_id = r.role_id
     LEFT JOIN rbac_modules m ON p.module_id = m.module_id
     LEFT JOIN users uc ON p.created_by = uc.user_id
     LEFT JOIN users uu ON p.updated_by = uu.user_id;

ALTER VIEW public.view_rbac_permissions OWNER TO postgres;
GRANT ALL ON TABLE public.view_rbac_permissions TO anon;
GRANT ALL ON TABLE public.view_rbac_permissions TO authenticated;
GRANT ALL ON TABLE public.view_rbac_permissions TO postgres;
GRANT ALL ON TABLE public.view_rbac_permissions TO service_role;

-- ============================================================================
-- RE-CREATE UNCHANGED VIEWS (to maintain consistency)
-- ============================================================================

DROP VIEW IF EXISTS public.view_brand_dropdown CASCADE;

CREATE VIEW public.view_brand_dropdown
WITH (security_invoker='true') AS
 SELECT brand_id,
    brand_name
   FROM brands
  WHERE is_active = true
  ORDER BY brand_name;

ALTER VIEW public.view_brand_dropdown OWNER TO postgres;
GRANT ALL ON TABLE public.view_brand_dropdown TO anon;
GRANT ALL ON TABLE public.view_brand_dropdown TO authenticated;
GRANT ALL ON TABLE public.view_brand_dropdown TO postgres;
GRANT ALL ON TABLE public.view_brand_dropdown TO service_role;

-- ============================================================================

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
     LEFT JOIN agencies r ON c.campaign_agency_id = r.agency_id
     LEFT JOIN brands s ON c.campaign_brand_id = s.brand_id
     LEFT JOIN agency_brand_links l ON c.campaign_brand_id = l.brand_id AND c.campaign_agency_id = l.agency_id
     LEFT JOIN users uc ON c.created_by = uc.user_id
     LEFT JOIN users uu ON c.updated_by = uu.user_id;

ALTER VIEW public.view_campaigns OWNER TO postgres;
GRANT ALL ON TABLE public.view_campaigns TO anon;
GRANT ALL ON TABLE public.view_campaigns TO authenticated;
GRANT ALL ON TABLE public.view_campaigns TO postgres;
GRANT ALL ON TABLE public.view_campaigns TO service_role;

-- ============================================================================

DROP VIEW IF EXISTS public.view_collaborations CASCADE;

CREATE VIEW public.view_collaborations
WITH (security_invoker='true') AS
 SELECT c.collaboration_id,
    c.campaign_id,
    c.influencer_id,
    c.agreed_commission_amount,
    c.commission_type,
    c.commission_rate,
    c.fixed_amount,
    c.barter_description,
    c.is_accepted_by_influencer,
    c.created_by,
    c.updated_by,
    c.created_at,
    c.updated_at,
    c.promo_code,
    c.discount_percentage,
    c.is_active,
    i.influencer_name AS influencer_id_label,
    i.influencer_category AS influencer_category_label,
    i.influencer_image_url AS influencer_image_label,
    i.base_commission_rate AS base_commission_rate_label,
    cam.campaign_id AS campaign_id_label,
    uc.full_name AS created_by_label,
    uu.full_name AS updated_by_label,
    COALESCE(pc.purchase_count, 0::bigint) AS purchase_count,
    COALESCE(ic_ig.instagram_install_count, 0::bigint) AS instagram_install_count,
    COALESCE(ic_fb.facebook_install_count, 0::bigint) AS facebook_install_count
   FROM collaborations c
     LEFT JOIN influencer i ON c.influencer_id = i.influencer_id
     LEFT JOIN campaign cam ON c.campaign_id = cam.campaign_id
     LEFT JOIN users uc ON c.created_by = uc.user_id
     LEFT JOIN users uu ON c.updated_by = uu.user_id
     LEFT JOIN LATERAL ( SELECT count(*) AS purchase_count
           FROM app_purchases
          WHERE app_purchases.promo_code_applied = c.promo_code) pc ON true
     LEFT JOIN LATERAL ( SELECT count(*) AS instagram_install_count
           FROM app_install_tracking
          WHERE app_install_tracking.referrer_raw ~~ (('%utm_medium='::text || c.promo_code) || '%'::text) AND app_install_tracking.referrer_raw ~~ '%utm_source=instagram%'::text) ic_ig ON true
     LEFT JOIN LATERAL ( SELECT count(*) AS facebook_install_count
           FROM app_install_tracking
          WHERE app_install_tracking.referrer_raw ~~ (('%utm_medium='::text || c.promo_code) || '%'::text) AND app_install_tracking.referrer_raw ~~ '%utm_source=facebook%'::text) ic_fb ON true;

ALTER VIEW public.view_collaborations OWNER TO postgres;
GRANT ALL ON TABLE public.view_collaborations TO anon;
GRANT ALL ON TABLE public.view_collaborations TO authenticated;
GRANT ALL ON TABLE public.view_collaborations TO postgres;
GRANT ALL ON TABLE public.view_collaborations TO service_role;

-- ============================================================================

DROP VIEW IF EXISTS public.view_po_collections CASCADE;

CREATE VIEW public.view_po_collections AS
 SELECT pc.collection_id,
    pc.po_id,
    pc.collected_amount,
    pc.is_cash,
    pc.is_online,
    pc.is_cheque,
    pc.cheque_no,
    pc.is_sign,
    pc.sign_amount,
    pc.comments,
    pc.created_at,
    pc.updated_at,
    pc.created_by,
    pc.updated_by,
    c.status AS po_status_label,
    c.updated_at AS po_updated_at,
    s.brand_name AS brand_id_label,
    r.agency_name AS agency_id_label,
    uc.full_name AS created_by_label,
    uu.full_name AS updated_by_label
   FROM po_collections pc
     LEFT JOIN campaign c ON pc.po_id = c.campaign_id
     LEFT JOIN brands s ON c.campaign_brand_id = s.brand_id
     LEFT JOIN agencies r ON c.campaign_agency_id = r.agency_id
     LEFT JOIN users uc ON pc.created_by = uc.user_id
     LEFT JOIN users uu ON pc.updated_by = uu.user_id;

ALTER VIEW public.view_po_collections OWNER TO postgres;
GRANT ALL ON TABLE public.view_po_collections TO anon;
GRANT ALL ON TABLE public.view_po_collections TO authenticated;
GRANT ALL ON TABLE public.view_po_collections TO postgres;
GRANT ALL ON TABLE public.view_po_collections TO service_role;

-- ============================================================================

DROP VIEW IF EXISTS public.view_products CASCADE;

CREATE VIEW public.view_products AS
 SELECT i.influencer_id,
    i.influencer_category,
    i.influencer_name,
    i.influencer_name_hindi,
    i.base_commission_rate,
    i.is_active,
    i.is_available,
    i.influencer_image_url,
    i.created_by,
    i.updated_by,
    i.created_at,
    i.updated_at,
    uc.full_name AS created_by_label,
    uu.full_name AS updated_by_label
   FROM influencer i
     LEFT JOIN users uc ON i.created_by = uc.user_id
     LEFT JOIN users uu ON i.updated_by = uu.user_id
  WHERE i.is_active = true;

ALTER VIEW public.view_products OWNER TO postgres;
GRANT ALL ON TABLE public.view_products TO anon;
GRANT ALL ON TABLE public.view_products TO authenticated;
GRANT ALL ON TABLE public.view_products TO postgres;
GRANT ALL ON TABLE public.view_products TO service_role;

-- ============================================================================

DROP VIEW IF EXISTS public.view_retailer_brand_link CASCADE;

CREATE VIEW public.view_retailer_brand_link AS
 SELECT rsl.link_id,
    rsl.user_id,
    rsl.brand_id,
    rsl.created_at,
    rsl.updated_at,
    rsl.created_by,
    rsl.updated_by,
    u.full_name AS user_id_label,
    rr.role_name AS user_role_label,
    s.brand_name AS brand_id_label,
    r.agency_name AS brand_agency_label
   FROM retailer_brand_link rsl
     LEFT JOIN users u ON rsl.user_id = u.user_id
     LEFT JOIN rbac_roles rr ON u.role_id = rr.role_id
     LEFT JOIN brands s ON rsl.brand_id = s.brand_id
     LEFT JOIN agencies r ON s.brands_primary_agency = r.agency_id;

ALTER VIEW public.view_retailer_brand_link OWNER TO postgres;
GRANT ALL ON TABLE public.view_retailer_brand_link TO anon;
GRANT ALL ON TABLE public.view_retailer_brand_link TO authenticated;
GRANT ALL ON TABLE public.view_retailer_brand_link TO postgres;
GRANT ALL ON TABLE public.view_retailer_brand_link TO service_role;

-- ============================================================================

DROP VIEW IF EXISTS public.view_user_agency_link CASCADE;

CREATE VIEW public.view_user_agency_link
WITH (security_invoker='true') AS
 SELECT ual.link_id,
    ual.user_id,
    ual.agency_id,
    ual.created_at,
    ual.updated_at,
    ual.created_by,
    ual.updated_by,
    u.full_name AS user_id_label,
    rr.role_name AS user_role_label,
    a.agency_name AS agency_id_label
   FROM user_agency_link ual
     LEFT JOIN users u ON ual.user_id = u.user_id
     LEFT JOIN rbac_roles rr ON u.role_id = rr.role_id
     LEFT JOIN agencies a ON ual.agency_id = a.agency_id;

ALTER VIEW public.view_user_agency_link OWNER TO postgres;
GRANT ALL ON TABLE public.view_user_agency_link TO anon;
GRANT ALL ON TABLE public.view_user_agency_link TO authenticated;
GRANT ALL ON TABLE public.view_user_agency_link TO postgres;
GRANT ALL ON TABLE public.view_user_agency_link TO service_role;

-- ============================================================================

DROP VIEW IF EXISTS public.view_user_influencer_link CASCADE;

CREATE VIEW public.view_user_influencer_link
WITH (security_invoker='true') AS
 SELECT uil.link_id,
    uil.user_id,
    uil.influencer_id,
    uil.created_at,
    uil.updated_at,
    uil.created_by,
    uil.updated_by,
    u.full_name AS user_id_label,
    rr.role_name AS user_role_label,
    a.influencer_name AS influencer_id_label
   FROM user_influencer_link uil
     LEFT JOIN users u ON uil.user_id = u.user_id
     LEFT JOIN rbac_roles rr ON u.role_id = rr.role_id
     LEFT JOIN influencer a ON uil.influencer_id = a.influencer_id;

ALTER VIEW public.view_user_influencer_link OWNER TO postgres;
GRANT ALL ON TABLE public.view_user_influencer_link TO anon;
GRANT ALL ON TABLE public.view_user_influencer_link TO authenticated;
GRANT ALL ON TABLE public.view_user_influencer_link TO postgres;
GRANT ALL ON TABLE public.view_user_influencer_link TO service_role;

-- ============================================================================
-- VERIFICATION QUERIES
-- ============================================================================

-- Verify all views exist
SELECT viewname FROM pg_views WHERE schemaname = 'public' ORDER BY viewname;

-- Verify view_users doesn't reference dropped column
SELECT column_name FROM information_schema.columns 
WHERE table_schema = 'public' AND table_name = 'view_users' 
ORDER BY column_name;

-- ============================================================================
-- COMMIT TRANSACTION
-- ============================================================================

COMMIT;

-- ============================================================================
-- VIEW CORRECTIONS COMPLETE
-- ============================================================================
-- Summary of changes:
-- ✅ Fixed view_users (removed preferred_agency_id references)
-- ✅ Enhanced view_agency_brand_links (added audit fields)
-- ✅ Enhanced view_brands (added audit fields)
-- ✅ Enhanced view_rbac_permissions (added audit fields)
-- ✅ Recreated all other views for consistency
-- ============================================================================

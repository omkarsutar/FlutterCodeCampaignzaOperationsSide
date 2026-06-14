BEGIN;

-- 1. Create the new referrer_links table
CREATE TABLE IF NOT EXISTS public.referrer_links (
    referrer_link_id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    referrer_link_string text UNIQUE NOT NULL,
    referrer_link_type text NOT NULL CHECK (referrer_link_type IN ('plain', 'qrcode')),
    campaign_id uuid REFERENCES public.campaign(campaign_id) ON DELETE CASCADE,
    campaign_type text NOT NULL,
    collaboration_id uuid REFERENCES public.collaborations(collaboration_id) ON DELETE CASCADE,
    referrer_link_source text NOT NULL,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    created_by uuid,
    updated_by uuid
);

-- 2. Enable RLS on the new table
ALTER TABLE public.referrer_links ENABLE ROW LEVEL SECURITY;

-- Create policies for RLS
DROP POLICY IF EXISTS "Allow authenticated users all operations" ON public.referrer_links;
CREATE POLICY "Allow authenticated users all operations" 
    ON public.referrer_links 
    FOR ALL 
    TO authenticated 
    USING (true) 
    WITH CHECK (true);

-- 3. Update view_campaigns to remove references to the c.referrer_links column
DROP VIEW IF EXISTS public.view_campaigns CASCADE;

CREATE VIEW public.view_campaigns WITH (security_invoker='true') AS
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
    c.campaign_type,
    r.agency_name AS campaign_agency_id_label,
    s.brand_name AS campaign_brand_id_label,
    s.brand_address AS brand_address_label,
    s.brand_note AS brand_note_label,
    s.brand_mobile_1 AS brand_mobile_label,
    uc.full_name AS created_by_label,
    uu.full_name AS updated_by_label,
    l.visit_order
   FROM (((((public.campaign c
     LEFT JOIN public.public_agency_labels r ON ((c.campaign_agency_id = r.agency_id)))
     LEFT JOIN public.brands s ON ((c.campaign_brand_id = s.brand_id)))
     LEFT JOIN public.agency_brand_links l ON (((c.campaign_brand_id = l.brand_id) AND (c.campaign_agency_id = l.agency_id))))
     LEFT JOIN public.public_user_labels uc ON ((c.created_by = uc.user_id)))
     LEFT JOIN public.public_user_labels uu ON ((c.updated_by = uu.user_id)));

-- 4. Recreate dependent view view_po_collections
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

-- 5. Drop the old column from campaign table
ALTER TABLE public.campaign DROP COLUMN IF EXISTS referrer_links;

COMMIT;

-- ============================================================================
-- FIX: Enhance User View with Email and Photo
-- Purpose: Update public.users table and view_users to include email 
--          from auth.users and a photo URL field.
-- Date: June 10, 2026
-- ============================================================================

BEGIN;

-- 1. Add user_photo_url to public.users if it doesn't exist
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'users' AND column_name = 'user_photo_url') THEN
        ALTER TABLE public.users ADD COLUMN user_photo_url TEXT;
    END IF;
END $$;

-- 2. Update view_users to include email from auth.users and the new photo URL
-- Note: This requires the view to be dropped and recreated to change columns.
DROP VIEW IF EXISTS public.view_users;

CREATE VIEW public.view_users AS
 SELECT u.user_id,
    u.full_name,
    u.role_id,
    u.user_language,
    u.user_photo_url,
    u.created_at,
    u.updated_at,
    r.role_name AS role_id_label,
    au.email AS email
   FROM public.users u
     LEFT JOIN public.rbac_roles r ON u.role_id = r.role_id
     LEFT JOIN auth.users au ON u.user_id = au.id;

ALTER VIEW public.view_users OWNER TO postgres;

-- 3. Update public_user_labels for consistency (optional)
DROP VIEW IF EXISTS public.public_user_labels;
CREATE VIEW public.public_user_labels AS
 SELECT user_id,
    full_name,
    user_photo_url
   FROM public.users;

COMMIT;

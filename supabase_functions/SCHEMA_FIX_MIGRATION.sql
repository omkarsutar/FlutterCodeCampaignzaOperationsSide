-- ============================================================================
-- SUPABASE SCHEMA MIGRATION SCRIPT
-- Purpose: Fix RLS policies, audit fields, constraints, and design issues
-- Date: June 7, 2026
-- ============================================================================

-- Transaction wrapper for safety
BEGIN;

-- ============================================================================
-- SECTION 1: FIX CONSTRAINT ISSUES
-- ============================================================================

-- Fix: collaborations discount_percentage check (allow 0%)
ALTER TABLE public.collaborations 
  DROP CONSTRAINT collaborations_discount_percentage_check;

ALTER TABLE public.collaborations 
  ADD CONSTRAINT collaborations_discount_percentage_check 
    CHECK ((discount_percentage >= 0) AND (discount_percentage <= 100));

-- ============================================================================
-- SECTION 2: STANDARDIZE FOREIGN KEY DELETE RULES
-- ============================================================================

-- Fix: po_collections - standardize FK delete actions to SET NULL
ALTER TABLE public.po_collections 
  DROP CONSTRAINT po_collections_created_by_fkey,
  DROP CONSTRAINT po_collections_updated_by_fkey;

ALTER TABLE public.po_collections
  ADD CONSTRAINT po_collections_created_by_fkey 
    FOREIGN KEY (created_by) REFERENCES public.users(user_id) ON DELETE SET NULL,
  ADD CONSTRAINT po_collections_updated_by_fkey 
    FOREIGN KEY (updated_by) REFERENCES public.users(user_id) ON DELETE SET NULL;

-- ============================================================================
-- SECTION 3: CLEAN UP USERS TABLE
-- ============================================================================

-- Drop preferred_agency_id (not required)
ALTER TABLE public.users 
  DROP CONSTRAINT users_preferred_agency_id_fkey;

ALTER TABLE public.users 
  DROP COLUMN IF EXISTS preferred_agency_id;

-- ============================================================================
-- SECTION 4: ADD MISSING AUDIT FIELDS
-- ============================================================================

-- Add created_by/updated_by to agencies table
ALTER TABLE public.agencies 
  ADD COLUMN created_by uuid,
  ADD COLUMN updated_by uuid,
  ADD CONSTRAINT agencies_created_by_fkey 
    FOREIGN KEY (created_by) REFERENCES public.users(user_id) ON DELETE SET NULL,
  ADD CONSTRAINT agencies_updated_by_fkey 
    FOREIGN KEY (updated_by) REFERENCES public.users(user_id) ON DELETE SET NULL;

-- Add created_by/updated_by to brands table
ALTER TABLE public.brands 
  ADD COLUMN created_by uuid,
  ADD COLUMN updated_by uuid,
  ADD CONSTRAINT brands_created_by_fkey 
    FOREIGN KEY (created_by) REFERENCES public.users(user_id) ON DELETE SET NULL,
  ADD CONSTRAINT brands_updated_by_fkey 
    FOREIGN KEY (updated_by) REFERENCES public.users(user_id) ON DELETE SET NULL;

-- Add created_by/updated_by to app_config table
ALTER TABLE public.app_config 
  ADD COLUMN created_by uuid,
  ADD COLUMN updated_by uuid,
  ADD CONSTRAINT app_config_created_by_fkey 
    FOREIGN KEY (created_by) REFERENCES public.users(user_id) ON DELETE SET NULL,
  ADD CONSTRAINT app_config_updated_by_fkey 
    FOREIGN KEY (updated_by) REFERENCES public.users(user_id) ON DELETE SET NULL;

-- Add created_by/updated_by to rbac_modules table
ALTER TABLE public.rbac_modules 
  ADD COLUMN created_by uuid,
  ADD COLUMN updated_by uuid,
  ADD CONSTRAINT rbac_modules_created_by_fkey 
    FOREIGN KEY (created_by) REFERENCES public.users(user_id) ON DELETE SET NULL,
  ADD CONSTRAINT rbac_modules_updated_by_fkey 
    FOREIGN KEY (updated_by) REFERENCES public.users(user_id) ON DELETE SET NULL;

-- Add created_by/updated_by to rbac_permissions table
ALTER TABLE public.rbac_permissions 
  ADD COLUMN created_by uuid,
  ADD COLUMN updated_by uuid,
  ADD CONSTRAINT rbac_permissions_created_by_fkey 
    FOREIGN KEY (created_by) REFERENCES public.users(user_id) ON DELETE SET NULL,
  ADD CONSTRAINT rbac_permissions_updated_by_fkey 
    FOREIGN KEY (updated_by) REFERENCES public.users(user_id) ON DELETE SET NULL;

-- Add created_by/updated_by to rbac_roles table
ALTER TABLE public.rbac_roles 
  ADD COLUMN created_by uuid,
  ADD COLUMN updated_by uuid,
  ADD CONSTRAINT rbac_roles_created_by_fkey 
    FOREIGN KEY (created_by) REFERENCES public.users(user_id) ON DELETE SET NULL,
  ADD CONSTRAINT rbac_roles_updated_by_fkey 
    FOREIGN KEY (updated_by) REFERENCES public.users(user_id) ON DELETE SET NULL;

-- Add created_by/updated_by to tbl_notes table
ALTER TABLE public.tbl_notes 
  ADD COLUMN created_by uuid NOT NULL DEFAULT auth.uid(),
  ADD COLUMN updated_by uuid NOT NULL DEFAULT auth.uid(),
  ADD CONSTRAINT tbl_notes_created_by_fkey 
    FOREIGN KEY (created_by) REFERENCES public.users(user_id) ON DELETE SET NULL,
  ADD CONSTRAINT tbl_notes_updated_by_fkey 
    FOREIGN KEY (updated_by) REFERENCES public.users(user_id) ON DELETE SET NULL;

-- Add missing audit fields to agency_brand_links
ALTER TABLE public.agency_brand_links 
  ADD COLUMN created_by uuid,
  ADD COLUMN updated_by uuid,
  ADD CONSTRAINT agency_brand_links_created_by_fkey 
    FOREIGN KEY (created_by) REFERENCES public.users(user_id) ON DELETE SET NULL,
  ADD CONSTRAINT agency_brand_links_updated_by_fkey 
    FOREIGN KEY (updated_by) REFERENCES public.users(user_id) ON DELETE SET NULL;

-- ============================================================================
-- SECTION 5: FIX GUEST_ROLE_ID TABLE
-- ============================================================================

-- Drop and recreate guest_role_id with proper constraints
DROP TABLE IF EXISTS public.guest_role_id;

CREATE TABLE public.guest_role_id (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    role_id uuid NOT NULL UNIQUE,
    created_at timestamp with time zone DEFAULT now(),
    CONSTRAINT guest_role_id_role_id_fkey 
        FOREIGN KEY (role_id) REFERENCES public.rbac_roles(role_id) ON DELETE CASCADE
);

ALTER TABLE public.guest_role_id OWNER TO postgres;

-- ============================================================================
-- SECTION 6: ADD RLS POLICIES TO TABLES MISSING THEM
-- ============================================================================

-- ============================================================================
-- RLS for influencer table (HIGH RISK - currently no policies)
-- ============================================================================

ALTER TABLE public.influencer ENABLE ROW LEVEL SECURITY;

-- Admins can do everything on influencers
CREATE POLICY influencer_admin_policy ON public.influencer
  TO authenticated
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

-- All authenticated users can SELECT influencers (read-only for collaborations)
CREATE POLICY influencer_select_policy ON public.influencer
  FOR SELECT
  TO authenticated
  USING (true);

-- ============================================================================
-- RLS for po_collections table (HIGH RISK - currently no policies)
-- ============================================================================

ALTER TABLE public.po_collections ENABLE ROW LEVEL SECURITY;

-- Admins can do everything
CREATE POLICY po_collections_admin_policy ON public.po_collections
  TO authenticated
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

-- Users can manage their own campaign collections
CREATE POLICY po_collections_campaign_owner_policy ON public.po_collections
  FOR ALL
  TO authenticated
  USING (
    po_id IN (
      SELECT campaign_id FROM campaign 
      WHERE campaign_agency_id IN (
        SELECT agency_id FROM user_agency_link WHERE user_id = auth.uid()
      )
    )
  )
  WITH CHECK (
    po_id IN (
      SELECT campaign_id FROM campaign 
      WHERE campaign_agency_id IN (
        SELECT agency_id FROM user_agency_link WHERE user_id = auth.uid()
      )
    )
  );

-- ============================================================================
-- RLS for tbl_notes table (HIGH RISK - currently no policies)
-- ============================================================================

ALTER TABLE public.tbl_notes ENABLE ROW LEVEL SECURITY;

-- Admins can do everything
CREATE POLICY tbl_notes_admin_policy ON public.tbl_notes
  TO authenticated
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

-- Users can read and modify their own notes
CREATE POLICY tbl_notes_user_policy ON public.tbl_notes
  FOR ALL
  TO authenticated
  USING (created_by = auth.uid())
  WITH CHECK (created_by = auth.uid());

-- ============================================================================
-- RLS for retailer_brand_link table (HIGH RISK - currently no policies)
-- ============================================================================

ALTER TABLE public.retailer_brand_link ENABLE ROW LEVEL SECURITY;

-- Admins can do everything
CREATE POLICY retailer_brand_link_admin_policy ON public.retailer_brand_link
  TO authenticated
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

-- Users can manage their own retailer-brand links
CREATE POLICY retailer_brand_link_user_policy ON public.retailer_brand_link
  FOR ALL
  TO authenticated
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

-- ============================================================================
-- RLS for users table (CRITICAL - currently no policies)
-- ============================================================================

ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

-- Admins can do everything on users
CREATE POLICY users_admin_policy ON public.users
  TO authenticated
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

-- Users can only read their own profile
CREATE POLICY users_read_own_policy ON public.users
  FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());

-- Users can only update their own profile
CREATE POLICY users_update_own_policy ON public.users
  FOR UPDATE
  TO authenticated
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

-- ============================================================================
-- RLS for rbac_modules table (MEDIUM RISK - currently no policies)
-- ============================================================================

ALTER TABLE public.rbac_modules ENABLE ROW LEVEL SECURITY;

-- Admins can do everything
CREATE POLICY rbac_modules_admin_policy ON public.rbac_modules
  TO authenticated
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

-- All authenticated users can read modules
CREATE POLICY rbac_modules_select_policy ON public.rbac_modules
  FOR SELECT
  TO authenticated
  USING (true);

-- ============================================================================
-- RLS for rbac_permissions table (MEDIUM RISK - currently no policies)
-- ============================================================================

ALTER TABLE public.rbac_permissions ENABLE ROW LEVEL SECURITY;

-- Admins can do everything
CREATE POLICY rbac_permissions_admin_policy ON public.rbac_permissions
  TO authenticated
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

-- All authenticated users can read permissions for their role
CREATE POLICY rbac_permissions_select_policy ON public.rbac_permissions
  FOR SELECT
  TO authenticated
  USING (
    role_id IN (
      SELECT role_id FROM users WHERE user_id = auth.uid()
    )
  );

-- ============================================================================
-- RLS for rbac_roles table (MEDIUM RISK - currently no policies)
-- ============================================================================

ALTER TABLE public.rbac_roles ENABLE ROW LEVEL SECURITY;

-- Admins can do everything
CREATE POLICY rbac_roles_admin_policy ON public.rbac_roles
  TO authenticated
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

-- All authenticated users can read active roles
CREATE POLICY rbac_roles_select_policy ON public.rbac_roles
  FOR SELECT
  TO authenticated
  USING (is_active = true);

-- ============================================================================
-- RLS for agency_brand_links table (MEDIUM RISK - currently no policies)
-- ============================================================================

ALTER TABLE public.agency_brand_links ENABLE ROW LEVEL SECURITY;

-- Admins can do everything
CREATE POLICY agency_brand_links_admin_policy ON public.agency_brand_links
  TO authenticated
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

-- Users can see links for their agencies
CREATE POLICY agency_brand_links_select_policy ON public.agency_brand_links
  FOR SELECT
  TO authenticated
  USING (
    agency_id IN (
      SELECT agency_id FROM user_agency_link WHERE user_id = auth.uid()
    )
  );

-- ============================================================================
-- RLS for app_config table (MEDIUM RISK - currently no policies)
-- ============================================================================

ALTER TABLE public.app_config ENABLE ROW LEVEL SECURITY;

-- Admins can do everything
CREATE POLICY app_config_admin_policy ON public.app_config
  TO authenticated
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

-- All authenticated users can read app config (immutable settings)
CREATE POLICY app_config_select_policy ON public.app_config
  FOR SELECT
  TO authenticated
  USING (true);

-- ============================================================================
-- RLS for guest_role_id table (MEDIUM RISK - currently no policies)
-- ============================================================================

ALTER TABLE public.guest_role_id ENABLE ROW LEVEL SECURITY;

-- Admins can do everything
CREATE POLICY guest_role_id_admin_policy ON public.guest_role_id
  TO authenticated
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

-- All authenticated users can read guest role (for form dropdowns)
CREATE POLICY guest_role_id_select_policy ON public.guest_role_id
  FOR SELECT
  TO authenticated
  USING (true);

-- ============================================================================
-- SECTION 7: UPDATE EXISTING TRIGGERS FOR NEW AUDIT FIELDS
-- ============================================================================

-- Attach set_created_updated_by trigger to agencies
DROP TRIGGER IF EXISTS set_created_updated_by_on_agencies ON public.agencies;
CREATE TRIGGER set_created_updated_by_on_agencies
  BEFORE INSERT OR UPDATE ON public.agencies
  FOR EACH ROW
  EXECUTE FUNCTION public.set_created_updated_by();

-- Attach set_created_updated_by trigger to brands
DROP TRIGGER IF EXISTS set_created_updated_by_on_brands ON public.brands;
CREATE TRIGGER set_created_updated_by_on_brands
  BEFORE INSERT OR UPDATE ON public.brands
  FOR EACH ROW
  EXECUTE FUNCTION public.set_created_updated_by();

-- Attach set_created_updated_by trigger to app_config
DROP TRIGGER IF EXISTS set_created_updated_by_on_app_config ON public.app_config;
CREATE TRIGGER set_created_updated_by_on_app_config
  BEFORE INSERT OR UPDATE ON public.app_config
  FOR EACH ROW
  EXECUTE FUNCTION public.set_created_updated_by();

-- Attach set_created_updated_by trigger to rbac_modules
DROP TRIGGER IF EXISTS set_created_updated_by_on_rbac_modules ON public.rbac_modules;
CREATE TRIGGER set_created_updated_by_on_rbac_modules
  BEFORE INSERT OR UPDATE ON public.rbac_modules
  FOR EACH ROW
  EXECUTE FUNCTION public.set_created_updated_by();

-- Attach set_created_updated_by trigger to rbac_permissions
DROP TRIGGER IF EXISTS set_created_updated_by_on_rbac_permissions ON public.rbac_permissions;
CREATE TRIGGER set_created_updated_by_on_rbac_permissions
  BEFORE INSERT OR UPDATE ON public.rbac_permissions
  FOR EACH ROW
  EXECUTE FUNCTION public.set_created_updated_by();

-- Attach set_created_updated_by trigger to rbac_roles
DROP TRIGGER IF EXISTS set_created_updated_by_on_rbac_roles ON public.rbac_roles;
CREATE TRIGGER set_created_updated_by_on_rbac_roles
  BEFORE INSERT OR UPDATE ON public.rbac_roles
  FOR EACH ROW
  EXECUTE FUNCTION public.set_created_updated_by();

-- Attach set_created_updated_by trigger to tbl_notes
DROP TRIGGER IF EXISTS set_created_updated_by_on_tbl_notes ON public.tbl_notes;
CREATE TRIGGER set_created_updated_by_on_tbl_notes
  BEFORE INSERT OR UPDATE ON public.tbl_notes
  FOR EACH ROW
  EXECUTE FUNCTION public.set_created_updated_by();

-- Attach set_created_updated_by trigger to agency_brand_links
DROP TRIGGER IF EXISTS set_created_updated_by_on_agency_brand_links ON public.agency_brand_links;
CREATE TRIGGER set_created_updated_by_on_agency_brand_links
  BEFORE INSERT OR UPDATE ON public.agency_brand_links
  FOR EACH ROW
  EXECUTE FUNCTION public.set_created_updated_by();

-- ============================================================================
-- SECTION 8: VERIFY SETUP
-- ============================================================================

-- Verify all required policies exist
SELECT 
  schemaname,
  tablename,
  array_agg(policyname) as policies
FROM pg_policies
WHERE schemaname = 'public'
GROUP BY schemaname, tablename
ORDER BY tablename;

-- Check RLS enabled on all tables
SELECT 
  schemaname,
  tablename,
  rowsecurity as rls_enabled
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY tablename;

-- ============================================================================
-- COMMIT TRANSACTION
-- ============================================================================

COMMIT;

-- ============================================================================
-- MIGRATION COMPLETE
-- ============================================================================
-- Summary of changes:
-- ✅ Fixed discount_percentage check constraint
-- ✅ Standardized FK delete rules for po_collections
-- ✅ Removed preferred_agency_id from users table
-- ✅ Added created_by/updated_by to 9 tables
-- ✅ Added RLS policies to 10 tables
-- ✅ Fixed guest_role_id table design
-- ✅ Attached triggers to new audit fields
-- 
-- Excluded (no changes):
-- ✅ app_install_tracking
-- ✅ app_purchases
-- ============================================================================

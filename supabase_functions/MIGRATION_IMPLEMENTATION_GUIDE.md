# Schema Migration Implementation Guide

## Overview
This guide walks you through applying the schema migration script (`SCHEMA_FIX_MIGRATION.sql`) to your Supabase database.

---

## 📋 Pre-Migration Checklist

- [ ] Backup your Supabase database (automatic in Supabase, but good to verify)
- [ ] Review all changes in the migration script
- [ ] Test in a development/staging environment first
- [ ] Schedule during low-traffic period
- [ ] Have a rollback plan (keep previous backup)

---

## 🚀 How to Apply Migration

### **Option 1: Using Supabase SQL Editor (Recommended for Supabase)**

1. **Login to Supabase Dashboard**
   - Go to https://app.supabase.com
   - Select your project
   - Navigate to "SQL Editor"

2. **Create New Query**
   - Click "+ New Query"
   - Open `SCHEMA_FIX_MIGRATION.sql` from this project
   - Copy the entire contents
   - Paste into the editor

3. **Review and Execute**
   - Review the highlighted SQL
   - Click "Run" (⚡ button)
   - Wait for completion (should take 30-60 seconds)

4. **Verify Success**
   - Look for green checkmarks
   - Check the "Results" panel for any errors
   - Run verification queries (provided at end of script)

---

### **Option 2: Using psql (Command Line)**

```bash
# Get your Supabase connection details from Dashboard → Settings → Database
# Then run:

psql -h <PROJECT_ID>.supabase.co \
     -U postgres \
     -d postgres \
     -f SCHEMA_FIX_MIGRATION.sql
```

You'll be prompted for the password (your Supabase database password).

---

### **Option 3: Using pgAdmin (if configured)**

1. Right-click your database → "Query Tool"
2. Copy-paste the migration script
3. Click "Execute" / "F5"
4. Review results

---

## 📊 What Gets Changed

### **Section 1: Constraint Fixes**
✅ Fixes discount percentage check to allow 0%  
- **Impact:** Minimum, no data loss

### **Section 2: Foreign Key Standardization**
✅ Standardizes `po_collections` FK delete rules to `SET NULL`  
- **Impact:** Affects delete behavior going forward, no data loss

### **Section 3: Column Cleanup**
✅ Removes `preferred_agency_id` from `users` table  
- **Impact:** Data loss if column had values (recommend backing up first)

### **Section 4: Audit Field Addition**
✅ Adds `created_by` and `updated_by` to 9 tables:
- agencies
- brands
- app_config
- rbac_modules
- rbac_permissions
- rbac_roles
- tbl_notes
- agency_brand_links
- (po_collections already had these, now just fixed)

- **Impact:** Minimal - columns added as NULLABLE (can be populated later)
- **Exception:** `tbl_notes` defaults to `auth.uid()` (prevents NULL)

### **Section 5: Table Redesign**
✅ Fixes `guest_role_id` table:
- Adds proper primary key
- Adds foreign key to rbac_roles
- Adds created_at timestamp

- **Impact:** Table recreation (if had data, it will be lost - consider backing up)

### **Section 6: RLS Policy Addition**
✅ Enables RLS and adds policies for 10 tables:
- influencer
- po_collections
- tbl_notes
- retailer_brand_link
- users
- rbac_modules
- rbac_permissions
- rbac_roles
- agency_brand_links
- app_config
- guest_role_id

- **Impact:** Changes data access patterns - MUST TEST WITH YOUR USERS

### **Section 7: Trigger Setup**
✅ Attaches `set_created_updated_by()` trigger to new audit fields  
- **Impact:** Auto-population of created_by/updated_by on new records

---

## ⚠️ Important Warnings

### **Before Running Migration:**

1. **Test in Development First**
   - Never run untested migrations on production
   - Create a test branch or staging environment
   - Verify RLS policies don't block legitimate access

2. **Backup Your Data**
   ```sql
   -- Optional: Export critical table data before migration
   -- Example for agencies:
   CREATE TABLE agencies_backup_2026_06_07 AS SELECT * FROM agencies;
   CREATE TABLE users_backup_2026_06_07 AS SELECT * FROM users;
   ```

3. **Review RLS Policies**
   - The RLS policies may block some operations
   - Test with different user roles (admin vs regular user)
   - Adjust `is_admin()` function if needed

4. **Data Loss Risk**
   - `preferred_agency_id` column drop: If it had data, it's lost
   - `guest_role_id` table recreation: If it had data, it's lost
   - **Recommendation:** Query these first:
     ```sql
     SELECT COUNT(*), COUNT(preferred_agency_id) FROM users;
     SELECT * FROM guest_role_id;
     ```

---

## ✅ Post-Migration Verification

### **Run These Queries to Verify Success:**

```sql
-- 1. Verify RLS is enabled on all tables
SELECT tablename, rowsecurity 
FROM pg_tables 
WHERE schemaname = 'public' 
ORDER BY tablename;

-- Should show: rowsecurity = true for ~19 tables

-- 2. Verify policies exist
SELECT policyname, tablename 
FROM pg_policies 
WHERE schemaname = 'public' 
ORDER BY tablename;

-- Should show multiple policies per table

-- 3. Verify audit fields exist
SELECT table_name, column_name 
FROM information_schema.columns 
WHERE table_schema = 'public' 
AND column_name IN ('created_by', 'updated_by')
ORDER BY table_name;

-- Should show new columns

-- 4. Verify FK constraints
SELECT constraint_name, table_name, column_name 
FROM information_schema.key_column_usage 
WHERE table_schema = 'public' 
AND column_name IN ('created_by', 'updated_by')
ORDER BY table_name;

-- Should show all FK relationships

-- 5. Test RLS with sample user
-- (Requires authenticated session with specific user_id)
SELECT * FROM agencies; -- Should only see user's agencies
SELECT * FROM users; -- Should only see your own user record
```

---

## 🔧 Troubleshooting

### **Issue: "Permission denied" error**

**Cause:** Your database user doesn't have admin privileges

**Solution:** 
- Use `postgres` user (superuser) instead
- Contact Supabase support to grant necessary permissions

---

### **Issue: "Relation already exists" error**

**Cause:** Migration partially ran or ran twice

**Solution:**
```sql
-- Option 1: Drop and retry (if safe)
DROP POLICY IF EXISTS policy_name ON table_name;

-- Option 2: Just continue - the constraint already exists
-- (Run verification queries to confirm state)
```

---

### **Issue: RLS blocks all reads after migration**

**Cause:** RLS policies are too restrictive or `is_admin()` returns false

**Solution:**
```sql
-- Temporarily disable RLS to debug
ALTER TABLE table_name DISABLE ROW LEVEL SECURITY;

-- Query the is_admin() function
SELECT public.is_admin(); -- Should return true if you're admin

-- Re-enable after debugging
ALTER TABLE table_name ENABLE ROW LEVEL SECURITY;
```

---

### **Issue: Foreign key constraint violations**

**Cause:** Trying to add FK but reference table has invalid data

**Solution:**
```sql
-- Check for NULL values in reference columns
SELECT * FROM po_collections WHERE po_id IS NULL;

-- Clean up invalid data first, then retry
DELETE FROM po_collections WHERE po_id IS NULL;

-- Then re-run the migration
```

---

## 📈 Performance Impact

| Operation | Impact | Duration |
|-----------|--------|----------|
| Adding columns | Minimal | < 1 second |
| Adding RLS policies | Minimal | < 1 second |
| Adding foreign keys | Low | 1-5 seconds |
| Creating triggers | Minimal | < 1 second |
| **Total** | **Low** | **~30-60 seconds** |

**Recommendation:** Run during off-peak hours just in case.

---

## 🔙 Rollback Plan

If something goes wrong, you can rollback using Supabase's backup:

1. **Automatic Backups (Supabase Free Plan)**
   - Daily automated backups available
   - Kept for 7 days
   - Restore from Dashboard → Backups → "Restore"

2. **Manual Backup Before Migration**
   ```bash
   # Create a backup of the entire database
   pg_dump -h <PROJECT>.supabase.co -U postgres -d postgres \
     > backup_before_migration_$(date +%Y%m%d_%H%M%S).sql
   ```

3. **Quick Rollback via Supabase**
   - Dashboard → Settings → Backups
   - Select backup before migration
   - Click "Restore to new project" or "Restore"

---

## 🧪 Testing the Migration in Development

```sql
-- Create test users
INSERT INTO public.users (user_id, full_name) 
VALUES ('test-user-1', 'Test User 1');

-- Test RLS policy for influencer
SELECT * FROM influencer; -- All users can read

-- Test RLS policy for users
SELECT * FROM users 
WHERE user_id = auth.uid(); -- Should only return self

-- Test audit field triggers
INSERT INTO agencies (agency_name, is_active) 
VALUES ('Test Agency', true);

-- Verify created_by/updated_by were auto-populated
SELECT agency_id, agency_name, created_by, updated_by 
FROM agencies 
WHERE agency_name = 'Test Agency';

-- Verify discount check allows 0%
INSERT INTO collaborations (
  collaboration_id, 
  campaign_id, 
  influencer_id, 
  discount_percentage
) VALUES (
  gen_random_uuid(),
  'valid-campaign-uuid',
  'valid-influencer-uuid',
  0 -- This should NOW be allowed
);
```

---

## 📝 Excluded from Migration

As per your requirements:

✅ **app_install_tracking** - No changes (read-only reference data)
✅ **app_purchases** - No changes (read-only reference data)
✅ **preferred_agency_id** - Removed from users table (not required)

---

## 🚨 Critical Next Steps

After migration succeeds:

1. **Test with Flutter app:**
   - Run app in development
   - Try to create/read/update records
   - Verify RLS doesn't break existing functionality

2. **Monitor logs:**
   - Check Supabase dashboard for errors
   - Monitor database performance

3. **Update Flutter models** (if needed):
   - Add `created_by` / `updated_by` fields to models that now have them
   - Update serialization logic

4. **Update Flutter services:**
   - Services already updated (removed manual assignment of these fields)
   - Verify triggers work: records should auto-populate created_by/updated_by

---

## 📞 Support

If migration fails:
1. Check error message in Supabase dashboard
2. Verify database user has correct permissions
3. Restore from backup if needed
4. Contact Supabase support with error logs

---

## ✨ Success Indicators

After migration, you should see:

✅ 19 tables with RLS enabled  
✅ 50+ RLS policies protecting data  
✅ 9 tables with created_by/updated_by audit fields  
✅ Triggers auto-populating audit fields  
✅ Standardized FK delete behavior  
✅ Fixed constraint validation  
✅ Redesigned guest_role_id table  
✅ Zero data loss (except intentional removals)  
✅ Flutter app continues working correctly  
✅ RLS policies enforced on read/write operations  

**Expected Result:** More secure, auditable, and maintainable database schema! 🎉

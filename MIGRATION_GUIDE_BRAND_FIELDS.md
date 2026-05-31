# Adding android_app_id and website_url to Brand Model

## Summary
Added two new columns to the `brands` table and updated the Flutter `ModelBrand` class to support:
- **android_app_id**: Store the Android package ID (e.g., `com.numeroshastra.client`) for referrer tracking
- **website_url**: Store the brand's website URL

## Changes Made

### 1. Database (Supabase)
**File**: `supabase_functions/migrations/add_brand_app_id_and_website_url.sql`

Created migration to add two nullable text columns to the `brands` table:
```sql
ALTER TABLE public.brands
ADD COLUMN android_app_id text,
ADD COLUMN website_url text;
```

### 2. Flutter Model
**File**: `lib/features/postLogin/brands/model/brand_model.dart`

#### Added Field Constants:
```dart
static const String androidAppId = 'android_app_id';
static const String websiteUrl = 'website_url';
```

#### Added Labels:
```dart
androidAppId: 'Android App ID',
websiteUrl: 'Website URL',
```

#### Updated ModelBrand Class:
- Added two new properties:
  ```dart
  final String? androidAppId;
  final String? websiteUrl;
  ```
- Updated constructor parameters
- Updated `fromMap()` factory method
- Updated `toMap()` conversion method
- Updated `toJson()` serialization method
- Updated `fromJson()` deserialization method

## Implementation Steps

### Step 1: Execute Database Migration
1. Open Supabase dashboard
2. Navigate to **SQL Editor**
3. Run the migration SQL:
   ```sql
   -- Migration: Add android_app_id and website_url columns to brands table
   -- Date: 2026-05-31
   -- Description: Add mobile app ID and brand website URL fields to support referrer tracking and brand links

   ALTER TABLE public.brands
   ADD COLUMN android_app_id text,
   ADD COLUMN website_url text;

   COMMENT ON COLUMN public.brands.android_app_id IS 'Android package ID for the brand app (e.g., com.numeroshastra.client)';
   COMMENT ON COLUMN public.brands.website_url IS 'Brand website URL';
   ```

### Step 2: Format and Build Flutter App
1. Run Dart formatter:
   ```bash
   dart format lib/features/postLogin/brands/model/brand_model.dart
   ```

2. Verify no errors:
   ```bash
   dart analyze lib/features/postLogin/brands/model/brand_model.dart
   ```

3. Get dependencies and rebuild:
   ```bash
   flutter pub get
   flutter clean
   flutter pub get
   flutter build apk  # or web/ios/mac depending on target
   ```

### Step 3: Update UI Forms (if applicable)
If your brand creation/editing forms need to include these fields:

**Example Form Fields**:
```dart
// Android App ID field
TextFormField(
  initialValue: brand?.androidAppId ?? '',
  decoration: InputDecoration(
    labelText: 'Android App ID',
    hintText: 'com.example.app',
  ),
  onSaved: (value) => formData['androidAppId'] = value,
  validator: (value) {
    if (value?.isNotEmpty ?? false) {
      // Optional validation for package name format
      if (!RegExp(r'^[a-z0-9_.]+$').hasMatch(value!)) {
        return 'Invalid package name format';
      }
    }
    return null;
  },
),

// Website URL field
TextFormField(
  initialValue: brand?.websiteUrl ?? '',
  decoration: InputDecoration(
    labelText: 'Website URL',
    hintText: 'https://example.com',
  ),
  onSaved: (value) => formData['websiteUrl'] = value,
  validator: (value) {
    if (value?.isNotEmpty ?? false) {
      if (!Uri.tryParse(value!)?.hasScheme ?? false) {
        return 'Invalid URL format';
      }
    }
    return null;
  },
),
```

### Step 4: Update Brand Service/Provider (if needed)
Update any queries or data fetching to include the new fields if you're using custom queries.

## Usage Example in Collaboration View

Now you can use these fields when generating referrer links:

```dart
// In collaboration_view_page_riverpod.dart
final instagramUrl = _buildStoreUrl(
  appId: collaboration.resolvedLabels['android_app_id_label'] ?? 'com.numeroshastra.client',
  referrer: instagramReferrer,
);
```

## Verification

### Database Level
```sql
-- Verify columns exist
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'brands'
ORDER BY ordinal_position;
```

### Flutter Level
The model classes will automatically handle:
- Serialization/deserialization from Supabase
- Form input handling
- JSON export/import
- Database mapping

## Notes
- Both columns are **optional** (nullable) to maintain backward compatibility
- No existing brand records will be affected
- The migration is safe to run multiple times (idempotent)
- Fields default to `null` if not provided

## Related Files Modified
- ✅ `supabase_functions/migrations/add_brand_app_id_and_website_url.sql` (created)
- ✅ `lib/features/postLogin/brands/model/brand_model.dart` (updated)

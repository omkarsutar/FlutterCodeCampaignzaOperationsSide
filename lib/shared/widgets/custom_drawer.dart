import 'package:flutter/material.dart';
import 'package:flutter_supabase_order_app_mobile/features/postLogin/notes/note_barrel.dart';
import 'package:flutter_supabase_order_app_mobile/features/postLogin/influencers/influencer_barrel.dart';
import 'package:flutter_supabase_order_app_mobile/features/postLogin/campaigns/campaign_barrel.dart';
import 'package:flutter_supabase_order_app_mobile/features/postLogin/rbac_modules/rbac_module_barrel.dart';
import 'package:flutter_supabase_order_app_mobile/features/postLogin/rbac_permissions/rbac_permission_barrel.dart';
import 'package:flutter_supabase_order_app_mobile/features/postLogin/roles/role_barrel.dart';
import 'package:flutter_supabase_order_app_mobile/features/postLogin/agency_brand_links/agency_brand_link_barrel.dart';
import 'package:flutter_supabase_order_app_mobile/features/postLogin/agencies/agency_barrel.dart';
import 'package:flutter_supabase_order_app_mobile/features/postLogin/brands/brand_barrel.dart';
import 'package:flutter_supabase_order_app_mobile/features/postLogin/po_collections/po_collection_barrel.dart';
import 'package:flutter_supabase_order_app_mobile/features/postLogin/users/user_barrel.dart';
import 'package:flutter_supabase_order_app_mobile/features/postLogin/retailer_brand_links/retailer_brand_link_barrel.dart';
import 'package:flutter_supabase_order_app_mobile/features/postLogin/collaborations/collaboration_barrel.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/auth_providers.dart';
import '../../core/providers/core_providers.dart';

import '../../core/utils/dialogs.dart';
import '../../router/app_routes.dart';
import 'read_entity_tile.dart';

class CustomDrawer extends ConsumerWidget {
  const CustomDrawer({super.key});

  String? _userDisplayName(WidgetRef ref) {
    final user = ref.watch(userProfileProvider).value;
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      // Fallback to metadata if profile not yet loaded/available
      final name = currentUser?.userMetadata?['name']?.toString();
      if (name != null && name.isNotEmpty) return name;
      return currentUser?.email;
    }
    return user.fullName ?? currentUser?.email;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch initialization state to trigger rebuilds for Role display, etc.
    ref.watch(rbacInitializationProvider);

    final authService = ref.watch(authServiceProvider);
    final rbacService = ref.watch(rbacServiceProvider);
    final displayName = _userDisplayName(ref);
    final theme = Theme.of(context);
    final isLoggedIn = Supabase.instance.client.auth.currentSession != null;

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: theme.colorScheme.primary),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (displayName != null)
                  Text(
                    "Order App",
                    style: TextStyle(color: theme.colorScheme.onPrimary),
                  ),
                Text(
                  displayName != null
                      ? 'Welcome, $displayName'
                      : 'Welcome to Order App',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w400,
                    color: theme.colorScheme.onPrimary,
                  ),
                ),
                if (rbacService.roleName != null)
                  Text(
                    'Role: ${rbacService.roleName!}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w300,
                      color: theme.colorScheme.onPrimary.withValues(alpha: 0.7),
                    ),
                  ),
              ],
            ),
          ),

          // Removed Todays Brands per user request

          // Agencies
          ReadEntityTile(
            moduleName: ModelAgencyFields.table, // "agencies"
            routeName: AgenciesRoutesJson.listRouteName,
            title: 'Agencies',
            icon: Icons.alt_route,
          ),

          // Brands
          ReadEntityTile(
            moduleName: ModelBrandFields.table, // "brands"
            routeName: BrandsRoutesJson.listRouteName,
            title: 'Brands',
            icon: Icons.store,
          ),

          // Campaigns
          ReadEntityTile(
            moduleName: ModelCampaignFields.table, // "campaigns"
            routeName: CampaignsRoutesJson.listRouteName,
            title: 'Campaigns',
            icon: Icons.receipt_long,
          ),

          // Collaborations
          ReadEntityTile(
            moduleName: ModelCollaborationFields.table, // "collaborations"
            routeName: CollaborationsRoutesJson.listRouteName,
            title: 'Collaborations',
            icon: Icons.list_alt,
          ),

          // Influencers
          ReadEntityTile(
            moduleName: ModelInfluencerFields.table, // "influencer"
            routeName: InfluencerRoutesJson.listRouteName,
            title: 'Influencers',
            icon: Icons.people,
            allowAnonymous: true,
          ),

          // Collections
          ReadEntityTile(
            moduleName: ModelPoCollectionFields.table, // "po_collections"
            routeName: 'collections',
            title: 'Collections',
            icon: Icons.payments,
          ),

          ListTile(
            leading: const Icon(Icons.shopping_cart), // 🛒 My Cart
            title: const Text('My Cart'),
            onTap: () => context.goNamed(AppRoute.cartName),
          ),

          if (isLoggedIn)
            ListTile(
              leading: const Icon(Icons.person), // 👤 Profile
              title: const Text('Profile'),
              onTap: () => context.goNamed(AppRoute.profileName),
            ),

          // Users
          ReadEntityTile(
            moduleName: ModelUserFields.table, // "users"
            routeName: UsersRoutesJson.listRouteName,
            title: 'Users',
            icon: Icons.group,
          ),

          // Roles
          ReadEntityTile(
            moduleName: ModelRoleFields.table, // "rbac_roles"
            routeName: RolesRoutesJson.listRouteName,
            title: 'Roles',
            icon: Icons.admin_panel_settings,
          ),

          // RBAC Modules
          ReadEntityTile(
            moduleName: ModelRbacModuleFields.table, // "rbac_modules"
            routeName: RbacModulesRoutesJson.listRouteName,
            title: 'RbacModules',
            icon: Icons.extension,
          ),

          // RBAC Permissions
          ReadEntityTile(
            moduleName: ModelRbacPermissionFields.table, // "rbac_permissions"
            routeName: RbacPermissionsRoutesJson.listRouteName,
            title: 'RbacPermissions',
            icon: Icons.lock_open,
          ),

          // Agency Brand Links
          ReadEntityTile(
            moduleName:
                ModelAgencyBrandLinkFields.table, // "agency_brand_links"
            routeName: AgencyBrandLinksRoutesJson.listRouteName,
            title: 'Agency Brand Links',
            icon: Icons.link,
          ),

          // Retailer Brand Links
          ReadEntityTile(
            moduleName:
                ModelRetailerBrandLinkFields.table, // "retailer_brand_link"
            routeName: RetailerBrandLinkRoutesJson.listRouteName,
            title: 'Retailer Brand Links',
            icon: Icons.link,
          ),

          // Notes
          ReadEntityTile(
            moduleName: ModelNoteFields.table, // "notes"
            routeName: NotesRoutesJson.listRouteName,
            title: 'Notes',
            icon: Icons.note,
          ),

          if (!isLoggedIn)
            ListTile(
              leading: const Icon(Icons.login), // 🔑 Login
              title: const Text('Login'),
              onTap: () => context.goNamed(AppRoute.loginName),
            ),

          if (!isLoggedIn)
            ListTile(
              leading: const Icon(Icons.waving_hand), // 👋 Welcome
              title: const Text('Welcome'),
              onTap: () => context.goNamed(AppRoute.welcomeName),
            ),

          if (Supabase.instance.client.auth.currentSession != null)
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () async {
                final confirmed = await showConfirmationDialog(
                  context: context,
                  title: 'Logout',
                  content: 'Are you sure you want to Logout?',
                  confirmLabel: 'Logout',
                );
                if (confirmed) {
                  await authService.signOut();
                }
              },
            ),
        ],
      ),
    );
  }
}

import 'package:flutter/foundation.dart';
import 'package:flutter_supabase_order_app_mobile/features/postLogin/notes/note_barrel.dart';
import 'package:flutter_supabase_order_app_mobile/features/postLogin/collaborations/collaboration_barrel.dart';
import 'package:flutter_supabase_order_app_mobile/features/postLogin/influencers/influencer_barrel.dart';
import 'package:flutter_supabase_order_app_mobile/features/postLogin/campaigns/campaign_barrel.dart';
import 'package:flutter_supabase_order_app_mobile/features/postLogin/rbac_modules/rbac_module_barrel.dart';
import 'package:flutter_supabase_order_app_mobile/features/postLogin/rbac_permissions/rbac_permission_barrel.dart';
import 'package:flutter_supabase_order_app_mobile/features/postLogin/roles/role_barrel.dart';
import 'package:flutter_supabase_order_app_mobile/features/postLogin/agency_brand_links/agency_brand_link_barrel.dart';
import 'package:flutter_supabase_order_app_mobile/features/postLogin/agencies/agency_barrel.dart';
import 'package:flutter_supabase_order_app_mobile/features/postLogin/brands/brand_barrel.dart';
import 'package:flutter_supabase_order_app_mobile/features/postLogin/po_collections/po_collection_barrel.dart';
import 'package:flutter_supabase_order_app_mobile/features/postLogin/retailer_brand_links/retailer_brand_link_barrel.dart';
import 'package:flutter_supabase_order_app_mobile/features/postLogin/user_agency_links/user_agency_link_barrel.dart';
import 'package:flutter_supabase_order_app_mobile/features/postLogin/user_influencer_links/user_influencer_link_barrel.dart';
import 'package:flutter_supabase_order_app_mobile/features/postLogin/users/user_barrel.dart';
import 'package:flutter_supabase_order_app_mobile/router/app_routes.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/providers/core_providers.dart';
import '../core/providers/user_profile_state_provider.dart';

import '../features/postLogin/loading_page/loading_page.dart';
import '../features/preLogin/welcome_page.dart';
import '../features/auth/auth_page.dart';
import '../features/postLogin/cart/cart_barrel.dart';
import '../shared/widgets/shared_widget_barrel.dart';
import '../core/routing/module_route_generator.dart';
import '../core/services/rbac_service.dart';

final routerProvider = Provider<GoRouter>((ref) {
  ref.watch(userProfileStateProvider);
  final rbacService = ref.watch(rbacServiceProvider);
  final isRbacInitialized = ref.watch(rbacInitializationProvider);

  return GoRouter(
    routes: [
      ...authRoutes,
      ...NotesRoutesJson.routes,
      ...AgenciesRoutesJson.routes,
      ...BrandsRoutesJson.routes,
      ...AgencyBrandLinksRoutesJson.routes,
      ...RolesRoutesJson.routes,
      ...UsersRoutesJson.routes,
      ...CampaignsRoutesJson.routes,
      ...CollaborationsRoutesJson.routes,
      ...InfluencerRoutesJson.routes,
      ...RbacModulesRoutesJson.routes,
      ...RbacPermissionsRoutesJson.routes,
      ...PoCollectionsRoutesJson.routes,
      ...RetailerBrandLinkRoutesJson.routes,
      ...UserAgencyLinkRoutesJson.routes,
      ...UserInfluencerLinkRoutesJson.routes,
    ],
    initialLocation: AppRoute.welcome,
    redirect: (context, state) async {
      final session = Supabase.instance.client.auth.currentSession;
      final isLoggedIn = session != null;

      final isAtRoot = state.uri.path == AppRoute.welcome;
      final isAuthPage =
          state.uri.path == AppRoute.login || state.uri.path == AppRoute.signup;

      // Check role first if possible
      final roleName = rbacService.roleName?.toLowerCase();

      debugPrint(
        'AppRouter: Redirect Check | LoggedIn: $isLoggedIn | Role: $roleName | Path: ${state.uri.path}',
      );

      final hasRole = roleName != null && roleName.isNotEmpty;

      final isPublicRoute =
          state.uri.path.startsWith('/influencers') ||
          state.uri.path.startsWith('/cart');

      // Redirect to products page if not logged in and trying to access protected routes
      if (!isLoggedIn && !isAuthPage && !isAtRoot && !isPublicRoute) {
        return state.namedLocation(InfluencerRoutesJson.listRouteName);
      }

      // Redirect to products page if at root and not logged in
      if (!isLoggedIn && isAtRoot) {
        return state.namedLocation(InfluencerRoutesJson.listRouteName);
      }
      if (isLoggedIn && (isAuthPage || isAtRoot)) {
        debugPrint(
          'AppRouter: Handling Root/Auth Page Redirect for LoggedIn User',
        );

        if (!isRbacInitialized || !hasRole) {
          debugPrint('AppRouter: Profile/RBAC not ready -> Loading');
          return AppRoute.loading; // Wait for RBAC at minimum
        }

        debugPrint('AppRouter: User role is $roleName');

        // Redirect guest to Products
        if (roleName == 'guest') {
          debugPrint('AppRouter: Guest user -> Redirecting to Products');
          return state.namedLocation(InfluencerRoutesJson.listRouteName);
        }

        // Redirect salesperson to All Brands
        if (roleName == 'salesperson') {
          return state.namedLocation(BrandsRoutesJson.listRouteName);
        }

        return state.namedLocation(CampaignsRoutesJson.listRouteName);
      }

      // --- RBAC Route Protection ---
      // Check if the current route has a permission requirement
      final routeName = state.name;

      debugPrint(
        'AppRouter: RBAC Check Loop | Path: ${state.uri.path} | RouteName: $routeName',
      );

      if (isLoggedIn && routeName != null) {
        final permission = ModuleRouteRegistry.getRoutePermission(routeName);

        if (permission != null) {
          final hasAccess = rbacService.hasPermission(
            permission.moduleId,
            permission.action,
          );

          debugPrint(
            'AppRouter: RBAC Check | Route: $routeName | Module: ${permission.moduleId} | Action: ${permission.action.name} | Role: $roleName | Allowed: $hasAccess',
          );

          if (!hasAccess) {
            debugPrint(
              'AppRouter: Access denied for route $routeName -> Redirecting to unauthorized',
            );
            return AppRoute.unauthorized;
          }
        } else {
          // Verbose logging of unprotected routes
          debugPrint(
            'AppRouter: No RBAC permission found for route $routeName',
          );
        }
      }

      return null;
    },
  );
});

final authRoutes = [
  GoRoute(
    name: AppRoute.loadingName,
    path: AppRoute.loading,
    builder: (context, state) => const LoadingPage(),
  ),
  GoRoute(
    name: AppRoute.welcomeName,
    path: AppRoute.welcome,
    builder: (context, state) => const WelcomePage(),
  ),
  GoRoute(
    name: AppRoute.loginName,
    path: AppRoute.login,
    builder: (context, state) => const AuthPage(),
  ),
  GoRoute(
    name: AppRoute.signupName,
    path: AppRoute.signup,
    builder: (context, state) => const AuthPage(),
  ),
  GoRoute(
    name: AppRoute.profileName,
    path: AppRoute.profile,
    builder: (context, state) => const UserProfilePage(),
  ),
  GoRoute(
    name: AppRoute.cartName,
    path: AppRoute.cart,
    builder: (context, state) => const CartPage(),
  ),
  GoRoute(
    name: 'campaign_collection',
    path: '/campaigns/:poId/collect',
    builder: (context, state) =>
        CampaignCollectionPage(poId: state.pathParameters['poId']!),
  ),
  GoRoute(
    name: AppRoute.unauthorizedName,
    path: AppRoute.unauthorized,
    builder: (context, state) => const UnauthorizedPage(),
  ),
];

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_supabase_order_app_mobile/core/providers/core_providers.dart';
import 'package:flutter_supabase_order_app_mobile/features/postLogin/campaigns/campaign_barrel.dart';
import 'package:flutter_supabase_order_app_mobile/features/postLogin/brands/brand_barrel.dart';
import 'package:flutter_supabase_order_app_mobile/features/postLogin/influencers/influencer_barrel.dart';
import 'package:flutter_supabase_order_app_mobile/router/app_routes.dart';
import 'package:go_router/go_router.dart';

class LoadingPage extends ConsumerWidget {
  const LoadingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isRbacInitialized = ref.watch(rbacInitializationProvider);
    final rbacService = ref.read(rbacServiceProvider);
    final roleName = rbacService.roleName?.toLowerCase();

    final hasRole = roleName != null && roleName.isNotEmpty;

    // If RBAC has resolved the user's role, proceed to the role-specific home.
    if (isRbacInitialized && hasRole) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;

        // Only redirect if we are actually on the loading page
        // This prevents accidental redirects if the widget is still in the tree
        final state = GoRouterState.of(context);
        if (state.uri.path != AppRoute.loading) return;

        final rbacService = ref.read(rbacServiceProvider);
        final roleName = rbacService.roleName?.toLowerCase();

        if (roleName == 'guest') {
          context.goNamed(InfluencerRoutesJson.listRouteName);
        } else if (roleName == 'salesperson') {
          context.goNamed(BrandsRoutesJson.listRouteName);
        } else {
          context.goNamed(CampaignsRoutesJson.listRouteName);
        }
      });
    }

    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

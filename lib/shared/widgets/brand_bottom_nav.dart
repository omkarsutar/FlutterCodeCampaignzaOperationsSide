import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_supabase_order_app_mobile/features/postLogin/brands/brand_barrel.dart';
import 'package:flutter_supabase_order_app_mobile/shared/widgets/read_entity_tile.dart';
import 'package:go_router/go_router.dart';

/// Struct-like class to hold query parameters
class BrandQueryParams {
  final String? filterBrandId;
  final String? tapCondition;
  final bool showBackButton;
  final bool selection;

  BrandQueryParams({
    this.filterBrandId,
    this.tapCondition,
    this.showBackButton = false,
    this.selection = false,
  });

  bool get isTapConditionEmpty => tapCondition == null || tapCondition!.isEmpty;
}

/// Parse query parameters once and return typed object
BrandQueryParams getBrandQueryParams(BuildContext context) {
  final params = GoRouterState.of(context).uri.queryParameters;
  return BrandQueryParams(
    filterBrandId: params['filterBrandId'],
    tapCondition: params['tapCondition'],
    showBackButton: params['showBackButton'] == 'true',
    selection:
        params['selection'] == 'true' || params['isSelectionMode'] == 'true',
  );
}

/// Maps tapCondition string to bottom nav index
int getBottomNavIndex(String? tapCondition) {
  if (tapCondition == 'listWithoutTodaysPOs') return 0; // Todays Brands
  if (tapCondition == 'listWithTodaysEmptyPOs') return 1; // Visited Brands
  if (tapCondition == 'listWithTodaysFilledPOs') return 2; // Ordered Brands
  return 0;
}

/// Navigates to the correct brand tab using RBAC-aware ReadEntityTile
void navigateToBrandTab(BuildContext context, WidgetRef ref, int index) {
  final tapConditionMap = {
    0: 'listWithoutTodaysPOs',
    1: 'listWithTodaysEmptyPOs',
    2: 'listWithTodaysFilledPOs',
  };

  final tile = ReadEntityTile(
    moduleName: ModelBrandFields.table,
    routeName: BrandsRoutesJson.listRouteName,
    title: '', // not needed for bottom nav
    icon: Icons.store,
    queryParameters: {'tapCondition': tapConditionMap[index]!},
  );

  tile.navigate(context, ref); // ✅ RBAC-aware navigation
}

/// Builds the bottom navigation bar, shared between Brands and Campaigns pages
BottomNavigationBar? buildBrandBottomNav({
  required BuildContext context,
  required WidgetRef ref,
  required String? tapCondition,
  required bool showBottomNav,
}) {
  if (!showBottomNav) return null;

  return BottomNavigationBar(
    currentIndex: getBottomNavIndex(tapCondition),
    items: const [
      BottomNavigationBarItem(
        icon: Icon(Icons.shopping_cart),
        label: 'Todays Brands',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.check_circle),
        label: 'Visited Brands',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.done_all),
        label: 'Ordered Brands',
      ),
    ],
    onTap: (index) => navigateToBrandTab(context, ref, index),
  );
}

/// Shared AppBar title logic
String getAppBarTitle(String? tapCondition) {
  if (tapCondition == 'listWithTodaysEmptyPOs') {
    return 'Visited Brands';
  } else if (tapCondition == 'listWithTodaysFilledPOs') {
    return 'Ordered Brands';
  } else if (tapCondition == 'listWithoutTodaysPOs') {
    return 'Todays Brands';
  }
  return 'All Brands';
}

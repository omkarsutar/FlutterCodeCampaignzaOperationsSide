import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Struct-like class to hold query parameters
class BrandQueryParams {
  final String? filterBrandId;
  final bool showBackButton;
  final bool selection;

  BrandQueryParams({
    this.filterBrandId,
    this.showBackButton = false,
    this.selection = false,
  });
}

/// Parse query parameters once and return typed object
BrandQueryParams getBrandQueryParams(BuildContext context) {
  final params = GoRouterState.of(context).uri.queryParameters;
  return BrandQueryParams(
    filterBrandId: params['filterBrandId'],
    showBackButton: params['showBackButton'] == 'true',
    selection:
        params['selection'] == 'true' || params['isSelectionMode'] == 'true',
  );
}

/// Shared AppBar title logic
String getAppBarTitle() {
  return 'All Brands';
}

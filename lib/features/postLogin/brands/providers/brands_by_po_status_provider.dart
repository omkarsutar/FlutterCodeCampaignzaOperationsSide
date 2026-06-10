import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_supabase_order_app_mobile/core/providers/core_providers.dart';
import 'package:flutter_supabase_order_app_mobile/features/postLogin/brands/model/brand_model.dart';
import 'package:flutter_supabase_order_app_mobile/features/postLogin/brands/providers/brand_providers.dart';
import 'package:flutter_supabase_order_app_mobile/features/postLogin/users/providers/user_providers.dart';

/// Provider to fetch brands classified by campaign item status
/// Returns a map with keys: 'noPOs', 'emptyPOs', 'filledPOs'
final brandsByPOStatusProvider = StreamProvider.autoDispose
    .family<Map<String, List<ModelBrand>>, String?>((ref, agencyId) {
  final roleName = ref.watch(roleNameProvider);
  final isAdmin = roleName?.toLowerCase() == 'admin' ||
      roleName?.toLowerCase() == 'administrator';

  final effectiveRouteId = (agencyId != null && agencyId.isNotEmpty)
      ? agencyId
      : ref.watch(selectedAgencyIdProvider);

  final service = ref.read(brandServiceProvider);

  if (effectiveRouteId == null || effectiveRouteId.isEmpty) {
    if (isAdmin) {
      // For admins with "All Agencies", we might want to show all brands
      // but status classification is agency-specific in the current service.
      // For now, return empty or implement a global classification if needed.
    }
    // emit empty classification
    return Stream.value({
      'noPOs': <ModelBrand>[],
      'emptyPOs': <ModelBrand>[],
      'filledPOs': <ModelBrand>[],
    });
  }

  // service.streamBrandsByPOItemStatus already handles classification + sorting
  return service.streamBrandsByCollaborationStatus(effectiveRouteId);
});

final regularBrandsProvider = FutureProvider.autoDispose
    .family<List<ModelBrand>, String?>((ref, agencyId) async {
  final roleName = ref.watch(roleNameProvider);
  final isAdmin = roleName?.toLowerCase() == 'admin' ||
      roleName?.toLowerCase() == 'administrator';

  final effectiveRouteId = (agencyId != null && agencyId.isNotEmpty)
      ? agencyId
      : ref.watch(selectedAgencyIdProvider);

  final service = ref.read(brandServiceProvider);

  if (effectiveRouteId == null || effectiveRouteId.isEmpty) {
    if (isAdmin) {
      return await service.fetchAll();
    }
    return [];
  }

  return await service.fetchAllBrandsForAgency(effectiveRouteId);
});

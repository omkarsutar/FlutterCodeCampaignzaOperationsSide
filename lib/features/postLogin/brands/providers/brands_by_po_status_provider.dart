import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_supabase_order_app_mobile/core/providers/user_profile_state_provider.dart';
import 'package:flutter_supabase_order_app_mobile/features/postLogin/brands/model/brand_model.dart';
import 'package:flutter_supabase_order_app_mobile/features/postLogin/brands/providers/brand_providers.dart';

/// Provider to fetch brands classified by campaign item status
/// Returns a map with keys: 'noPOs', 'emptyPOs', 'filledPOs'
final brandsByPOStatusProvider = StreamProvider.autoDispose
    .family<Map<String, List<ModelBrand>>, String?>((ref, agencyId) {
      final effectiveRouteId = (agencyId != null && agencyId.isNotEmpty)
          ? agencyId
          : ref.watch(userProfileStateProvider).profile?.preferredAgencyId;

      final service = ref.read(brandServiceProvider);

      if (effectiveRouteId == null || effectiveRouteId.isEmpty) {
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
      final effectiveRouteId = (agencyId != null && agencyId.isNotEmpty)
          ? agencyId
          : ref.watch(userProfileStateProvider).profile?.preferredAgencyId;

      if (effectiveRouteId == null || effectiveRouteId.isEmpty) return [];

      final service = ref.read(brandServiceProvider);
      return await service.fetchAllBrandsForAgency(effectiveRouteId);
    });

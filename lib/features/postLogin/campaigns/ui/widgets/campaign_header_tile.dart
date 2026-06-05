import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_supabase_order_app_mobile/core/providers/core_providers.dart';
import 'package:flutter_supabase_order_app_mobile/core/providers/auth_providers.dart';
import 'package:flutter_supabase_order_app_mobile/features/postLogin/agencies/providers/agency_providers.dart';
import 'package:flutter_supabase_order_app_mobile/features/postLogin/brands/providers/brand_providers.dart';
import 'package:flutter_supabase_order_app_mobile/features/postLogin/brands/model/brand_model.dart';
import 'package:flutter_supabase_order_app_mobile/features/postLogin/campaigns/providers/campaign_list_controller.dart';
import 'package:flutter_supabase_order_app_mobile/features/postLogin/campaigns/providers/campaign_providers.dart';
import 'package:flutter_supabase_order_app_mobile/features/postLogin/campaigns/model/campaign_model.dart';

class CampaignHeaderTile extends ConsumerWidget {
  final String? filterBrandId;
  final ModelBrand? brandExtra;

  const CampaignHeaderTile({
    super.key,
    this.filterBrandId,
    this.brandExtra,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final roleName = ref.watch(roleNameProvider)?.toLowerCase();
    final isAdmin = roleName == 'admin';
    if (isAdmin) return const SizedBox.shrink();

    // 1. Get Agency details
    final agencyNameAsync = ref.watch(currentAgencyNameProvider);
    final userProfile = ref.watch(userProfileProvider).value;
    final agencyId = userProfile?.preferredAgencyId;

    // 2. Get Brand details
    String? brandId = filterBrandId ?? brandExtra?.brandId;
    String? brandName = brandExtra?.brandName;

    // If we have brandId but no brandName, look it up via brandByIdProvider
    if (brandId != null && brandName == null) {
      final brandAsync = ref.watch(brandByIdProvider(brandId));
      brandName = brandAsync.value?.brandName;
    }

    // Fallback: if brandId is null, look up from first campaign item in state
    if (brandId == null) {
      final listState = ref.watch(campaignListControllerProvider('campaignList'));
      final firstPo = listState.filteredCampaigns.firstOrNull ?? listState.allCampaigns.firstOrNull;
      if (firstPo != null) {
        brandId = firstPo.poBrandId;
        final adapter = ref.read(campaignAdapterProvider);
        brandName = adapter.getLabelValue(firstPo, ModelCampaignFields.poBrandId)?.toString();
      }
    }

    final valueStyle = theme.textTheme.bodyMedium?.copyWith(
      fontWeight: FontWeight.bold,
      fontSize: 14,
    );

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.55),
          width: 0.8,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Column(
          children: [
            agencyNameAsync.when(
              data: (agencyName) => Row(
                children: [
                  Icon(Icons.corporate_fare_outlined, color: theme.colorScheme.primary, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Agency: $agencyName',
                      style: valueStyle,
                    ),
                  ),
                  if (agencyId != null && agencyId.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.visibility_outlined),
                      tooltip: 'View agency',
                      iconSize: 18,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                      onPressed: () => context.pushNamed(
                        'viewAgency',
                        pathParameters: {'id': agencyId},
                      ),
                    ),
                ],
              ),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            const Divider(height: 8, thickness: 0.5),
            Row(
              children: [
                Icon(Icons.business_outlined, color: theme.colorScheme.primary, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Brand: ${brandName ?? 'Loading...'}',
                    style: valueStyle,
                  ),
                ),
                if (brandId != null && brandId.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.visibility_outlined),
                    tooltip: 'View brand',
                    iconSize: 18,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                    onPressed: () => context.pushNamed(
                      'viewBrand',
                      pathParameters: {'id': brandId!},
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

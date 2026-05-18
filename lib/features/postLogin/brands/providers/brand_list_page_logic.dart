import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/providers/user_profile_state_provider.dart';
import '../../../../core/services/core_services_barrel.dart';
import '../../../../core/utils/core_utils_barrel.dart';
import '../../campaigns/campaign_barrel.dart';
import '../model/brand_model.dart';

/// Logic for Brand List Page navigation and actions
class BrandListPageLogic {
  /// Determines the tap action
  static VoidCallback getOnTapForBrand({
    required BuildContext context,
    required ModelBrand entity,
    required EntityAdapter<ModelBrand> adapter,
    required bool isSelectionMode,
    required String viewRouteName,
    required String idField,
  }) {
    // Handle selection mode - pop with selected entity
    if (isSelectionMode) {
      return () => context.pop(entity);
    }

    final brandId = adapter.getFieldValue(entity, ModelBrandFields.brandId);

    // Default: navigate to PO list for this brand
    return () => context.pushNamed(
      CampaignsRoutesJson.listRouteName,
      queryParameters: {
        'filterBrandId': brandId,
        'showBackButton': 'true',
      },
      extra: entity,
    );
  }

  /// Handles the complete PO creation workflow
  static Future<void> handleCreateCampaign({
    required BuildContext context,
    required WidgetRef ref,
    required ModelBrand entity,
    required EntityAdapter<ModelBrand> adapter,
  }) async {
    final agencyId = ref
        .read(userProfileStateProvider)
        .profile
        ?.preferredAgencyId;
    final brandId = adapter.getFieldValue(entity, ModelBrandFields.brandId);

    // Validation
    if (agencyId == null || brandId == null) {
      SnackbarUtils.showError('Missing route or brand ID');
      return;
    }

    // Confirmation dialog
    final confirmed = await showConfirmationDialog(
      context: context,
      title: 'New Campaign',
      content: 'Are you sure you want to create a new Campaign?',
      confirmLabel: 'Create',
    );
    if (!confirmed) return;

    // Create PO
    try {
      await ref
          .read(campaignServiceProvider)
          .createEmptyCampaign(poAgencyId: agencyId, poBrandId: brandId);

      if (!context.mounted) return;
      SnackbarUtils.showSuccess('Campaign Created');
      if (!context.mounted) return;

      // Navigate to PO list
      context.pushNamed(
        CampaignsRoutesJson.listRouteName,
        queryParameters: {
          'filterBrandId': brandId,
          'showBackButton': 'true',
        },
        extra: entity,
      );
    } catch (e, stackTrace) {
      ErrorHandler.handle(
        e,
        stackTrace,
        context: 'Creating campaign for brand',
        showToUser: true,
      );
    }
  }
}

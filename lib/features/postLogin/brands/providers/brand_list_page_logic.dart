import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/providers/user_profile_state_provider.dart';
import '../../../../core/services/core_services_barrel.dart';
import '../../../../core/utils/core_utils_barrel.dart';
import '../../../../shared/widgets/brand_bottom_nav.dart';
import '../../campaigns/campaign_barrel.dart';
import '../model/brand_model.dart';

/// Logic for Brand List Page navigation and actions
class BrandListPageLogic {
  /// Determines the tap action based on tapCondition
  static VoidCallback getOnTapForBrand({
    required BuildContext context,
    required ModelBrand entity,
    required EntityAdapter<ModelBrand> adapter,
    required String? tapCondition,
    required bool isSelectionMode,
    required String viewRouteName,
    required String idField,
    required Future<void> Function(
      BuildContext,
      ModelBrand,
      EntityAdapter<ModelBrand>,
    )
    handleCreatePO,
  }) {
    // Handle selection mode - pop with selected entity
    if (isSelectionMode) {
      return () => context.pop(entity);
    }

    final brandId = adapter.getFieldValue(entity, ModelBrandFields.brandId);

    // Create new PO for brands without today's POs
    if (tapCondition == 'listWithoutTodaysPOs') {
      return () => handleCreatePO(context, entity, adapter);
    }

    // Navigate to PO list for brands with today's POs
    if (tapCondition == 'listWithTodaysEmptyPOs' ||
        tapCondition == 'listWithTodaysFilledPOs') {
      return () => context.pushNamed(
        CampaignsRoutesJson.listRouteName,
        queryParameters: {
          'filterBrandId': brandId,
          'showBackButton': 'true',
          'tapCondition': tapCondition!,
        },
        extra: entity,
      );
    }

    // Default: navigate to brand view page
    return () => context.pushNamed(
      viewRouteName,
      pathParameters: {'id': adapter.getId(entity, idField).toString()},
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

      // Navigate to PO list with tapCondition
      final queryParams = getBrandQueryParams(context);

      context.pushNamed(
        CampaignsRoutesJson.listRouteName,
        queryParameters: {
          'filterBrandId': brandId,
          if (queryParams.tapCondition != null)
            'tapCondition': queryParams.tapCondition,
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

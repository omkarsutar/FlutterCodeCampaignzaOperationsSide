import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/dialogs.dart';
import '../model/campaign_model.dart';
import '../providers/campaign_providers.dart';

/// Logic for Campaign List Tile display and operations
class CampaignTileLogic {
  /// Maps status string to display color
  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return Colors.green;
      case 'delivered':
        return Colors.blue;
      case 'cancelled':
        return Colors.red;
      case 'paid ads':
      case 'paid_ads':
        return Colors.deepOrange;
      case 'direct':
      case 'direct brand promotions':
      case 'direct_brand_promotions':
        return Colors.teal;
      case 'collabs':
      case 'influencer collaborations':
      case 'influencer_collaborations':
        return Colors.purple;
      default:
        return Colors.orange;
    }
  }

  /// Available status options for dropdown
  static const List<String> statusOptions = [
    'pending',
    'confirmed',
    'delivered',
    'cancelled',
  ];

  /// Formats profit/amount as integer (ceiling)
  static String formatCurrency(double? amount) {
    return (amount ?? 0).ceil().toString();
  }

  /// Handles status update workflow
  static Future<bool> updateStatus({
    required BuildContext context,
    required WidgetRef ref,
    required ModelCampaign entity,
    required String newStatus,
    required Function(bool) setUpdating,
  }) async {
    if (entity.poId == null) return false;

    setUpdating(true);

    try {
      final service = ref.read(campaignServiceProvider);

      // Create updated entity with new status
      final updatedEntity = ModelCampaign(
        poId: entity.poId,
        poAgencyId: entity.poAgencyId,
        poBrandId: entity.poBrandId,
        poTotalAmount: entity.poTotalAmount,
        poLineItemCount: entity.poLineItemCount,
        userComment: entity.userComment,
        profitToBrand: entity.profitToBrand,
        poLat: entity.poLat,
        poLong: entity.poLong,
        status: newStatus,
      );

      await service.update(entity.poId!, updatedEntity);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Status updated to ${newStatus.toUpperCase()}'),
          ),
        );
      }
      return true;
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update status: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return false;
    } finally {
      setUpdating(false);
    }
  }

  /// Handles order deletion workflow
  static Future<void> deleteOrder({
    required BuildContext context,
    required WidgetRef ref,
    required String poId,
    required Function(bool) setUpdating,
  }) async {
    final confirmed = await showConfirmDeleteWithTextDialog(
      context: context,
      title: 'Delete Campaign',
      content:
          'Are you sure you want to delete this campaign? This action cannot be undone.',
      entityNameLower: 'campaign',
    );

    if (!confirmed) return;

    setUpdating(true);
    try {
      final service = ref.read(campaignServiceProvider);
      await service.delete(poId);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Campaign deleted successfully')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete campaign: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setUpdating(false);
    }
  }
}

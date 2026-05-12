import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
        poRouteId: entity.poRouteId,
        poShopId: entity.poShopId,
        poTotalAmount: entity.poTotalAmount,
        poLineItemCount: entity.poLineItemCount,
        userComment: entity.userComment,
        profitToShop: entity.profitToShop,
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Campaign'),
        content: const Text(
          'Are you sure you want to delete this campaign? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

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

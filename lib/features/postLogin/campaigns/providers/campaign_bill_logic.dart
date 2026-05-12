import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/entity_service.dart';
import '../model/campaign_model.dart';

/// Processed data for the Campaign Bill page
class ProcessedBillData {
  final List<ModelCampaign> sortedOrders;
  final List<ModelCampaign> selectedOrders;
  final double totalAmount;
  final Map<int, bool> showHeaderAtIndex;
  final int heavyOrdersCount;

  ProcessedBillData({
    required this.sortedOrders,
    required this.selectedOrders,
    required this.totalAmount,
    required this.showHeaderAtIndex,
    required this.heavyOrdersCount,
  });
}

class CampaignBillLogic {
  /// Sorts orders by Route → Visit Order → Created At
  static List<ModelCampaign> sortOrders(
    List<ModelCampaign> orders,
    EntityAdapter<ModelCampaign> adapter,
  ) {
    final sorted = List<ModelCampaign>.from(orders);

    sorted.sort((a, b) {
      // 1. Sort by Route
      final routeA =
          adapter.getLabelValue(a, ModelCampaignFields.poRouteId)?.toString() ??
          '';
      final routeB =
          adapter.getLabelValue(b, ModelCampaignFields.poRouteId)?.toString() ??
          '';

      final routeCompare = routeA.compareTo(routeB);
      if (routeCompare != 0) return routeCompare;

      // 2. Sort by Visit Order
      final visitA = a.visitOrder ?? 999999;
      final visitB = b.visitOrder ?? 999999;
      final visitCompare = visitA.compareTo(visitB);
      if (visitCompare != 0) return visitCompare;

      // 3. Fallback to Created At
      final timeA = a.createdAt ?? DateTime(0);
      final timeB = b.createdAt ?? DateTime(0);
      return timeA.compareTo(timeB);
    });

    return sorted;
  }

  /// Determines which indices should show route headers
  static Map<int, bool> calculateHeaderIndices(
    List<ModelCampaign> sortedOrders,
    EntityAdapter<ModelCampaign> adapter,
  ) {
    final headers = <int, bool>{};

    for (int i = 0; i < sortedOrders.length; i++) {
      if (i == 0) {
        headers[i] = true;
        continue;
      }

      final currentRoute =
          adapter
              .getLabelValue(sortedOrders[i], ModelCampaignFields.poRouteId)
              ?.toString() ??
          'Unknown Route';
      final prevRoute =
          adapter
              .getLabelValue(sortedOrders[i - 1], ModelCampaignFields.poRouteId)
              ?.toString() ??
          'Unknown Route';

      headers[i] = currentRoute != prevRoute;
    }

    return headers;
  }

  /// Calculates total amount for selected orders
  static double calculateTotalAmount(List<ModelCampaign> selectedOrders) {
    return selectedOrders.fold<double>(
      0,
      (sum, order) => sum + (order.poTotalAmount ?? 0),
    );
  }

  /// Calculates count of orders with > 15 line items
  static int calculateHeavyOrdersCount(List<ModelCampaign> orders) {
    return orders.where((o) => (o.poLineItemCount ?? 0) > 15).length;
  }
}

/// Provider for processed bill data
final campaignBillLogicProvider = Provider.autoDispose
    .family<
      ProcessedBillData,
      ({
        List<ModelCampaign> allOrders,
        Set<String> selectedPoIds,
        EntityAdapter<ModelCampaign> adapter,
      })
    >((ref, arg) {
      // Sort orders
      final sortedOrders = CampaignBillLogic.sortOrders(
        arg.allOrders,
        arg.adapter,
      );

      // Calculate headers
      final showHeaderAtIndex = CampaignBillLogic.calculateHeaderIndices(
        sortedOrders,
        arg.adapter,
      );

      // Filter selected orders
      final selectedOrders = sortedOrders
          .where((o) => arg.selectedPoIds.contains(o.poId))
          .toList();

      // Calculate total
      final totalAmount = CampaignBillLogic.calculateTotalAmount(
        selectedOrders,
      );

      // Calculate heavy orders count (based on SELECTED orders only, as per user feedback)
      final heavyOrdersCount = CampaignBillLogic.calculateHeavyOrdersCount(
        selectedOrders,
      );

      return ProcessedBillData(
        sortedOrders: sortedOrders,
        selectedOrders: selectedOrders,
        totalAmount: totalAmount,
        showHeaderAtIndex: showHeaderAtIndex,
        heavyOrdersCount: heavyOrdersCount,
      );
    });

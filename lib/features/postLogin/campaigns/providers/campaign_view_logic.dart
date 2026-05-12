import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../model/campaign_model.dart';
import 'campaign_list_controller.dart';

class ProcessedCampaignData {
  final List<ModelCampaign> filteredOrders;
  final Map<String, int> statusCounts;
  final String? activeFabType; // 'bill', 'delivery', null

  ProcessedCampaignData({
    required this.filteredOrders,
    required this.statusCounts,
    this.activeFabType,
  });
}

final campaignViewLogicProvider = Provider.autoDispose<ProcessedCampaignData>((
  ref,
) {
  final listState = ref.watch(campaignListControllerProvider('campaignList'));
  final allOrders = listState.allCampaigns;
  final filteredOrders = listState.filteredCampaigns;
  final selectedStatus = listState.selectedStatus?.toLowerCase();

  // 1. Calculate status counts
  final statuses = ['All', 'pending', 'confirmed', 'delivered', 'cancelled'];
  final Map<String, int> statusCounts = {};

  for (final status in statuses) {
    if (status == 'All') {
      statusCounts[status] = allOrders.length;
    } else {
      statusCounts[status] = allOrders
          .where((po) => po.status?.toLowerCase() == status.toLowerCase())
          .length;
    }
  }

  // 2. Determine FAB type
  String? activeFabType;
  if (selectedStatus == 'confirmed') {
    activeFabType = 'bill';
  } else if (selectedStatus == 'delivered') {
    activeFabType = 'delivery';
  }

  return ProcessedCampaignData(
    filteredOrders: filteredOrders,
    statusCounts: statusCounts,
    activeFabType: activeFabType,
  );
});

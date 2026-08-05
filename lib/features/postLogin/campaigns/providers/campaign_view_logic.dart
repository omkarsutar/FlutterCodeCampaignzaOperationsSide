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

  // 1. Calculate campaign type counts
  final types = ['All', 'Direct', 'Paid Ads', 'Collabs'];
  final Map<String, int> typeCounts = {};

  for (final type in types) {
    if (type == 'All') {
      typeCounts[type] = allOrders.length;
    } else if (type == 'Paid Ads') {
      typeCounts[type] = allOrders
          .where((po) => po.effectiveCampaignType == CampaignType.paidAds)
          .length;
    } else if (type == 'Direct') {
      typeCounts[type] = allOrders
          .where(
            (po) =>
                po.effectiveCampaignType == CampaignType.directBrandPromotions,
          )
          .length;
    } else if (type == 'Collabs') {
      typeCounts[type] = allOrders
          .where(
            (po) =>
                po.effectiveCampaignType ==
                CampaignType.influencerCollaborations,
          )
          .length;
    }
  }

  return ProcessedCampaignData(
    filteredOrders: filteredOrders,
    statusCounts: typeCounts,
    activeFabType: null,
  );
});

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../collaborations/model/collaboration_model.dart';
import '../providers/cart_providers.dart';
import '../../influencers/influencer_barrel.dart';

class ProcessedCartItem {
  final ModelCollaboration item;
  final String productName;
  final String formattedQty;
  final String formattedRate;
  final String formattedAmount;

  ProcessedCartItem({
    required this.item,
    required this.productName,
    required this.formattedQty,
    required this.formattedRate,
    required this.formattedAmount,
  });
}

class ProcessedCartData {
  final List<ProcessedCartItem> items;
  final String totalAmount;
  final String totalProfit;
  final int itemCount;
  final bool isEmpty;

  ProcessedCartData({
    required this.items,
    required this.totalAmount,
    required this.totalProfit,
    required this.itemCount,
    required this.isEmpty,
  });
}

final cartViewLogicProvider = Provider.autoDispose<ProcessedCartData>((ref) {
  final cartState = ref.watch(cartProvider);
  final influencers = ref.watch(influencersStreamProvider).value ?? [];

  final processedItems = cartState.items.map((item) {
    // Resolve influencer name
    String influencerName = item.resolvedLabels['influencer_id_label'] ?? 'Unknown';
    if (influencerName == 'Unknown') {
      try {
        influencerName = influencers
            .firstWhere((p) => p.influencerId == item.influencerId)
            .influencerName;
      } catch (_) {
        influencerName = 'Unknown';
      }
    }

    final double rate = item.commissionRate ?? item.fixedAmount ?? 0.0;
    final double amount = item.agreedCommissionAmount ?? 0.0;

    return ProcessedCartItem(
      item: item,
      productName: influencerName,
      formattedQty: '1',
      formattedRate: rate.toStringAsFixed(2),
      formattedAmount: amount.toStringAsFixed(2),
    );
  }).toList();

  return ProcessedCartData(
    items: processedItems,
    totalAmount: cartState.totalAmount.round().toString(),
    totalProfit: '0.00',
    itemCount: cartState.items.length,
    isEmpty: cartState.items.isEmpty,
  );
});

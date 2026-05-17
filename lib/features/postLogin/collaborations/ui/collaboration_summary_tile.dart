import 'package:flutter/material.dart';

import '../model/collaboration_model.dart';

class CollaborationSummaryTile extends StatelessWidget {
  final ModelCollaboration item;

  const CollaborationSummaryTile({super.key, required this.item});

  String get _influencerName =>
      item.resolvedLabels['influencer_id_label']?.toString() ?? 'Unnamed Influencer';

  String get _commissionDetails {
    if (item.commissionType == null) return '-';
    switch (item.commissionType!) {
      case CommissionType.percentage:
        return item.commissionRate != null ? '${item.commissionRate}%' : '-';
      case CommissionType.fixedAmount:
        return item.fixedAmount != null ? '₹${item.fixedAmount!.toStringAsFixed(2)}' : '-';
      case CommissionType.barter:
        return 'Barter';
    }
  }

  String get _agreedCommission =>
      item.agreedCommissionAmount != null ? '₹${item.agreedCommissionAmount!.toStringAsFixed(2)}' : '-';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              _influencerName,
              style: theme.textTheme.bodySmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              item.commissionType?.displayName ?? '-',
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.right,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              _commissionDetails,
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.right,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              _agreedCommission,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}

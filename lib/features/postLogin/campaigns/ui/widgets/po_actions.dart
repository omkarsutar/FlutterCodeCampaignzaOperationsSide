import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_supabase_order_app_mobile/core/services/entity_service.dart';
import 'package:flutter_supabase_order_app_mobile/features/postLogin/campaigns/model/campaign_model.dart';
import 'package:flutter_supabase_order_app_mobile/features/postLogin/campaigns/providers/campaign_tile_logic.dart';
import '../campaign_share_preview_page.dart';

class CampaignActions extends ConsumerWidget {
  final ModelCampaign entity;
  final EntityAdapter<ModelCampaign> adapter;
  final bool showShare;
  final bool canDelete;
  final String status;
  final bool isUpdating;
  final ValueChanged<bool> onUpdating;

  const CampaignActions({
    super.key,
    required this.entity,
    required this.adapter,
    this.showShare = true,
    this.canDelete = true,
    required this.status,
    required this.isUpdating,
    required this.onUpdating,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Edit Campaign Button (Opens the campaign metadata edit form)
        _IconButton(
          icon: Icons.edit,
          color: theme.colorScheme.secondary,
          onPressed: () {
            if (entity.campaignId != null) {
              context.pushNamed(
                'editCampaign',
                pathParameters: {'id': entity.campaignId!},
              );
            }
          },
        ),

        // Share Button
        // Share Button (Only if delivered)
        if (showShare && status.toLowerCase() == 'delivered')
          _IconButton(
            icon: Icons.share,
            color: theme.colorScheme.secondary,
            onPressed: () => showDialog(
              context: context,
              useSafeArea: false,
              builder: (context) =>
                  CampaignSharePreviewPage(entity: entity, adapter: adapter),
            ),
          ),

        // Payment Collection Button
        if (status.toLowerCase() == 'delivered')
          _IconButton(
            icon: Icons.payment,
            color: Colors.green,
            onPressed: () => context.pushNamed(
              'campaign_collection',
              pathParameters: {'poId': entity.poId!},
            ),
          ),

        // Delete Button
        if (canDelete &&
            status.toLowerCase() == 'cancelled' &&
            entity.poId != null)
          _IconButton(
            icon: Icons.delete_forever,
            color: Colors.red,
            onPressed: isUpdating
                ? null
                : () => CampaignTileLogic.deleteOrder(
                    context: context,
                    ref: ref,
                    poId: entity.poId!,
                    setUpdating: onUpdating,
                  ),
          ),
      ],
    );
  }
}

class _IconButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback? onPressed;

  const _IconButton({required this.icon, required this.color, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Icon(icon, size: 20, color: color),
      ),
    );
  }
}

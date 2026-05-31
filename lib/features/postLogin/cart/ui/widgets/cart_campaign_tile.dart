import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart'; // Added for context.pushNamed
import '../../../../../../core/services/entity_service.dart';
import '../../../campaigns/model/campaign_model.dart';
import '../../../campaigns/providers/campaign_tile_logic.dart';
import '../../../campaigns/ui/widgets/po_actions.dart';

class CartCampaignTile extends StatelessWidget {
  final ModelCampaign entity;
  final EntityAdapter<ModelCampaign> adapter;
  final bool isUpdating;
  final ValueChanged<bool> onUpdating;

  const CartCampaignTile({
    super.key,
    required this.entity,
    required this.adapter,
    required this.isUpdating,
    required this.onUpdating,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final campaignName =
        entity.campaignName ?? entity.campaignNameString ?? 'Unnamed Campaign';

    final brandName =
        adapter
            .getLabelValue(entity, ModelCampaignFields.poBrandId)
            ?.toString() ??
        'Unknown Brand';
    final agencyName =
        adapter
            .getLabelValue(entity, ModelCampaignFields.poAgencyId)
            ?.toString() ??
        'Unknown Agency';
    final status = entity.status ?? 'pending';
    final collabsCount = entity.poLineItemCount ?? 0;

    // Date formatting (convert to local timezone first)
    final DateFormat formatter = DateFormat('dd MMM yyyy HH:mm');
    final validFromStr = entity.validFrom != null
        ? formatter.format(entity.validFrom!.toLocal())
        : 'N/A';
    final validUntilStr = entity.validUntil != null
        ? formatter.format(entity.validUntil!.toLocal())
        : 'N/A';

    final statusColor = CampaignTileLogic.getStatusColor(status);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row: Campaign Name, Edit Icon & Status Badge
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    campaignName,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Edit button – navigates to edit campaign screen
                InkWell(
                  onTap: entity.campaignId != null
                      ? () => context.pushNamed(
                          'editCampaign',
                          pathParameters: {'id': entity.campaignId!},
                        )
                      : null,
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Icon(
                      Icons.edit,
                      size: 20,
                      color: theme.colorScheme.secondary,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                if (isUpdating)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  _StatusBadge(status: status, statusColor: statusColor),
              ],
            ),
            const SizedBox(height: 12),

            // Brand & Agency Info Row
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.business,
                            size: 16,
                            color: theme.colorScheme.primary.withValues(
                              alpha: 0.8,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Brand: $brandName',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (entity.poBrandId != null)
                            InkWell(
                              onTap: () => context.pushNamed(
                                'viewBrand',
                                pathParameters: {'id': entity.poBrandId!},
                              ),
                              borderRadius: BorderRadius.circular(12),
                              child: const Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                child: Icon(
                                  Icons.open_in_new,
                                  size: 16,
                                  color: Colors.blue,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.corporate_fare,
                            size: 16,
                            color: theme.colorScheme.onSurfaceVariant
                                .withValues(alpha: 0.8),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Agency: $agencyName',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 20),

            // Validity & Collabs Info Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today_outlined,
                            size: 14,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Valid From: $validFromStr',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 14,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Valid Until: $validUntilStr',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondaryContainer.withValues(
                      alpha: 0.4,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Collabs: $collabsCount',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSecondaryContainer,
                    ),
                  ),
                ),
              ],
            ),

            // Actions Row
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                CampaignActions(
                  entity: entity,
                  adapter: adapter,
                  showShare: false,
                  canDelete: false,
                  status: status,
                  isUpdating: isUpdating,
                  onUpdating: onUpdating,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  final Color statusColor;

  const _StatusBadge({required this.status, required this.statusColor});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor, width: 1),
      ),
      child: Text(
        status.toUpperCase(),
        style: theme.textTheme.bodySmall?.copyWith(
          color: statusColor,
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
      ),
    );
  }
}

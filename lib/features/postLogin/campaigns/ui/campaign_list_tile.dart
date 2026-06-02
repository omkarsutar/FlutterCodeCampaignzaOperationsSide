import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_supabase_order_app_mobile/core/providers/core_providers.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/services/entity_service.dart';
import '../model/campaign_model.dart';
import '../providers/campaign_tile_logic.dart';
import '../../cart/providers/cart_controller.dart';
import 'widgets/po_actions.dart';

class CampaignListTile extends ConsumerStatefulWidget {
  final ModelCampaign entity;
  final EntityAdapter<ModelCampaign> adapter;
  final VoidCallback? onTap;
  final bool? collaborationTile;
  final bool showShare;
  final void Function(String oldStatus, String newStatus)? onStatusChanged;

  const CampaignListTile({
    super.key,
    required this.entity,
    required this.adapter,
    this.onTap,
    this.collaborationTile,
    this.showShare = false,
    this.onStatusChanged,
  });

  @override
  ConsumerState<CampaignListTile> createState() => _CampaignListTileState();
}

class _CampaignListTileState extends ConsumerState<CampaignListTile> {
  bool _isUpdating = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isRbacReady = ref.watch(rbacInitializationProvider);
    final rbacService = ref.watch(rbacServiceProvider);

    final canDelete = isRbacReady && rbacService.canDelete('campaign');

    final campaignName =
        widget.entity.campaignName ??
        widget.entity.campaignNameString ??
        'Unnamed Campaign';

    final brandName =
        widget.adapter
            .getLabelValue(widget.entity, ModelCampaignFields.poBrandId)
            ?.toString() ??
        'Unknown Brand';
    final agencyName =
        widget.adapter
            .getLabelValue(widget.entity, ModelCampaignFields.poAgencyId)
            ?.toString() ??
        'Unknown Agency';
    final status = widget.entity.status ?? 'pending';
    final campaignType = widget.entity.effectiveCampaignType;
    final collabsCount = widget.entity.poLineItemCount ?? 0;
    final commentStr = widget.entity.userComment ?? '';
    final adminCommentStr = widget.entity.adminComment ?? '';
    final showCollabsCount = campaignType.isInfluencerCollaboration;

    // Date formatting (convert to local timezone first)
    final DateFormat formatter = DateFormat('dd MMM yyyy HH:mm');
    final validFromStr = widget.entity.validFrom != null
        ? formatter.format(widget.entity.validFrom!.toLocal())
        : 'N/A';
    final validUntilStr = widget.entity.validUntil != null
        ? formatter.format(widget.entity.validUntil!.toLocal())
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
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: widget.collaborationTile == true
            ? widget.onTap
            : (widget.onTap ??
                  () {
                    ref
                        .read(cartControllerProvider)
                        .editCampaign(context, widget.entity);
                  }),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row: Campaign Name & Edit Button & Status Badge
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
                  // Edit Button
                  InkWell(
                    onTap: widget.entity.campaignId != null
                        ? () => context.pushNamed(
                            'editCampaign',
                            pathParameters: {'id': widget.entity.campaignId!},
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
                  if (_isUpdating)
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
                            if (widget.entity.poBrandId != null)
                              InkWell(
                                onTap: () => context.pushNamed(
                                  'viewBrand',
                                  pathParameters: {
                                    'id': widget.entity.poBrandId!,
                                  },
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

              // Validity & Campaign Info Row
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
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildTypeChip(theme, campaignType.displayName),
                  if (showCollabsCount)
                    _buildMetricChip(
                      theme,
                      'Collabs: $collabsCount',
                      theme.colorScheme.secondaryContainer,
                      theme.colorScheme.onSecondaryContainer,
                    ),
                ],
              ),

              // Actions Row
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  CampaignActions(
                    entity: widget.entity,
                    adapter: widget.adapter,
                    showShare: widget.showShare,
                    canDelete: canDelete,
                    status: status,
                    isUpdating: _isUpdating,
                    onUpdating: (val) {
                      if (mounted) setState(() => _isUpdating = val);
                    },
                  ),
                ],
              ),

              if (commentStr.isNotEmpty)
                _buildComment(theme, 'User Comment', commentStr),
              if (adminCommentStr.isNotEmpty)
                _buildComment(
                  theme,
                  'Admin Comment',
                  adminCommentStr,
                  color: Colors.red.shade700,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildComment(
    ThemeData theme,
    String title,
    String commentStr, {
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Text(
        '$title: $commentStr',
        style: theme.textTheme.bodySmall?.copyWith(
          fontStyle: FontStyle.italic,
          color: color ?? theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _buildTypeChip(ThemeData theme, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: theme.textTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.onPrimaryContainer,
        ),
      ),
    );
  }

  Widget _buildMetricChip(
    ThemeData theme,
    String label,
    Color background,
    Color foreground,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: theme.textTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.bold,
          color: foreground,
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

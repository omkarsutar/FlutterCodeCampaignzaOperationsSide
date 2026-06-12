import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_supabase_order_app_mobile/core/providers/core_providers.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

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
    final showCollabsCount = campaignType.isInfluencerCollaboration;
    final statusColor = CampaignTileLogic.getStatusColor(status);
    final commentStr = widget.entity.userComment ?? '';
    final adminCommentStr = widget.entity.adminComment ?? '';
    final formatter = DateFormat('dd MMM yyyy HH:mm');
    final validFromStr = widget.entity.validFrom != null
        ? formatter.format(widget.entity.validFrom!.toLocal())
        : 'N/A';
    final validUntilStr = widget.entity.validUntil != null
        ? formatter.format(widget.entity.validUntil!.toLocal())
        : 'N/A';

    final roleName = ref.watch(roleNameProvider)?.toLowerCase();
    final isAdmin = roleName == 'admin';
    final isCollaborationTile = widget.collaborationTile == true;
    final cardColor = isCollaborationTile
        ? Colors.white
        : theme.colorScheme.surfaceContainerLowest;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 1,
      color: cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: isCollaborationTile
              ? theme.colorScheme.primary.withValues(alpha: 0.18)
              : theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: widget.collaborationTile == true
            ? widget.onTap
            : (widget.onTap ??
                  () {
                    ref
                        .read(cartControllerProvider)
                        .editCampaign(context, widget.entity);
                  }),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: Row(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Expanded(
                      child: _TypePill(label: campaignType.displayName),
                    ),
                    const SizedBox(width: 6),
                    if (_isUpdating)
                      const SizedBox(
                        width: 36,
                        height: 36,
                        child: Center(
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      )
                    else
                      _StatusBadge(status: status, statusColor: statusColor),
                    IconButton(
                      tooltip: 'Edit campaign',
                      icon: const Icon(Icons.edit_outlined),
                      iconSize: 20,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 36,
                        minHeight: 36,
                      ),
                      onPressed: widget.entity.campaignId != null
                          ? () => context.pushNamed(
                              'editCampaign',
                              pathParameters: {
                                'id': widget.entity.campaignId!,
                              },
                            )
                          : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              _InfoRow(
                icon: Icons.campaign_outlined,
                label: 'Campaign',
                value: campaignName,
                maxLines: null,
                overflow: TextOverflow.visible,
                valueStyle: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              if (isAdmin) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _InfoRow(
                        icon: Icons.business_outlined,
                        label: 'Brand',
                        value: brandName,
                        valueStyle: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                    if (widget.entity.poBrandId != null)
                      IconButton(
                        tooltip: 'View brand',
                        icon: const Icon(Icons.open_in_new),
                        iconSize: 18,
                        constraints: const BoxConstraints(
                          minWidth: 36,
                          minHeight: 36,
                        ),
                        onPressed: () => context.pushNamed(
                          'viewBrand',
                          pathParameters: {'id': widget.entity.poBrandId!},
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                _InfoRow(
                  icon: Icons.corporate_fare_outlined,
                  label: 'Agency',
                  value: agencyName,
                  valueStyle: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const Divider(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _InfoRow(
                          icon: Icons.calendar_today_outlined,
                          label: 'Valid From',
                          value: validFromStr,
                          valueStyle: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 4),
                        _InfoRow(
                          icon: Icons.calendar_today,
                          label: 'Valid Until',
                          value: validUntilStr,
                          valueStyle: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (showCollabsCount) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _MetricPill(
                      label: 'Collabs: $collabsCount',
                      background: theme.colorScheme.secondaryContainer,
                      foreground: theme.colorScheme.onSecondaryContainer,
                    ),
                  ],
                ),
              ],
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
      padding: const EdgeInsets.only(top: 8),
      child: Text(
        '$title: $commentStr',
        style: theme.textTheme.bodySmall?.copyWith(
          fontStyle: FontStyle.italic,
          color: color ?? theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final TextStyle? valueStyle;
  final int? maxLines;
  final TextOverflow? overflow;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueStyle,
    this.maxLines = 1,
    this.overflow = TextOverflow.ellipsis,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(icon, size: 16, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            '$label: $value',
            style: valueStyle ?? theme.textTheme.bodyMedium,
            maxLines: maxLines,
            overflow: overflow,
          ),
        ),
      ],
    );
  }
}

class _TypePill extends StatelessWidget {
  final String label;

  const _TypePill({required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w700,
          color: theme.colorScheme.onPrimaryContainer,
        ),
      ),
    );
  }
}

class _MetricPill extends StatelessWidget {
  final String label;
  final Color background;
  final Color foreground;

  const _MetricPill({
    required this.label,
    required this.background,
    required this.foreground,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor, width: 0.8),
      ),
      child: Text(
        status.toUpperCase(),
        style: theme.textTheme.labelSmall?.copyWith(
          color: statusColor,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

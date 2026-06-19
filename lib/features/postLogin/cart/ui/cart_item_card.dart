import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../collaborations/model/collaboration_model.dart';
import '../../collaborations/providers/collaboration_providers.dart';
import '../../collaborations/providers/collaboration_list_controller.dart';
import '../../campaigns/providers/campaign_providers.dart';
import '../../agencies/providers/agency_providers.dart';
import '../../brands/providers/brand_providers.dart';
import '../../influencers/influencer_barrel.dart';
import '../providers/cart_providers.dart';

class CartItemCard extends ConsumerStatefulWidget {
  final ModelCollaboration entity;
  final List<ModelInfluencer> influencers;
  final bool isReadOnly;
  final String? lastModifiedId;
  final String? poId;

  const CartItemCard({
    super.key,
    required this.entity,
    required this.influencers,
    this.isReadOnly = false,
    this.lastModifiedId,
    this.poId,
  });

  @override
  ConsumerState<CartItemCard> createState() => _CartItemCardState();
}

class _CartItemCardState extends ConsumerState<CartItemCard> {
  bool _isHighlighted = false;
  Timer? _highlightTimer;

  @override
  void initState() {
    super.initState();
  }

  void _triggerHighlight() {
    if (!mounted) return;
    setState(() => _isHighlighted = true);
    _highlightTimer?.cancel();
    _highlightTimer = Timer(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() => _isHighlighted = false);
      }
    });
  }

  @override
  void dispose() {
    _highlightTimer?.cancel();
    super.dispose();
  }

  ModelInfluencer? get _influencer {
    try {
      return widget.influencers.firstWhere(
        (p) => p.influencerId == widget.entity.influencerId,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lastModifiedId =
        widget.lastModifiedId ??
        ref.watch(cartProvider.select((s) => s.lastModifiedItemId));

    if (lastModifiedId == widget.entity.collaborationId && !_isHighlighted) {
      Future.microtask(() => _triggerHighlight());
    }

    final influencer = _influencer;
    String? influencerImage = influencer?.influencerImageUrl;
    if (influencerImage != null && influencerImage.isNotEmpty) {
      influencerImage = Uri.encodeFull(Uri.decodeFull(influencerImage));
    }

    final String displayName =
        influencer?.influencerName ??
        widget.entity.resolvedLabels['influencer_id_label'] ??
        'Unnamed Influencer';
    final String category =
        influencer?.influencerCategory ??
        widget.entity.resolvedLabels['influencer_category_label'] ??
        'General';

    final campaignAsync = widget.entity.campaignId != null
        ? ref.watch(campaignByIdProvider(widget.entity.campaignId!))
        : null;
    final campaign = campaignAsync?.valueOrNull;

    final brandAsync = campaign?.campaignBrandId != null
        ? ref.watch(brandByIdProvider(campaign!.campaignBrandId!))
        : null;
    final agencyAsync = campaign?.campaignAgencyId != null
        ? ref.watch(agencyByIdProvider(campaign!.campaignAgencyId!))
        : null;

    final campaignName =
        campaign?.campaignNameString ??
        campaign?.campaignName ??
        widget.entity.resolvedLabels['campaign_id_label']?.toString() ??
        widget.entity.campaignId ??
        '-';
    final brandName =
        brandAsync?.valueOrNull?.brandName ??
        campaign?.campaignBrandLabel?.toString() ??
        '-';
    final agencyName =
        agencyAsync?.valueOrNull?.agencyName ??
        campaign?.campaignAgencyLabel?.toString() ??
        '-';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOut,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _isHighlighted
            ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3)
            : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: _isHighlighted
              ? theme.colorScheme.primary.withValues(alpha: 0.5)
              : theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          width: _isHighlighted ? 2 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          context.pushNamed(
            'viewCollaboration',
            pathParameters: {'id': widget.entity.collaborationId!},
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Influencer Image
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 80,
                    height: 80,
                    color: theme.colorScheme.surfaceContainerHighest.withValues(
                      alpha: 0.3,
                    ),
                    child:
                        (influencerImage != null && influencerImage.isNotEmpty)
                        ? Image.network(
                            influencerImage,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(
                                  Icons.person_outline,
                                  color: Colors.grey,
                                  size: 36,
                                ),
                          )
                        : const Icon(
                            Icons.person_outline,
                            color: Colors.grey,
                            size: 36,
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                // Influencer Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              displayName,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                height: 1.2,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 4),
                          if (!widget.isReadOnly) ...[
                            GestureDetector(
                              onTap: () async {
                                await context.pushNamed(
                                  'editCollaboration',
                                  pathParameters: {
                                    'id': widget.entity.collaborationId!,
                                  },
                                );
                                if (context.mounted) {
                                  if (widget.poId != null) {
                                    ref.invalidate(
                                      collaborationListControllerProvider(
                                        widget.poId!,
                                      ),
                                    );
                                  }
                                }
                              },
                              child: Icon(
                                Icons.edit_outlined,
                                color: theme.colorScheme.primary.withValues(
                                  alpha: 0.7,
                                ),
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            GestureDetector(
                              onTap: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Delete Collaboration?'),
                                    content: const Text(
                                      'Are you sure you want to delete this collaboration from this campaign?',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, false),
                                        child: const Text('Cancel'),
                                      ),
                                      ElevatedButton(
                                        onPressed: () =>
                                            Navigator.pop(context, true),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red,
                                        ),
                                        child: const Text(
                                          'Delete',
                                          style: TextStyle(color: Colors.white),
                                        ),
                                      ),
                                    ],
                                  ),
                                );

                                if (confirm == true && context.mounted) {
                                  try {
                                    if (widget.poId != null) {
                                      await ref
                                          .read(
                                            collaborationListControllerProvider(
                                              widget.poId!,
                                            ).notifier,
                                          )
                                          .deleteItem(
                                            widget.entity.collaborationId!,
                                            widget.poId!,
                                          );
                                      ref.invalidate(
                                        collaborationsByPoIdProvider(
                                          widget.poId!,
                                        ),
                                      );
                                    } else {
                                      await ref
                                          .read(collaborationServiceProvider)
                                          .delete(
                                            widget.entity.collaborationId!,
                                          );
                                      if (widget.entity.campaignId != null &&
                                          widget
                                              .entity
                                              .campaignId!
                                              .isNotEmpty) {
                                        ref.invalidate(
                                          collaborationsByPoIdProvider(
                                            widget.entity.campaignId!,
                                          ),
                                        );
                                      }
                                    }
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text('Failed to delete: $e'),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  }
                                }
                              },
                              child: Icon(
                                Icons.delete_outline_rounded,
                                color: theme.colorScheme.error.withValues(
                                  alpha: 0.7,
                                ),
                                size: 20,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        category,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      if (widget.isReadOnly) ...[
                        const SizedBox(height: 8),
                        _MetaLine(label: 'Agency', value: agencyName),
                        _MetaLine(label: 'Brand', value: brandName),
                        _MetaLine(label: 'Campaign', value: campaignName),
                        const SizedBox(height: 10),
                      ],
                      const Spacer(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.shopping_cart_outlined,
                            size: 16,
                            color: Colors.deepPurple,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Purchases: ${widget.entity.purchaseCount ?? 0}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.deepPurple,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Icon(
                            Icons.install_mobile,
                            size: 16,
                            color: Colors.pink,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Installs: ${widget.entity.totalInstalls}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.pink,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MetaLine extends StatelessWidget {
  final String label;
  final String value;

  const _MetaLine({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Expanded(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

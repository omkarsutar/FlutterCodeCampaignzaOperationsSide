import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../influencers/influencer_barrel.dart';
import '../model/collaboration_model.dart';
import '../providers/collaboration_list_controller.dart';
import '../providers/collaboration_providers.dart';

class CollaborationCard extends ConsumerStatefulWidget {
  final ModelCollaboration entity;
  final List<ModelInfluencer> influencers;
  final String poId; // maps to campaignId

  const CollaborationCard({
    super.key,
    required this.entity,
    required this.influencers,
    required this.poId,
  });

  @override
  ConsumerState<CollaborationCard> createState() => _CollaborationCardState();
}

class _CollaborationCardState extends ConsumerState<CollaborationCard> {
  late TextEditingController _rateController;
  late TextEditingController _fixedAmountController;
  late TextEditingController _barterController;
  late TextEditingController _agreedController;

  Timer? _debounceTimer;
  bool _isExpanded = false;
  bool _isTransitionHighlighted = false;
  Timer? _highlightTimer;

  @override
  void initState() {
    super.initState();
    _rateController = TextEditingController(
      text: widget.entity.commissionRate != null ? widget.entity.commissionRate!.toStringAsFixed(1) : '',
    );
    _fixedAmountController = TextEditingController(
      text: widget.entity.fixedAmount != null ? widget.entity.fixedAmount!.toStringAsFixed(2) : '',
    );
    _barterController = TextEditingController(text: widget.entity.barterDescription ?? '');
    _agreedController = TextEditingController(
      text: widget.entity.agreedCommissionAmount != null
          ? widget.entity.agreedCommissionAmount!.toStringAsFixed(2)
          : '',
    );
  }

  @override
  void didUpdateWidget(covariant CollaborationCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.entity.commissionRate != widget.entity.commissionRate) {
      final newVal = widget.entity.commissionRate != null ? widget.entity.commissionRate!.toStringAsFixed(1) : '';
      if (_rateController.text != newVal) _rateController.text = newVal;
    }
    if (oldWidget.entity.fixedAmount != widget.entity.fixedAmount) {
      final newVal = widget.entity.fixedAmount != null ? widget.entity.fixedAmount!.toStringAsFixed(2) : '';
      if (_fixedAmountController.text != newVal) _fixedAmountController.text = newVal;
    }
    if (oldWidget.entity.barterDescription != widget.entity.barterDescription) {
      final newVal = widget.entity.barterDescription ?? '';
      if (_barterController.text != newVal) _barterController.text = newVal;
    }
    if (oldWidget.entity.agreedCommissionAmount != widget.entity.agreedCommissionAmount) {
      final newVal =
          widget.entity.agreedCommissionAmount != null ? widget.entity.agreedCommissionAmount!.toStringAsFixed(2) : '';
      if (_agreedController.text != newVal) _agreedController.text = newVal;
    }
  }

  void _triggerHighlight() {
    if (!mounted) return;
    setState(() => _isTransitionHighlighted = true);
    _highlightTimer?.cancel();
    _highlightTimer = Timer(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() => _isTransitionHighlighted = false);
      }
    });
  }

  @override
  void dispose() {
    _rateController.dispose();
    _fixedAmountController.dispose();
    _barterController.dispose();
    _agreedController.dispose();
    _debounceTimer?.cancel();
    _highlightTimer?.cancel();
    super.dispose();
  }

  ModelInfluencer? get _influencer {
    try {
      return widget.influencers.firstWhere(
        (i) => i.influencerId == widget.entity.influencerId,
      );
    } catch (_) {
      return null;
    }
  }

  void _triggerUpdate(ModelCollaboration updated) {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      ref
          .read(collaborationListControllerProvider(widget.poId).notifier)
          .updateItem(updated, widget.poId);
    });
  }

  Future<void> _selectInfluencer() async {
    final result = await context.pushNamed(
      InfluencerRoutesJson.listRouteName,
      queryParameters: {'selection': 'true'},
    );

    if (result is ModelInfluencer) {
      final updated = widget.entity.copyWith(
        influencerId: result.influencerId,
        commissionRate: result.baseCommissionRate,
        agreedCommissionAmount: result.baseCommissionRate * 100, // starting value or calculated
        resolvedLabels: {
          ...widget.entity.resolvedLabels,
          'influencer_id_label': result.influencerName,
          'influencer_category_label': result.influencerCategory,
          'base_commission_rate_label': result.baseCommissionRate,
          'influencer_image_label': result.influencerImageUrl,
        },
      );
      _rateController.text = result.baseCommissionRate.toStringAsFixed(1);
      _agreedController.text = (result.baseCommissionRate * 100).toStringAsFixed(2);
      ref
          .read(collaborationListControllerProvider(widget.poId).notifier)
          .updateItem(updated, widget.poId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lastModifiedId = ref.watch(
      collaborationListControllerProvider(
        widget.poId,
      ).select((asyncState) => asyncState.value?.lastModifiedItemId),
    );

    // Trigger highlight if this item was the last one modified
    if (lastModifiedId == widget.entity.collaborationId &&
        !_isTransitionHighlighted) {
      Future.microtask(() => _triggerHighlight());
    }

    final influencer = _influencer;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOut,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _isTransitionHighlighted
            ? theme.colorScheme.primaryContainer.withValues(alpha: 0.2)
            : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: _isTransitionHighlighted
              ? theme.colorScheme.primary
              : theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          width: _isTransitionHighlighted ? 2 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4.0, 8.0, 8.0, 8.0),
          child: Column(
            children: [
              // Row 1: Influencer Selection + Accepted status + Expand Button
              Row(
                children: [
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _isExpanded = !_isExpanded;
                      });
                    },
                    icon: Icon(
                      _isExpanded ? Icons.expand_less : Icons.expand_more,
                      color: theme.colorScheme.primary,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    constraints: const BoxConstraints(
                      minWidth: 30,
                      minHeight: 30,
                    ),
                    visualDensity: const VisualDensity(
                      horizontal: -4,
                      vertical: -4,
                    ),
                  ),

                  // Influencer Selection
                  Expanded(
                    child: InkWell(
                      onTap: _selectInfluencer,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Influencer',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 8,
                          ),
                        ),
                        child: Text(
                          influencer?.influencerName ??
                              widget.entity.resolvedLabels['influencer_id_label']?.toString() ??
                              'Select Influencer',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Accepted Switch
                  Column(
                    children: [
                      Text(
                        'Accepted',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      SizedBox(
                        height: 32,
                        child: Switch(
                          value: widget.entity.isAcceptedByInfluencer,
                          onChanged: (val) {
                            final updated = widget.entity.copyWith(
                              isAcceptedByInfluencer: val,
                            );
                            ref
                                .read(collaborationListControllerProvider(widget.poId).notifier)
                                .updateItem(updated, widget.poId);
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // Row 2: Commission Type, Inputs, and Details
              if (_isExpanded) ...[
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 8),

                // Commission Type Dropdown
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<CommissionType>(
                        initialValue: widget.entity.commissionType ?? CommissionType.percentage,
                        decoration: const InputDecoration(
                          labelText: 'Commission Type',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 8,
                          ),
                        ),
                        items: CommissionType.values.map((type) {
                          return DropdownMenuItem<CommissionType>(
                            value: type,
                            child: Text(type.displayName),
                          );
                        }).toList(),
                        onChanged: (CommissionType? val) {
                          if (val != null) {
                            final updated = widget.entity.copyWith(
                              commissionType: val,
                            );
                            ref
                                .read(collaborationListControllerProvider(widget.poId).notifier)
                                .updateItem(updated, widget.poId);
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Conditional inputs based on Commission Type
                if (widget.entity.commissionType == CommissionType.percentage) ...[
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _rateController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'Commission Rate (%)',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.percent, size: 16),
                            contentPadding: EdgeInsets.all(8),
                          ),
                          onChanged: (val) {
                            final d = double.tryParse(val);
                            if (d != null) {
                              final updated = widget.entity.copyWith(commissionRate: d);
                              _triggerUpdate(updated);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ] else if (widget.entity.commissionType == CommissionType.fixedAmount) ...[
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _fixedAmountController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'Fixed Amount (₹)',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.currency_rupee, size: 16),
                            contentPadding: EdgeInsets.all(8),
                          ),
                          onChanged: (val) {
                            final d = double.tryParse(val);
                            if (d != null) {
                              final updated = widget.entity.copyWith(
                                fixedAmount: d,
                                agreedCommissionAmount: d, // Auto sync fixed amount to agreed amount
                              );
                              _agreedController.text = d.toStringAsFixed(2);
                              _triggerUpdate(updated);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ] else if (widget.entity.commissionType == CommissionType.barter) ...[
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _barterController,
                          maxLines: 2,
                          decoration: const InputDecoration(
                            labelText: 'Barter Description',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.card_giftcard, size: 16),
                            contentPadding: EdgeInsets.all(8),
                          ),
                          onChanged: (val) {
                            final updated = widget.entity.copyWith(barterDescription: val);
                            _triggerUpdate(updated);
                          },
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 12),

                // Agreed Commission Amount Input
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _agreedController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Agreed Commission (₹)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.wallet, size: 16),
                          contentPadding: EdgeInsets.all(8),
                        ),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        onChanged: (val) {
                          final d = double.tryParse(val);
                          if (d != null) {
                            final updated = widget.entity.copyWith(agreedCommissionAmount: d);
                            _triggerUpdate(updated);
                          }
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Delete Button
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () async {
                      if (widget.entity.collaborationId != null) {
                        await ref
                            .read(collaborationListControllerProvider(widget.poId).notifier)
                            .deleteItem(widget.entity.collaborationId!, widget.poId);
                        ref.invalidate(collaborationsByPoIdProvider(widget.poId));
                      }
                    },
                    icon: const Icon(Icons.delete, color: Colors.red, size: 18),
                    label: const Text(
                      'Remove Collaboration',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

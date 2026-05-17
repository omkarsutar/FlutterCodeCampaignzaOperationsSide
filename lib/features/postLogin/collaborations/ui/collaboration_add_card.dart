import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../influencers/influencer_barrel.dart';
import '../model/collaboration_model.dart';
import '../providers/collaboration_list_controller.dart';
import '../../cart/providers/cart_providers.dart';

class CollaborationAddCard extends ConsumerStatefulWidget {
  final List<ModelInfluencer> influencers;
  final String poId; // maps to campaignId
  final void Function(ModelCollaboration)? onAddLocal;
  final ModelInfluencer? initialInfluencer;

  const CollaborationAddCard({
    super.key,
    required this.influencers,
    required this.poId,
    this.onAddLocal,
    this.initialInfluencer,
  });

  @override
  ConsumerState<CollaborationAddCard> createState() =>
      _CollaborationAddCardState();
}

class _CollaborationAddCardState extends ConsumerState<CollaborationAddCard> {
  final TextEditingController _rateController = TextEditingController();
  final TextEditingController _fixedAmountController = TextEditingController();
  final TextEditingController _barterController = TextEditingController();
  final TextEditingController _agreedController = TextEditingController();

  String? _selectedInfluencerId;
  ModelInfluencer? _selectedInfluencer;
  CommissionType _commissionType = CommissionType.percentage;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialInfluencer != null) {
      _selectedInfluencer = widget.initialInfluencer;
      _selectedInfluencerId = widget.initialInfluencer!.influencerId;
      _rateController.text =
          widget.initialInfluencer!.baseCommissionRate.toStringAsFixed(1);
      _agreedController.text =
          (widget.initialInfluencer!.baseCommissionRate * 100)
              .toStringAsFixed(2);
    }
  }

  @override
  void dispose() {
    _rateController.dispose();
    _fixedAmountController.dispose();
    _barterController.dispose();
    _agreedController.dispose();
    super.dispose();
  }

  Future<void> _selectInfluencer() async {
    final result = await context.pushNamed(
      InfluencerRoutesJson.listRouteName,
      queryParameters: {'selection': 'true'},
    );

    if (result is ModelInfluencer) {
      if (mounted) {
        setState(() {
          _selectedInfluencer = result;
          _selectedInfluencerId = result.influencerId;
          _rateController.text = result.baseCommissionRate.toStringAsFixed(1);
          _agreedController.text = (result.baseCommissionRate * 100).toStringAsFixed(2);
        });
      }
    }
  }

  Future<void> _handleAdd() async {
    if (_selectedInfluencerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an influencer')),
      );
      return;
    }

    final double rate = double.tryParse(_rateController.text) ?? 0.0;
    final double fixedAmount = double.tryParse(_fixedAmountController.text) ?? 0.0;
    final double agreedAmount = double.tryParse(_agreedController.text) ?? 0.0;

    // Check for duplicate influencer in this Campaign or local cart
    final List<ModelCollaboration> existingItems;
    if (widget.onAddLocal != null) {
      existingItems = ref.read(cartProvider).items;
    } else {
      existingItems = ref
              .read(collaborationListControllerProvider(widget.poId))
              .value
              ?.items ??
          [];
    }
    
    final isAlreadyPresent = existingItems.any(
      (item) => item.influencerId == _selectedInfluencerId,
    );

    if (isAlreadyPresent) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${_selectedInfluencer!.influencerName} is already in a collaboration.'),
          backgroundColor: Colors.orange.shade800,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    final newItem = ModelCollaboration(
      campaignId: widget.poId,
      influencerId: _selectedInfluencerId,
      commissionType: _commissionType,
      commissionRate: _commissionType == CommissionType.percentage ? rate : null,
      fixedAmount: _commissionType == CommissionType.fixedAmount ? fixedAmount : null,
      barterDescription: _commissionType == CommissionType.barter ? _barterController.text : null,
      agreedCommissionAmount: agreedAmount,
      isAcceptedByInfluencer: false,
      resolvedLabels: {
        'influencer_id_label': _selectedInfluencer!.influencerName,
        'influencer_category_label': _selectedInfluencer!.influencerCategory,
        'base_commission_rate_label': _selectedInfluencer!.baseCommissionRate,
        'influencer_image_label': _selectedInfluencer!.influencerImageUrl,
      },
    );

    if (widget.onAddLocal != null) {
      widget.onAddLocal!(newItem);
      if (mounted) {
        setState(() => _isSaving = false);
        // Reset form
        setState(() {
          if (widget.initialInfluencer == null) {
             _selectedInfluencer = null;
             _selectedInfluencerId = null;
          }
          _commissionType = CommissionType.percentage;
          if (widget.initialInfluencer == null) {
             _rateController.text = "";
             _agreedController.text = "";
          }
          _fixedAmountController.text = "";
          _barterController.text = "";
        });
      }
      return;
    }

    final success = await ref
        .read(collaborationListControllerProvider(widget.poId).notifier)
        .addItem(newItem, widget.poId);

    if (mounted) {
      setState(() => _isSaving = false);
      if (success) {
        // Reset form
        setState(() {
          _selectedInfluencer = null;
          _selectedInfluencerId = null;
          _commissionType = CommissionType.percentage;
          _rateController.text = "";
          _fixedAmountController.text = "";
          _barterController.text = "";
          _agreedController.text = "";
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final purpleBg = Colors.purple.shade900;
    const contrastColor = Colors.white;
    final accentColor = Colors.purple.shade100;

    return Container(
      decoration: BoxDecoration(
        color: purpleBg,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 15,
            spreadRadius: 2,
            offset: const Offset(0, -5),
          ),
        ],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(color: accentColor.withValues(alpha: 0.5), width: 3),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag Handle / Indicator
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: contrastColor.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 8),

            // Header "New Collaboration"
            Text(
              "New Collaboration",
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: contrastColor,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 12),

            // Row 1: Select Influencer
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: _selectInfluencer,
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Influencer',
                        labelStyle: TextStyle(color: accentColor),
                        border: OutlineInputBorder(
                          borderSide: BorderSide(color: accentColor),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: accentColor.withValues(alpha: 0.5),
                          ),
                        ),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.05),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        isDense: true,
                      ),
                      child: Text(
                        _selectedInfluencer?.influencerName ?? 'Select Influencer',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Dropdown: Commission Type
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<CommissionType>(
                    initialValue: _commissionType,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    dropdownColor: purpleBg,
                    decoration: InputDecoration(
                      labelText: 'Commission Type',
                      labelStyle: TextStyle(color: accentColor),
                      border: OutlineInputBorder(
                        borderSide: BorderSide(color: accentColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: accentColor.withValues(alpha: 0.5),
                        ),
                      ),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.05),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      isDense: true,
                    ),
                    items: CommissionType.values.map((type) {
                      return DropdownMenuItem<CommissionType>(
                        value: type,
                        child: Text(type.displayName),
                      );
                    }).toList(),
                    onChanged: (CommissionType? val) {
                      if (val != null) {
                        setState(() {
                          _commissionType = val;
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Input Fields based on Commission Type
            if (_commissionType == CommissionType.percentage) ...[
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _rateController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Commission Rate (%)',
                        labelStyle: TextStyle(color: accentColor),
                        border: const OutlineInputBorder(),
                        prefixIcon: Icon(Icons.percent, color: accentColor, size: 16),
                        contentPadding: const EdgeInsets.all(8),
                      ),
                    ),
                  ),
                ],
              ),
            ] else if (_commissionType == CommissionType.fixedAmount) ...[
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _fixedAmountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Fixed Amount (₹)',
                        labelStyle: TextStyle(color: accentColor),
                        border: const OutlineInputBorder(),
                        prefixIcon: Icon(Icons.currency_rupee, color: accentColor, size: 16),
                        contentPadding: const EdgeInsets.all(8),
                      ),
                      onChanged: (val) {
                        final d = double.tryParse(val);
                        if (d != null) {
                          setState(() {
                            _agreedController.text = d.toStringAsFixed(2);
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),
            ] else if (_commissionType == CommissionType.barter) ...[
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _barterController,
                      maxLines: 2,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Barter Description',
                        labelStyle: TextStyle(color: accentColor),
                        border: const OutlineInputBorder(),
                        prefixIcon: Icon(Icons.card_giftcard, color: accentColor, size: 16),
                        contentPadding: const EdgeInsets.all(8),
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),

            // Agreed Commission Amount
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _agreedController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      labelText: 'Agreed Commission (₹)',
                      labelStyle: TextStyle(color: accentColor),
                      border: const OutlineInputBorder(),
                      prefixIcon: Icon(Icons.wallet, color: accentColor, size: 16),
                      contentPadding: const EdgeInsets.all(8),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Action Row: Add Button
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton.icon(
                  onPressed: _isSaving ? null : _handleAdd,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.add),
                  label: const Text("Add Collaboration"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: contrastColor,
                    foregroundColor: purpleBg,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

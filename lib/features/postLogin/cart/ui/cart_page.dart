import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_supabase_order_app_mobile/shared/widgets/shared_widget_barrel.dart';
import 'package:go_router/go_router.dart';
import '../providers/cart_view_logic.dart';
import '../providers/cart_providers.dart';
import '../../../../core/providers/localization_provider.dart';
import '../../influencers/influencer_barrel.dart';
import '../../brands/brand_barrel.dart';
import '../../agencies/agency_barrel.dart';
import '../../campaigns/ui/widgets/po_brand_route_info.dart';
import '../../campaigns/ui/widgets/po_actions.dart';
import '../../campaigns/campaign_barrel.dart';
import '../../collaborations/providers/collaboration_providers.dart';
import 'cart_item_card.dart';

class CartPage extends ConsumerStatefulWidget {
  const CartPage({super.key});

  @override
  ConsumerState<CartPage> createState() => _CartPageState();
}

class _CartPageState extends ConsumerState<CartPage>
    with SingleTickerProviderStateMixin {
  bool _isUpdating = false;

  late AnimationController _profitHighlightController;
  late Animation<double> _profitScaleAnimation;
  late Animation<Color?> _profitColorAnimation;

  @override
  void initState() {
    super.initState();
    _profitHighlightController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _profitScaleAnimation =
        TweenSequence<double>([
          TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.2), weight: 50),
          TweenSequenceItem(tween: Tween(begin: 1.2, end: 1.0), weight: 50),
        ]).animate(
          CurvedAnimation(
            parent: _profitHighlightController,
            curve: Curves.easeInOut,
          ),
        );

    _profitColorAnimation =
        ColorTween(
          begin: Colors.green.withValues(alpha: 0.2),
          end: Colors.white,
        ).animate(
          CurvedAnimation(
            parent: _profitHighlightController,
            curve: Curves.linear,
          ),
        );

  }

  @override
  void dispose() {
    _profitHighlightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final viewData = ref.watch(cartViewLogicProvider);
    final influencers = ref.watch(influencersStreamProvider).value ?? [];
    final l10n = ref.watch(l10nProvider);
    final cartState = ref.watch(cartProvider);

    final isReadOnly = cartState.isReadOnly;

    ref.listen(
      cartViewLogicProvider.select((d) => (d.totalProfit, d.itemCount)),
      (previous, next) {
        if (previous != next && next.$1 != '0.00') {
          _profitHighlightController.forward(from: 0.0);
        }
      },
    );

    final canPop = context.canPop();

    return Scaffold(
      appBar: CustomAppBar(
        title: l10n['my_cart'] ?? 'My Cart',
        showBack: canPop,
      ),
      drawer: canPop ? null : const CustomDrawer(),
      body: Column(
        children: [
          if (!viewData.isEmpty) _buildSummaryHeader(context, viewData, l10n),
          Expanded(
            child: viewData.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.shopping_cart_outlined,
                          size: 64,
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.2,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          l10n['empty_cart_msg'] ?? 'Your cart is empty',
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        FilledButton.icon(
                          onPressed: () {
                            final campaignId = ref.read(cartProvider).campaignId;
                            if (campaignId == null || campaignId.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('No active campaign loaded.'),
                                ),
                              );
                              return;
                            }
                            context.pushNamed(
                              'newCollaboration',
                              queryParameters: {'campaign_id': campaignId},
                            );
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('Add Collaboration'),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 20, top: 10),
                    itemCount: viewData.items.length,
                    itemBuilder: (context, index) {
                      final processedItem = viewData.items[index];
                      return CartItemCard(
                        key: ValueKey(processedItem.item.collaborationId),
                        entity: processedItem.item,
                        influencers: influencers,
                        isReadOnly: isReadOnly,
                      );
                    },
                  ),
          ),
          if (!viewData.isEmpty && !isReadOnly)
            _buildActionFooter(context, viewData, l10n),
        ],
      ),
    );
  }

  Widget _buildSummaryHeader(
    BuildContext context,
    ProcessedCartData viewData,
    Map<String, String> l10n,
  ) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            offset: const Offset(0, 4),
            blurRadius: 8,
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            if (ref.watch(cartProvider).brandId != null) ...[
              Builder(
                builder: (context) {
                  final cartState = ref.watch(cartProvider);
                  final brandAsync = ref.watch(
                    brandByIdProvider(cartState.brandId!),
                  );
                  final routeAsync = ref.watch(
                    agencyByIdProvider(cartState.agencyId!),
                  );
                  final adapter = ref.watch(campaignAdapterProvider);

                  // Create a dummy/temp PO entity for actions
                  final tempPo = ModelCampaign(
                    poId: cartState.campaignId,
                    poBrandId: cartState.brandId,
                    poAgencyId: cartState.agencyId,
                    status: cartState.status,
                  );

                  return CampaignBrandAgencyInfo(
                    brandName: brandAsync.value?.brandName ?? 'Loading...',
                    agencyName: routeAsync.value?.agencyName ?? 'Loading...',
                    campaignId: null, // Hide PO ID on Cart Page
                    status: cartState.status,
                    trailing: CampaignActions(
                      entity: tempPo,
                      adapter: adapter,
                      status: cartState.status ?? 'pending',
                      isUpdating: _isUpdating,
                      onUpdating: (val) {
                        if (mounted) setState(() => _isUpdating = val);
                      },
                    ),
                  );
                },
              ),
              const Divider(),
              const SizedBox(height: 8),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSummaryItem(
                  context,
                  l10n['items'] ?? 'Items',
                  '${viewData.itemCount}',
                  valueSize: 18,
                  crossAxisAlignment: CrossAxisAlignment.center,
                ),
                AnimatedBuilder(
                  animation: _profitHighlightController,
                  builder: (context, child) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _profitHighlightController.value > 0
                            ? _profitColorAnimation.value
                            : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.green.withValues(alpha: 0.1),
                          width: 1,
                        ),
                      ),
                      child: ScaleTransition(
                        scale: _profitScaleAnimation,
                        child: _buildSummaryItem(
                          context,
                          l10n['brand_profit'] ?? 'Brand Profit on MRP',
                          '₹${viewData.totalProfit}',
                          color: Colors.green[700],
                          valueSize: 18,
                          isBold: true,
                        ),
                      ),
                    );
                  },
                ),
                _buildSummaryItem(
                  context,
                  l10n['final_amount'] ?? 'Final Amount',
                  '₹${viewData.totalAmount}',
                  isBold: true,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  valueSize: 18,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionFooter(
    BuildContext context,
    ProcessedCartData viewData,
    Map<String, String> l10n,
  ) {
    final theme = Theme.of(context);
    final campaignId = ref.watch(cartProvider).campaignId;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            offset: const Offset(0, -4),
            blurRadius: 12,
          ),
        ],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Delete All Button
            OutlinedButton.icon(
              onPressed: () async {
                if (campaignId == null || campaignId.isEmpty) return;

                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Delete All Collaborations?'),
                    content: const Text(
                      'Are you sure you want to delete all collaborations for this campaign from Supabase? This action cannot be undone.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                        child: const Text(
                          'Delete All',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                );

                if (confirm == true && context.mounted) {
                  try {
                    await ref
                        .read(collaborationServiceProvider)
                        .deleteAllByPo(campaignId);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Successfully deleted all collaborations.'),
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Failed to delete all: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                }
              },
              icon: const Icon(Icons.delete_sweep_outlined, color: Colors.red),
              label: const Text('Delete All', style: TextStyle(color: Colors.red)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Add Collaboration Button
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  if (campaignId == null || campaignId.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('No active campaign loaded.'),
                      ),
                    );
                    return;
                  }
                  context.pushNamed(
                    'newCollaboration',
                    queryParameters: {'campaign_id': campaignId},
                  );
                },
                icon: const Icon(Icons.add, size: 18),
                label: const Text(
                  'Add Collaboration',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(
    BuildContext context,
    String label,
    String value, {
    bool isBold = false,
    Color? color,
    double? valueSize,
    CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.center,
  }) {
    final theme = Theme.of(context);
    final labelStyle = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
      fontSize: 12,
    );
    final valueStyle = theme.textTheme.bodySmall?.copyWith(
      fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
      color: color ?? theme.colorScheme.onSurface,
      fontSize: valueSize ?? 14,
    );

    return Column(
      crossAxisAlignment: crossAxisAlignment,
      children: [
        Text(label, style: labelStyle),
        const SizedBox(height: 2),
        Text(value, style: valueStyle),
      ],
    );
  }
}

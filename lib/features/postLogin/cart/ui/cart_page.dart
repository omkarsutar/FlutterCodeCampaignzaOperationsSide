import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_supabase_order_app_mobile/shared/widgets/shared_widget_barrel.dart';
import 'package:go_router/go_router.dart';
import '../providers/cart_view_logic.dart';
import '../providers/cart_providers.dart';
import '../../../../core/providers/localization_provider.dart';
import '../../influencers/influencer_barrel.dart';
import '../../campaigns/campaign_barrel.dart';
import '../../collaborations/providers/collaboration_providers.dart';
import 'cart_item_card.dart';
import 'widgets/cart_campaign_tile.dart';

class CartPage extends ConsumerStatefulWidget {
  const CartPage({super.key});

  @override
  ConsumerState<CartPage> createState() => _CartPageState();
}

class _CartPageState extends ConsumerState<CartPage> {
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
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
                            final campaignId = ref
                                .read(cartProvider)
                                .campaignId;
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
    // The summary header previously displayed a row with items, profit, and total amount.
    // Those rows have been removed. We now simply show the campaign tile (if a brand is set)
    // and let it occupy the full available width, matching the layout on the campaigns list page.
    if (ref.watch(cartProvider).brandId == null) return const SizedBox.shrink();
    return Builder(
      builder: (context) {
        final cartState = ref.watch(cartProvider);
        final campaignAsync = ref.watch(
          campaignByIdProvider(cartState.campaignId!),
        );
        final adapter = ref.watch(campaignAdapterProvider);

        return campaignAsync.when(
          data: (campaign) => campaign != null
              ? CartCampaignTile(
                  entity: campaign,
                  adapter: adapter,
                  isUpdating: _isUpdating,
                  onUpdating: (val) {
                    if (mounted) setState(() => _isUpdating = val);
                  },
                )
              : const Center(child: Text('Campaign not found')),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) =>
              Center(child: Text('Error loading campaign: $error')),
        );
      },
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
                    ref.invalidate(collaborationsByPoIdProvider(campaignId));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Successfully deleted all collaborations.',
                          ),
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
              label: const Text(
                'Delete All',
                style: TextStyle(color: Colors.red),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 16,
                ),
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

  // The summary item widget was used for the removed summary row. It is no longer needed.
  // Keeping the method would add dead code, so it has been removed.
}

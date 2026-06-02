import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/config/module_config.dart';
import 'package:flutter_supabase_order_app_mobile/features/postLogin/campaigns/campaign_barrel.dart';
import 'package:flutter_supabase_order_app_mobile/shared/widgets/shared_widget_barrel.dart';
import 'package:flutter_supabase_order_app_mobile/core/utils/snackbar_utils.dart';
import '../providers/collaboration_providers.dart';
import '../providers/collaboration_list_controller.dart';
import 'collaboration_add_card.dart';
import '../../cart/ui/cart_item_card.dart';
import '../../campaigns/ui/widgets/referrer_link_tile.dart';

class CollaborationListPageRiverpod extends ConsumerStatefulWidget {
  final String poId;
  final String entityLabel;
  final String viewRouteName;
  final String newRouteName;
  final SortingConfig? initialSorting;

  const CollaborationListPageRiverpod({
    super.key,
    required this.poId,
    required this.entityLabel,
    required this.viewRouteName,
    required this.newRouteName,
    this.initialSorting,
  });

  @override
  ConsumerState<CollaborationListPageRiverpod> createState() =>
      _CollaborationListPageRiverpodState();
}

class _CollaborationListPageRiverpodState
    extends ConsumerState<CollaborationListPageRiverpod> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    // Set sorting configuration once when widget is created
    if (widget.initialSorting != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final service = ref.read(collaborationServiceProvider);
        service.setSortingConfig(
          widget.initialSorting!.field,
          widget.initialSorting!.sortAscending,
        );
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _showReferrerLinkDialog(
    BuildContext context,
    WidgetRef ref,
    ModelCampaign campaign,
    {String? existingLink}) async {
    dynamic parentBrand;
    try {
      parentBrand = await ref.read(
        collaborationParentBrandProvider(campaign.poId ?? '').future,
      );
    } catch (_) {
      parentBrand = null;
    }
    final appId = parentBrand?.androidAppId?.toString().trim();
    final resolvedAppId =
        (appId != null && appId.isNotEmpty)
        ? appId
        : 'com.numeroshastra.client';
    final campaignNameString =
        (campaign.campaignNameString ?? campaign.campaignName ?? campaign.poId ?? '')
            .trim();

    final sourceController = TextEditingController();
    final mediumController = TextEditingController();

    if (existingLink != null) {
      final existingUri = Uri.tryParse(existingLink);
      final existingReferrer = existingUri?.queryParameters['referrer'];
      if (existingReferrer != null && existingReferrer.isNotEmpty) {
        try {
          final parts = Uri.splitQueryString(existingReferrer);
          sourceController.text = parts['utm_source'] ?? '';
          mediumController.text = parts['utm_medium'] ?? '';
        } catch (_) {}
      }
    }

    String buildPreviewUrl() {
      final source = sourceController.text.trim().isEmpty
          ? '<>'
          : sourceController.text.trim();
      final medium = mediumController.text.trim().isEmpty
          ? '<>'
          : mediumController.text.trim();
      final referrer = Uri.encodeComponent(
        'utm_source=$source&utm_campaign=$campaignNameString&utm_medium=$medium',
      );
      return 'https://play.google.com/store/apps/details?id=$resolvedAppId&referrer=$referrer';
    }

    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final previewUrl = buildPreviewUrl();

            return AlertDialog(
              title: Text(
                existingLink == null ? 'Add Referrer Link' : 'Edit Referrer Link',
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Generated link preview',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: 8),
                    SelectableText(
                      previewUrl,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontFamily: 'monospace',
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Campaign: $campaignNameString',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: sourceController,
                      autofocus: true,
                      decoration: const InputDecoration(
                        labelText: 'utm_source',
                        hintText: 'instagram',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (_) => setDialogState(() {}),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: mediumController,
                      decoration: const InputDecoration(
                        labelText: 'utm_medium',
                        hintText: 'bio',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (_) => setDialogState(() {}),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final source = sourceController.text.trim();
                    final medium = mediumController.text.trim();
                    if (source.isEmpty || medium.isEmpty) return;
                    Navigator.pop(dialogContext, previewUrl);
                  },
                  child: Text(existingLink == null ? 'Save' : 'Update'),
                ),
              ],
            );
          },
        );
      },
    );

    sourceController.dispose();
    mediumController.dispose();

    final link = result?.trim();
    if (link == null || link.isEmpty) return;

    final uri = Uri.tryParse(link);
    if (uri == null || !(uri.hasScheme && uri.host.isNotEmpty)) {
      SnackbarUtils.showError('Please enter a valid URL');
      return;
    }

    try {
      final service = ref.read(campaignServiceProvider);
      if (existingLink == null) {
        await service.addReferrerLink(
          campaignId: campaign.poId!,
          referrerLink: link,
        );
      } else {
        await service.updateReferrerLink(
          campaignId: campaign.poId!,
          oldReferrerLink: existingLink,
          newReferrerLink: link,
        );
      }
      ref.invalidate(campaignByIdProvider(campaign.poId!));
      ref.invalidate(campaignStreamByIdProvider(campaign.poId!));
      SnackbarUtils.showSuccess(
        existingLink == null
            ? 'Referrer link added successfully!'
            : 'Referrer link updated successfully!',
      );
    } catch (e) {
      SnackbarUtils.showError('Failed to save referrer link: $e');
    }
  }

  Future<void> _deleteReferrerLink(
    BuildContext context,
    WidgetRef ref,
    ModelCampaign campaign,
    String existingLink,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Referrer Link'),
        content: const Text(
          'Are you sure you want to delete this referrer link?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await ref.read(campaignServiceProvider).deleteReferrerLink(
            campaignId: campaign.poId!,
            referrerLink: existingLink,
          );
      ref.invalidate(campaignByIdProvider(campaign.poId!));
      ref.invalidate(campaignStreamByIdProvider(campaign.poId!));
      SnackbarUtils.showSuccess('Referrer link deleted successfully!');
    } catch (e) {
      SnackbarUtils.showError('Failed to delete referrer link: $e');
    }
  }

  Widget _buildCampaignHeader(ModelCampaign campaign) {
    return CampaignListTile(
      entity: campaign,
      adapter: ref.read(campaignAdapterProvider),
      onTap: null,
      collaborationTile: true,
    );
  }

  Widget _buildCollaborationBody(
    AsyncValue<CollaborationListState> asyncState,
    ModelCampaign campaign,
  ) {
    return Column(
      children: [
        Expanded(
          child: CustomScrollView(
            controller: _scrollController,
            slivers: [
              SliverToBoxAdapter(child: _buildCampaignHeader(campaign)),
              const SliverToBoxAdapter(child: Divider()),
              asyncState.when(
                loading: () => const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (error, stackTrace) => SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Error: $error'),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            ref.invalidate(
                              collaborationListControllerProvider(widget.poId),
                            );
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ),
                data: (state) {
                  if (state.items.isEmpty) {
                    return SliverFillRemaining(
                      child: Center(
                        child: Text('No items found. Add one below.'),
                      ),
                    );
                  }
                  return SliverPadding(
                    padding: const EdgeInsets.only(bottom: 20),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final item = state.items[index];
                        return CartItemCard(
                          key: ValueKey(item.collaborationId),
                          entity: item,
                          influencers: state.influencers,
                          isReadOnly: false,
                          lastModifiedId: state.lastModifiedItemId,
                          poId: widget.poId,
                        );
                      }, childCount: state.items.length),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        if (asyncState.value?.isNewItemAdded != true)
          CollaborationAddCard(
            influencers: asyncState.value?.influencers ?? [],
            poId: widget.poId,
          ),
      ],
    );
  }

  Widget _buildReferrerLinksBody(ModelCampaign campaign) {
    final referrerLinks = campaign.referrerLinks;

    return Column(
      children: [
        Expanded(
          child: CustomScrollView(
            controller: _scrollController,
            slivers: [
              SliverToBoxAdapter(child: _buildCampaignHeader(campaign)),
              const SliverToBoxAdapter(child: Divider()),
              if (referrerLinks.isEmpty)
                const SliverFillRemaining(
                  child: Center(
                    child: Text('No referrer links yet. Add one below.'),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.only(bottom: 20),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final link = referrerLinks[index];
                      return ReferrerLinkTile(
                        link: link,
                        index: index,
                        onEdit: (existingLink) => _showReferrerLinkDialog(
                          context,
                          ref,
                          campaign,
                          existingLink: existingLink,
                        ),
                        onDelete: (existingLink) => _deleteReferrerLink(
                          context,
                          ref,
                          campaign,
                          existingLink,
                        ),
                      );
                    }, childCount: referrerLinks.length),
                  ),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _showReferrerLinkDialog(context, ref, campaign),
              icon: const Icon(Icons.link),
              label: const Text('Add Referrer Link'),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final campaignAsync = widget.poId.isNotEmpty
        ? ref.watch(campaignStreamByIdProvider(widget.poId))
        : null;
    final pageTitle = campaignAsync?.maybeWhen(
          loading: () => 'Loading Campaign...',
          error: (_, __) => 'Campaign Details',
          data: (campaign) {
            if (campaign == null) return 'Campaign Details';
            return campaign.effectiveCampaignType.isInfluencerCollaboration
                ? '${widget.entityLabel}s for PO'
                : 'Referrer Links';
          },
          orElse: () => 'Campaign Details',
        ) ??
        'All Collaborations';

    return Scaffold(
      appBar: CustomAppBar(
        title: pageTitle,
        showBack: widget.poId.isNotEmpty,
      ),
      drawer: const CustomDrawer(),
      body: campaignAsync == null
          ? const Center(child: Text('No campaign selected'))
          : campaignAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Error loading campaign: $error'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => ref.invalidate(
                        campaignStreamByIdProvider(widget.poId),
                      ),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
              data: (campaign) {
                if (campaign == null) {
                  return const Center(child: Text('Campaign not found'));
                }

                final isCollaborationCampaign =
                    campaign.effectiveCampaignType.isInfluencerCollaboration;

                if (isCollaborationCampaign) {
                  final asyncState = ref.watch(
                    collaborationListControllerProvider(widget.poId),
                  );
                  return _buildCollaborationBody(asyncState, campaign);
                }

                return _buildReferrerLinksBody(campaign);
              },
            ),
    );
  }
}

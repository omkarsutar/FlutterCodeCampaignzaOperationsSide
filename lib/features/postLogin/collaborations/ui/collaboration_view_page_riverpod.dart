import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../../core/providers/core_providers.dart';
import '../../../../shared/widgets/custom_app_bar.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../model/collaboration_model.dart';
import '../providers/collaboration_providers.dart';
import '../../referrer_links/providers/referrer_link_providers.dart';
import '../../referrer_links/model/referrer_link_model.dart';
import 'referrer_link_form_page.dart';

class CollaborationViewPageRiverpod extends ConsumerWidget {
  final String entityId;

  const CollaborationViewPageRiverpod({super.key, required this.entityId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final collaborationAsync = ref.watch(collaborationByIdProvider(entityId));
    final isInitialized = ref.watch(rbacInitializationProvider);
    final rbacService = ref.watch(rbacServiceProvider);

    const rbacModule = 'collaborations';
    final canUpdate = isInitialized && rbacService.canUpdate(rbacModule);
    final canDelete = isInitialized && rbacService.canDelete(rbacModule);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: CustomAppBar(
        title: 'Collaboration Details',
        showBack: context.canPop(),
        actions: [
          if (canUpdate)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                context.pushNamed(
                  'editCollaboration',
                  pathParameters: {'id': entityId},
                );
              },
            ),
          if (canDelete)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _showDeleteDialog(context, ref),
            ),
        ],
      ),
      body: collaborationAsync.when(
        data: (collaboration) {
          if (collaboration == null) {
            return const Center(child: Text('Collaboration not found'));
          }

          final influencerName =
              collaboration.resolvedLabels['influencer_id_label'] ??
              'Unknown Influencer';
          final category =
              collaboration.resolvedLabels['influencer_category_label'] ??
              'General';
          final influencerImage =
              collaboration.resolvedLabels['influencer_image_label'] as String?;
          final baseCommissionRate =
              collaboration.resolvedLabels['base_commission_rate_label'];

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header card with Image
                _buildProfileHeader(context, theme, influencerImage),

                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Influencer details section
                      Text(
                        influencerName,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        category,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 16),

                      // Status Section
                      _buildStatusCard(
                        theme,
                        collaboration.isAcceptedByInfluencer,
                      ),
                      const SizedBox(height: 24),

                      // Promo Code & Link Section with counts
                      _buildPromoCodeSection(
                        context,
                        theme,
                        collaboration,
                        ref,
                      ),
                      const SizedBox(height: 24),

                      // Commission Config Detail Box
                      _buildCommissionTypeDetails(
                        theme,
                        collaboration,
                        baseCommissionRate,
                      ),
                      const SizedBox(height: 24),

                      // System info
                      _buildInfoRow(
                        theme,
                        'Agreed Commission Amount',
                        '₹${collaboration.agreedCommissionAmount?.toStringAsFixed(2) ?? '0.00'}',
                        valueColor: theme.colorScheme.primary,
                        isBold: true,
                      ),
                      if (collaboration.createdAt != null)
                        _buildInfoRow(
                          theme,
                          'Created At',
                          collaboration.createdAt!.toLocal().toString().split(
                            '.',
                          )[0],
                        ),
                      if (collaboration.updatedAt != null)
                        _buildInfoRow(
                          theme,
                          'Last Updated At',
                          collaboration.updatedAt!.toLocal().toString().split(
                            '.',
                          )[0],
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: theme.colorScheme.error,
              ),
              const SizedBox(height: 16),
              const Text(
                'Error loading collaboration',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(err.toString(), textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () =>
                    ref.invalidate(collaborationByIdProvider(entityId)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(
    BuildContext context,
    ThemeData theme,
    String? imageUrl,
  ) {
    String? cleanUrl;
    if (imageUrl != null && imageUrl.isNotEmpty) {
      cleanUrl = Uri.encodeFull(Uri.decodeFull(imageUrl));
    }

    return Container(
      width: double.infinity,
      height: 250,
      color: Colors.grey[200],
      child: cleanUrl != null
          ? CachedNetworkImage(
              imageUrl: cleanUrl,
              fit: BoxFit.cover,
              placeholder: (context, url) =>
                  const Center(child: CircularProgressIndicator()),
              errorWidget: (context, url, error) => _buildDefaultAvatar(theme),
            )
          : _buildDefaultAvatar(theme),
    );
  }

  Widget _buildDefaultAvatar(ThemeData theme) {
    return Center(
      child: Icon(
        Icons.person,
        size: 80,
        color: theme.colorScheme.onSurfaceVariant.withAlpha(127),
      ),
    );
  }

  Widget _buildStatusCard(ThemeData theme, bool isAccepted) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isAccepted
            ? Colors.green.withValues(alpha: 0.1)
            : Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isAccepted ? Colors.green : Colors.orange,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isAccepted ? Icons.check_circle_rounded : Icons.pending_rounded,
            color: isAccepted ? Colors.green : Colors.orange,
            size: 24,
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Acceptance Status',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isAccepted ? Colors.green[800] : Colors.orange[800],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                isAccepted ? 'Accepted by Influencer' : 'Pending Acceptance',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isAccepted ? Colors.green[900] : Colors.orange[900],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCommissionTypeDetails(
    ThemeData theme,
    ModelCollaboration collaboration,
    dynamic baseCommissionRate,
  ) {
    final type = collaboration.commissionType ?? CommissionType.percentage;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Commission Configuration',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _buildInfoRow(theme, 'Type', type.displayName, isBold: true),
          if (type == CommissionType.percentage) ...[
            _buildInfoRow(
              theme,
              'Commission Rate',
              '${collaboration.commissionRate ?? 0.0}%',
            ),
            if (baseCommissionRate != null)
              _buildInfoRow(
                theme,
                'Base Commission Rate',
                '$baseCommissionRate%',
              ),
          ] else if (type == CommissionType.fixedAmount) ...[
            _buildInfoRow(
              theme,
              'Fixed Amount',
              '₹${collaboration.fixedAmount?.toStringAsFixed(2) ?? '0.00'}',
            ),
          ] else if (type == CommissionType.barter) ...[
            const SizedBox(height: 8),
            Text(
              'Barter Description',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              collaboration.barterDescription ?? 'No details provided.',
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    ThemeData theme,
    String label,
    String value, {
    Color? valueColor,
    bool isBold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 180,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
                color: valueColor ?? Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPromoCodeSection(
    BuildContext context,
    ThemeData theme,
    ModelCollaboration collaboration,
    WidgetRef ref,
  ) {
    final promoCode = collaboration.promoCode;
    final linksAsync = ref.watch(referrerLinksForCollaborationProvider(collaboration.collaborationId ?? ''));

    // Watch parent campaign and brand data
    final parentCampaignAsync = ref.watch(
      collaborationParentCampaignProvider(collaboration.collaborationId ?? ''),
    );
    final parentBrandAsync = ref.watch(
      collaborationParentBrandProvider(collaboration.collaborationId ?? ''),
    );

    // Watch analytics counts
    final purchaseCountAsync = (promoCode != null && promoCode.isNotEmpty)
        ? ref.watch(purchaseCountProvider(promoCode))
        : const AsyncValue<int>.data(0);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header with refresh button
          Row(
            children: [
              Expanded(
                child: Text(
                  'Promo Code & Referrer Links',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              Tooltip(
                message: 'Refresh links and counts',
                child: IconButton(
                  icon: Icon(
                    Icons.refresh,
                    color: theme.colorScheme.primary,
                    size: 22,
                  ),
                  onPressed: () {
                    if (promoCode != null && promoCode.isNotEmpty) {
                      ref.invalidate(purchaseCountProvider(promoCode));
                    }
                    ref.invalidate(referrerLinksForCollaborationProvider(collaboration.collaborationId ?? ''));
                    SnackbarUtils.showSuccess('Refreshing data...');
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (promoCode != null && promoCode.isNotEmpty) ...[
            _buildCopyableTile(
              context,
              theme,
              title: 'Promo Code',
              text: promoCode,
              snackbarLabel: 'Promo Code',
              countLabel: 'Purchase Count',
              countAsync: purchaseCountAsync,
              icon: Icons.local_offer_outlined,
              color: Colors.deepPurple,
            ),
            const SizedBox(height: 16),
          ],

          Text(
            'Referrer Links',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),

          linksAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Text('Error loading links: $err'),
            data: (links) {
              if (links.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    'No referrer links added yet.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                );
              }
              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: links.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final linkItem = links[index];
                  final installCountAsync = ref.watch(
                    installCountProvider(linkItem.referrerLinkString),
                  );

                  return _buildDynamicLinkTile(
                    context,
                    theme,
                    ref,
                    linkItem,
                    installCountAsync,
                  );
                },
              );
            },
          ),

          const SizedBox(height: 16),
          parentCampaignAsync.when(
            data: (campaign) => parentBrandAsync.when(
              data: (brand) {
                if (campaign == null) return const SizedBox.shrink();
                return SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _addReferrerLinkForCollaboration(
                      context,
                      ref,
                      campaign,
                      brand,
                      collaboration,
                    ),
                    icon: const Icon(Icons.add_link),
                    label: const Text('Add Referrer Link'),
                  ),
                );
              },
              error: (_, __) => const SizedBox.shrink(),
              loading: () => const SizedBox.shrink(),
            ),
            error: (_, __) => const SizedBox.shrink(),
            loading: () => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildDynamicLinkTile(
    BuildContext context,
    ThemeData theme,
    WidgetRef ref,
    ModelReferrerLink linkItem,
    AsyncValue<int> countAsync,
  ) {
    final String source = linkItem.referrerLinkSource;
    final Color color = _getSourceColor(source);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.8),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: _getSourceIcon(source, color),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${source.toUpperCase()} (${linkItem.referrerLinkType})',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    _buildInlineCount(theme, 'Installs', countAsync, color),
                  ],
                ),
                const SizedBox(height: 6),
                SelectableText(
                  linkItem.referrerLinkString,
                  maxLines: 2,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontFamily: 'monospace',
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            tooltip: 'Copy Link',
            icon: const Icon(Icons.copy, size: 18),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: linkItem.referrerLinkString));
              SnackbarUtils.showSuccess('Link copied to clipboard!');
            },
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 4),
          IconButton(
            tooltip: 'Delete Link',
            icon: const Icon(Icons.delete_outline, size: 18),
            onPressed: () => _deleteReferrerLinkForCollaboration(
              context,
              ref,
              linkItem,
            ),
            color: theme.colorScheme.error,
          ),
        ],
      ),
    );
  }

  Color _getSourceColor(String source) {
    switch (source.toLowerCase()) {
      case 'instagram':
        return Colors.pink;
      case 'facebook':
        return Colors.blue;
      case 'youtube':
        return Colors.red;
      case 'tiktok':
        return Colors.black;
      case 'twitter':
        return Colors.lightBlue;
      default:
        return Colors.teal;
    }
  }

  Widget _getSourceIcon(String source, Color color) {
    return Icon(Icons.link, color: color, size: 20);
  }

  Future<void> _addReferrerLinkForCollaboration(
    BuildContext context,
    WidgetRef ref,
    dynamic campaign,
    dynamic brand,
    ModelCollaboration collaboration,
  ) async {
    final appId = brand.androidAppId?.toString().trim();
    final resolvedAppId =
        (appId != null && appId.isNotEmpty)
        ? appId
        : 'com.numeroshastra.client';
    final campaignNameString =
        (campaign.campaignNameString ?? campaign.campaignName ?? campaign.poId ?? '')
            .trim();

    final link = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => ReferrerLinkFormPage(
          appId: resolvedAppId,
          campaignNameString: campaignNameString,
        ),
      ),
    );

    if (link == null || link.isEmpty) return;

    final uri = Uri.tryParse(link);
    if (uri == null || !(uri.hasScheme && uri.host.isNotEmpty)) {
      SnackbarUtils.showError('Please enter a valid URL');
      return;
    }

    try {
      final service = ref.read(referrerLinkServiceProvider);
      final source = uri.queryParameters['utm_source'] ?? 'direct';

      await service.create(ModelReferrerLink(
        referrerLinkString: link,
        referrerLinkType: 'plain',
        campaignId: campaign.campaignId,
        campaignType: campaign.campaignType?.toDbValue() ?? 'influencer_collaborations',
        collaborationId: collaboration.collaborationId,
        referrerLinkSource: source,
      ));

      ref.invalidate(referrerLinksForCollaborationProvider(collaboration.collaborationId ?? ''));
      SnackbarUtils.showSuccess('Referrer link added successfully!');
    } catch (e) {
      SnackbarUtils.showError('Failed to save referrer link: $e');
    }
  }

  Future<void> _deleteReferrerLinkForCollaboration(
    BuildContext context,
    WidgetRef ref,
    ModelReferrerLink linkItem,
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
      final service = ref.read(referrerLinkServiceProvider);
      await service.deleteEntityById(linkItem.referrerLinkId!);

      ref.invalidate(referrerLinksForCollaborationProvider(linkItem.collaborationId ?? ''));
      SnackbarUtils.showSuccess('Referrer link deleted successfully!');
    } catch (e) {
      SnackbarUtils.showError('Failed to delete referrer link: $e');
    }
  }

  Widget _buildCopyableTile(
    BuildContext context,
    ThemeData theme, {
    required String title,
    required String text,
    required String snackbarLabel,
    required String countLabel,
    required AsyncValue<int> countAsync,
    required Color color,
    IconData? icon,
    Widget? logoWidget,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.8),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: logoWidget ?? Icon(icon, color: color, size: 22),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    _buildInlineCount(theme, countLabel, countAsync, color),
                  ],
                ),
                const SizedBox(height: 6),
                SelectableText(
                  text,
                  maxLines: 2,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontFamily: 'monospace',
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            tooltip: 'Copy $title',
            icon: const Icon(Icons.copy, size: 20),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: text));
              SnackbarUtils.showSuccess('$snackbarLabel copied to clipboard!');
            },
            color: theme.colorScheme.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildInlineCount(
    ThemeData theme,
    String label,
    AsyncValue<int> countAsync,
    Color color,
  ) {
    return countAsync.when(
      data: (count) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          '$label: $count',
          style: theme.textTheme.labelSmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      loading: () => const SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
      error: (err, _) => Text(
        '$label: Error',
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.error,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Future<void> _showDeleteDialog(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Collaboration'),
        content: const Text(
          'Are you sure you want to delete this collaboration? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final success = await ref
            .read(collaborationFormProvider.notifier)
            .deleteEntity(entityId);
        if (context.mounted) {
          if (success) {
            SnackbarUtils.showSuccess('Collaboration deleted successfully!');
            context.pop();
          } else {
            SnackbarUtils.showError('Failed to delete collaboration.');
          }
        }
      } catch (e) {
        if (context.mounted) {
          SnackbarUtils.showError('Error deleting: $e');
        }
      }
    }
  }
}

import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_supabase_order_app_mobile/core/utils/file_save_helper.dart';

import '../../../../core/providers/core_providers.dart';
import '../../../../shared/widgets/custom_app_bar.dart';
import '../../../../core/utils/dialogs.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../model/collaboration_model.dart';
import '../providers/collaboration_providers.dart';
import '../../referrer_links/providers/referrer_link_providers.dart';
import '../../referrer_links/model/referrer_link_model.dart';
import '../../campaigns/ui/widgets/referrer_link_tile.dart';
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

    // Influencer role has scoped actions on this page (accept collab, set
    // promo code, view referrer links) regardless of the generic RBAC flags.
    final role = ref.watch(roleNameProvider);
    final isInfluencer = role != null && role.toLowerCase() == 'influencer';

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: CustomAppBar(
        title: 'Collaboration Details',
        showBack: context.canPop(),
        actions: [
          // Influencer never gets the full edit affordance; their edits are
          // scoped to dedicated controls on the page itself.
          if (canUpdate && !isInfluencer)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                context.pushNamed(
                  'editCollaboration',
                  pathParameters: {'id': entityId},
                );
              },
            ),
          if (canDelete && !isInfluencer)
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
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Influencer details section: avatar on the left with
                      // name and platform stacked on the right.
                      _buildProfileHeaderRow(
                        context,
                        theme,
                        influencerName,
                        category,
                        influencerImage,
                      ),
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 16),

                      // Status Section
                      _buildStatusCard(
                        theme,
                        collaboration,
                        ref,
                        isInfluencer: isInfluencer,
                      ),
                      const SizedBox(height: 24),

                      // Promo Code section
                      _buildPromoCodeSection(
                        context,
                        theme,
                        collaboration,
                        ref,
                        isInfluencer: isInfluencer,
                      ),
                      const SizedBox(height: 24),

                      // Referrer Links section
                      _buildReferrerLinksSection(
                        context,
                        theme,
                        collaboration,
                        ref,
                        isInfluencer: isInfluencer,
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

  Widget _buildProfileHeaderRow(
    BuildContext context,
    ThemeData theme,
    String name,
    String platform,
    String? imageUrl,
  ) {
    String? cleanUrl;
    if (imageUrl != null && imageUrl.isNotEmpty) {
      cleanUrl = Uri.encodeFull(Uri.decodeFull(imageUrl));
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Avatar / influencer image on the left
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: 72,
            height: 72,
            color: theme.colorScheme.surfaceContainerHighest.withValues(
              alpha: 0.4,
            ),
            child: cleanUrl != null
                ? CachedNetworkImage(
                    imageUrl: cleanUrl,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => const Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                    errorWidget: (context, url, error) =>
                        _buildDefaultAvatarIcon(theme),
                  )
                : _buildDefaultAvatarIcon(theme),
          ),
        ),
        const SizedBox(width: 16),
        // Name and platform stacked on the right
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                name,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.public,
                    size: 16,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      platform,
                      style: theme.textTheme.titleMedium?.copyWith(
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
    );
  }

  Widget _buildDefaultAvatarIcon(ThemeData theme) {
    return Center(
      child: Icon(
        Icons.person,
        size: 36,
        color: theme.colorScheme.onSurfaceVariant.withAlpha(127),
      ),
    );
  }

  Widget _buildStatusCard(
    ThemeData theme,
    ModelCollaboration collaboration,
    WidgetRef ref, {
    bool isInfluencer = false,
  }) {
    final isAccepted = collaboration.isAcceptedByInfluencer;
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isAccepted ? Icons.check_circle_rounded : Icons.pending_rounded,
                color: isAccepted ? Colors.green : Colors.orange,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Acceptance Status',
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isAccepted
                            ? Colors.green[800]
                            : Colors.orange[800],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isAccepted
                          ? 'Accepted by Influencer'
                          : 'Pending Acceptance',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: isAccepted
                            ? Colors.green[900]
                            : Colors.orange[900],
                      ),
                    ),
                  ],
                ),
              ),
              // Influencer can accept the collaboration but, once accepted,
              // cannot toggle it back off.
              if (isInfluencer && !isAccepted)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: FilledButton.icon(
                    onPressed: () => _acceptCollaboration(ref, collaboration),
                    icon: const Icon(Icons.check_rounded),
                    label: const Text('Accept'),
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
    WidgetRef ref, {
    bool isInfluencer = false,
  }) {
    final promoCode = collaboration.promoCode;
    final hasPromoCode = promoCode != null && promoCode.isNotEmpty;

    // Watch analytics counts
    final purchaseCountAsync = hasPromoCode
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
          Row(
            children: [
              Expanded(
                child: Text(
                  'Promo Code',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              Tooltip(
                message: 'Refresh purchase count',
                child: IconButton(
                  icon: Icon(
                    Icons.refresh,
                    color: theme.colorScheme.primary,
                    size: 22,
                  ),
                  onPressed: () {
                    if (hasPromoCode) {
                      ref.invalidate(purchaseCountProvider(promoCode));
                    }
                    SnackbarUtils.showSuccess('Refreshing purchase count...');
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (hasPromoCode)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer.withValues(
                      alpha: 0.7,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.local_offer_outlined,
                    color: theme.colorScheme.onPrimaryContainer,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SelectableText(
                        promoCode,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                purchaseCountAsync.when(
                  data: (count) => _buildCountPill(
                    theme,
                    'Purchases: $count',
                    theme.colorScheme.secondary,
                  ),
                  loading: () => const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  error: (_, __) => _buildCountPill(
                    theme,
                    'Purchases: Error',
                    theme.colorScheme.error,
                  ),
                ),
              ],
            )
          else ...[
            Row(
              children: [
                Icon(
                  Icons.local_offer_outlined,
                  size: 20,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'No promo code set yet.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
            // Influencer can create a promo code when one does not exist.
            if (isInfluencer) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.tonalIcon(
                  onPressed: () => _setPromoCodeForCollaboration(
                    context,
                    ref,
                    collaboration,
                  ),
                  icon: const Icon(Icons.add),
                  label: const Text('Set Promo Code'),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildReferrerLinksSection(
    BuildContext context,
    ThemeData theme,
    ModelCollaboration collaboration,
    WidgetRef ref, {
    bool isInfluencer = false,
  }) {
    final linksAsync = ref.watch(
      referrerLinksForCollaborationProvider(
        collaboration.collaborationId ?? '',
      ),
    );

    // Influencers can only view referrer links and only after they have
    // accepted the collaboration. Everyone else sees the full management UI.
    final isAccepted = collaboration.isAcceptedByInfluencer;
    final showLinks = !isInfluencer || isAccepted;
    final canManageLinks = !isInfluencer;

    if (!showLinks) {
      return SizedBox(
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Referrer Links',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                'Accept the collaboration to view your referrer links.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Referrer Links',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              Tooltip(
                message: 'Refresh links',
                child: IconButton(
                  icon: Icon(
                    Icons.refresh,
                    color: theme.colorScheme.primary,
                    size: 22,
                  ),
                  onPressed: () {
                    ref.invalidate(
                      referrerLinksForCollaborationProvider(
                        collaboration.collaborationId ?? '',
                      ),
                    );
                    SnackbarUtils.showSuccess('Refreshing links...');
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
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
                  return ReferrerLinkTile(
                    link: linkItem.referrerLinkString,
                    title: _buildReferrerLinkTitle(linkItem),
                    campaignPlatform:
                        collaboration.resolvedLabels['campaign_platform']
                            ?.toString() ??
                        null,
                    referrerLinkSource: linkItem.referrerLinkSource,
                    margin: EdgeInsets.zero,
                    belowLinkWidget: _buildReferrerLinkQrWidget(linkItem),
                    onEdit: canManageLinks
                        ? (_) => _addReferrerLinkForCollaboration(
                            context,
                            ref,
                            collaboration,
                            existingLinkItem: linkItem,
                          )
                        : null,
                    onDelete: canManageLinks
                        ? (_) => _deleteReferrerLinkForCollaboration(
                            context,
                            ref,
                            linkItem,
                          )
                        : null,
                  );
                },
              );
            },
          ),
          if (canManageLinks) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _addReferrerLinkForCollaboration(
                  context,
                  ref,
                  collaboration,
                ),
                icon: const Icon(Icons.add_link),
                label: const Text('Add Referrer Link'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _addReferrerLinkForCollaboration(
    BuildContext context,
    WidgetRef ref,
    ModelCollaboration collaboration, {
    ModelReferrerLink? existingLinkItem,
  }) async {
    final campaign = await ref.read(
      collaborationParentCampaignProvider(
        collaboration.collaborationId ?? '',
      ).future,
    );
    final brand = await ref.read(
      collaborationParentBrandProvider(
        collaboration.collaborationId ?? '',
      ).future,
    );

    if (campaign == null || brand == null) {
      SnackbarUtils.showError('Unable to load campaign brand details');
      return;
    }

    if (!context.mounted) return;

    final appId = brand.androidAppId?.toString().trim();
    final resolvedAppId = (appId != null && appId.isNotEmpty)
        ? appId
        : 'com.numeroshastra.client';
    final campaignNameString =
        (campaign.campaignNameString ??
                campaign.campaignName ??
                campaign.poId ??
                '')
            .trim();

    final result = await Navigator.of(context).push<ReferrerLinkFormResult>(
      MaterialPageRoute(
        builder: (_) => ReferrerLinkFormPage(
          appId: resolvedAppId,
          campaignNameString: campaignNameString,
          campaignPlatform: campaign.campaignPlatform,
          websiteUrl: brand.websiteUrl,
          promoCode: collaboration.promoCode,
          existingLink: existingLinkItem?.referrerLinkString,
          initialReferrerLinkType: existingLinkItem?.referrerLinkType,
          initialReferrerLinkSource: existingLinkItem?.referrerLinkSource,
        ),
      ),
    );

    if (result == null || result.link.isEmpty) return;

    final uri = Uri.tryParse(result.link);
    if (uri == null || !(uri.hasScheme && uri.host.isNotEmpty)) {
      SnackbarUtils.showError('Please enter a valid URL');
      return;
    }

    try {
      final service = ref.read(referrerLinkServiceProvider);
      final entity = ModelReferrerLink(
        referrerLinkString: result.link,
        referrerLinkType: result.referrerLinkType,
        campaignId: campaign.campaignId,
        campaignType:
            campaign.campaignType?.toDbValue() ?? 'influencer_collaborations',
        collaborationId: collaboration.collaborationId,
        referrerLinkSource: result.referrerLinkSource,
      );

      if (existingLinkItem == null) {
        await service.create(entity);
      } else {
        await service.update(existingLinkItem.referrerLinkId!, entity);
      }

      ref.invalidate(
        referrerLinksForCollaborationProvider(
          collaboration.collaborationId ?? '',
        ),
      );
      SnackbarUtils.showSuccess(
        existingLinkItem == null
            ? 'Referrer link added successfully!'
            : 'Referrer link updated successfully!',
      );
    } catch (e) {
      SnackbarUtils.showError('Failed to save referrer link: $e');
    }
  }

  Future<void> _deleteReferrerLinkForCollaboration(
    BuildContext context,
    WidgetRef ref,
    ModelReferrerLink linkItem,
  ) async {
    final confirmed = await showConfirmDeleteWithTextDialog(
      context: context,
      title: 'Delete Referrer Link',
      content: 'Are you sure you want to delete this referrer link?',
      entityNameLower: 'referrer link',
    );

    if (!confirmed) return;

    try {
      final service = ref.read(referrerLinkServiceProvider);
      await service.deleteEntityById(linkItem.referrerLinkId!);

      ref.invalidate(
        referrerLinksForCollaborationProvider(linkItem.collaborationId ?? ''),
      );
      SnackbarUtils.showSuccess('Referrer link deleted successfully!');
    } catch (e) {
      SnackbarUtils.showError('Failed to delete referrer link: $e');
    }
  }

  /// Applies a partial update to the collaboration by writing only the
  /// supplied fields. Used by the influencer-scoped actions on this page
  /// (accept collaboration, set promo code) since the influencer role does
  /// not have the generic `update` RBAC permission.
  Future<void> _patchCollaboration(
    WidgetRef ref,
    ModelCollaboration collaboration,
    Map<String, dynamic> changes,
  ) async {
    final id = collaboration.collaborationId;
    if (id == null || id.isEmpty) {
      SnackbarUtils.showError('Collaboration id is missing');
      return;
    }
    if (changes.isEmpty) return;
    try {
      final service = ref.read(collaborationServiceProvider);
      await service.update(
        id,
        collaboration.copyWith(
          isAcceptedByInfluencer:
              changes.containsKey(
                ModelCollaborationFields.isAcceptedByInfluencer,
              )
              ? changes[ModelCollaborationFields.isAcceptedByInfluencer] == true
              : collaboration.isAcceptedByInfluencer,
          promoCode: changes.containsKey(ModelCollaborationFields.promoCode)
              ? changes[ModelCollaborationFields.promoCode]?.toString()
              : collaboration.promoCode,
        ),
      );
      ref.invalidate(collaborationByIdProvider(id));
    } catch (e) {
      SnackbarUtils.showError('Failed to update collaboration: $e');
    }
  }

  /// Influencer-only action: accept (set is_accepted_by_influencer = true).
  /// Acceptance is one-way; there is no UI to revoke it.
  Future<void> _acceptCollaboration(
    WidgetRef ref,
    ModelCollaboration collaboration,
  ) async {
    final id = collaboration.collaborationId;
    if (id == null) return;
    await _patchCollaboration(ref, collaboration, {
      ModelCollaborationFields.isAcceptedByInfluencer: true,
    });
    SnackbarUtils.showSuccess('Collaboration accepted!');
  }

  /// Influencer-only action: set a promo code when one does not exist yet.
  Future<void> _setPromoCodeForCollaboration(
    BuildContext context,
    WidgetRef ref,
    ModelCollaboration collaboration,
  ) async {
    final id = collaboration.collaborationId;
    if (id == null) return;

    final existing = collaboration.promoCode;
    if (existing != null && existing.isNotEmpty) {
      SnackbarUtils.showInfo(
        'A promo code is already set for this collaboration.',
      );
      return;
    }

    final code = await _showPromoCodeDialog(context);
    if (code == null || code.isEmpty) return;

    await _patchCollaboration(ref, collaboration, {
      ModelCollaborationFields.promoCode: code,
    });
    SnackbarUtils.showSuccess('Promo code set successfully!');
  }

  Future<String?> _showPromoCodeDialog(BuildContext context) async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Set Promo Code'),
        content: TextField(
          controller: controller,
          autofocus: true,
          autocorrect: false,
          enableSuggestions: false,
          textCapitalization: TextCapitalization.characters,
          decoration: const InputDecoration(
            labelText: 'Promo Code',
            hintText: 'e.g. SUMMER20',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.local_offer_outlined),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(null),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final value = controller.text.trim();
              Navigator.of(dialogContext).pop(value.isEmpty ? null : value);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Widget _buildCountPill(ThemeData theme, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  String _buildReferrerLinkTitle(ModelReferrerLink linkItem) {
    final source = linkItem.referrerLinkSource.trim();
    if (source.isEmpty) return 'Bio Link';
    return '${_capitalize(source)} Bio Link';
  }

  Widget _buildReferrerLinkLeadingWidget(
    ThemeData theme,
    ModelReferrerLink linkItem,
  ) {
    final assetPath = _referrerLinkAssetFor(linkItem);

    return Padding(
      padding: const EdgeInsets.all(6),
      child: SizedBox(
        width: 18,
        height: 18,
        child: Image.asset(
          assetPath,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => Icon(
            Icons.link_rounded,
            size: 18,
            color: theme.colorScheme.onPrimaryContainer,
          ),
        ),
      ),
    );
  }

  Widget? _buildReferrerLinkQrWidget(ModelReferrerLink linkItem) {
    final typeLower = linkItem.referrerLinkType.trim().toLowerCase();
    final isQrType =
        typeLower == 'qrcode' ||
        typeLower == 'branded qrcode' ||
        typeLower == 'branded_qrcode' ||
        typeLower == 'branded-qrcode';
    if (!isQrType) return null;

    final rawLink = linkItem.referrerLinkString.trim();
    if (rawLink.isEmpty) return null;

    // Sanitize QR payload: remove empty fragment / trailing '#' so QR content
    // matches the open/copy behavior used elsewhere in the app.
    String qrData = rawLink;
    try {
      final uri = Uri.tryParse(rawLink);
      if (uri != null) {
        qrData = uri.replace(fragment: null).toString();
        if (qrData.endsWith('#')) {
          qrData = qrData.substring(0, qrData.length - 1);
        }
      }
    } catch (_) {}

    final isBranded = typeLower.contains('branded');
    // For branded QR overlay use the source logo (not the generic qr icon)
    String logoAsset = 'assets/images/google_logo.webp';
    final source = linkItem.referrerLinkSource.trim().toLowerCase();
    switch (source) {
      case 'facebook':
        logoAsset = 'assets/images/facebook_logo.webp';
        break;
      case 'instagram':
        logoAsset = 'assets/images/instagram_logo.webp';
        break;
      case 'whatsapp':
        logoAsset = 'assets/images/whatsapp_logo.webp';
        break;
      case 'youtube':
        logoAsset = 'assets/images/youtube_logo.webp';
        break;
      case 'google':
      case 'direct':
      case 'tiktok':
      case 'twitter':
      case 'linkedin':
        logoAsset = 'assets/images/google_logo.webp';
        break;
      default:
        logoAsset = 'assets/images/google_logo.webp';
    }

    return _QrShareBlock(
      data: qrData,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black12),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            QrImageView(
              data: qrData,
              version: QrVersions.auto,
              size: 180,
              backgroundColor: Colors.white,
              gapless: false,
              errorCorrectionLevel: QrErrorCorrectLevel.M,
            ),
            if (isBranded)
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.all(6),
                child: Image.asset(logoAsset, fit: BoxFit.contain),
              ),
          ],
        ),
      ),
    );
  }

  String _referrerLinkAssetFor(ModelReferrerLink linkItem) {
    final type = linkItem.referrerLinkType.trim().toLowerCase();
    if (type == 'qrcode' ||
        type == 'branded qrcode' ||
        type == 'branded_qrcode' ||
        type == 'branded-qrcode') {
      return 'assets/images/qr_code.webp';
    }

    switch (linkItem.referrerLinkSource.trim().toLowerCase()) {
      case 'facebook':
        return 'assets/images/facebook_logo.webp';
      case 'instagram':
        return 'assets/images/instagram_logo.webp';
      case 'whatsapp':
        return 'assets/images/whatsapp_logo.webp';
      case 'youtube':
        return 'assets/images/youtube_logo.webp';
      case 'google':
      case 'direct':
      case 'tiktok':
      case 'twitter':
      case 'linkedin':
        return 'assets/images/google_logo.webp';
      default:
        return 'assets/images/google_logo.webp';
    }
  }

  String _capitalize(String value) {
    if (value.isEmpty) return value;
    if (value.length == 1) return value.toUpperCase();
    return value[0].toUpperCase() + value.substring(1);
  }

  Future<void> _showDeleteDialog(BuildContext context, WidgetRef ref) async {
    final confirmed = await showConfirmDeleteWithTextDialog(
      context: context,
      title: 'Delete Collaboration',
      content:
          'Are you sure you want to delete this collaboration? This action cannot be undone.',
      entityNameLower: 'collaboration',
    );

    if (confirmed) {
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

class _QrShareBlock extends StatefulWidget {
  final String data;
  final Widget child;

  const _QrShareBlock({required this.data, required this.child});

  @override
  State<_QrShareBlock> createState() => _QrShareBlockState();
}

class _QrShareBlockState extends State<_QrShareBlock> {
  final GlobalKey _boundaryKey = GlobalKey();

  String _getFileName() {
    try {
      final uri = Uri.tryParse(widget.data);
      if (uri != null) {
        final utmSource = uri.queryParameters['utm_source']?.trim();
        if (utmSource != null && utmSource.isNotEmpty) {
          final sanitized = utmSource.replaceAll(RegExp(r'[^\w\-_]'), '_');
          return '$sanitized.png';
        }
      }
    } catch (_) {}
    return 'referrer_qr.png';
  }

  Future<void> _handleQrAction() async {
    try {
      final boundary =
          _boundaryKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) return;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      final pngBytes = byteData.buffer.asUint8List();
      final fileName = _getFileName();

      if (kIsWeb) {
        await UniversalFileSaver.saveAndDownloadFile(
          bytes: pngBytes,
          fileName: fileName,
        );
        SnackbarUtils.showSuccess('QR Code downloaded successfully!');
        return;
      }

      await Share.shareXFiles([
        XFile.fromData(pngBytes, name: fileName, mimeType: 'image/png'),
      ], subject: 'Referrer QR Code');
    } catch (e) {
      if (mounted) {
        SnackbarUtils.showError('Could not process QR Code: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        RepaintBoundary(key: _boundaryKey, child: widget.child),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _handleQrAction,
          icon: Icon(kIsWeb ? Icons.download_outlined : Icons.share_outlined),
          label: Text(kIsWeb ? 'Download QR Code' : 'Share QR Code'),
        ),
      ],
    );
  }
}

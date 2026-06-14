import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/providers/core_providers.dart';
import '../../../../shared/widgets/custom_app_bar.dart';
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

                      // Promo Code section
                      _buildPromoCodeSection(
                        theme,
                        collaboration,
                        ref,
                      ),
                      const SizedBox(height: 24),

                      // Referrer Links section
                      _buildReferrerLinksSection(
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
    ThemeData theme,
    ModelCollaboration collaboration,
    WidgetRef ref,
  ) {
    final promoCode = collaboration.promoCode;

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
                    if (promoCode != null && promoCode.isNotEmpty) {
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
          if (promoCode != null && promoCode.isNotEmpty)
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
            ),
        ],
      ),
    );
  }

  Widget _buildReferrerLinksSection(
    BuildContext context,
    ThemeData theme,
    ModelCollaboration collaboration,
    WidgetRef ref,
  ) {
    final linksAsync = ref.watch(
      referrerLinksForCollaborationProvider(collaboration.collaborationId ?? ''),
    );

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
                    margin: EdgeInsets.zero,
                    leadingWidget: _buildReferrerLinkLeadingWidget(
                      theme,
                      linkItem,
                    ),
                    belowLinkWidget: _buildReferrerLinkQrWidget(linkItem),
                    onEdit: (_) => _addReferrerLinkForCollaboration(
                      context,
                      ref,
                      collaboration,
                      existingLinkItem: linkItem,
                    ),
                    onDelete: (_) => _deleteReferrerLinkForCollaboration(
                      context,
                      ref,
                      linkItem,
                    ),
                  );
                },
              );
            },
          ),
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
    final resolvedAppId =
        (appId != null && appId.isNotEmpty)
        ? appId
        : 'com.numeroshastra.client';
    final campaignNameString =
        (campaign.campaignNameString ?? campaign.campaignName ?? campaign.poId ?? '')
            .trim();

    final result = await Navigator.of(context).push<ReferrerLinkFormResult>(
      MaterialPageRoute(
        builder: (_) => ReferrerLinkFormPage(
          appId: resolvedAppId,
          campaignNameString: campaignNameString,
          promoCode: collaboration.promoCode,
          existingLink: existingLinkItem?.referrerLinkString,
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
            campaign.campaignType?.toDbValue() ??
            'influencer_collaborations',
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

  Widget _buildCountPill(
    ThemeData theme,
    String label,
    Color color,
  ) {
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
    if (linkItem.referrerLinkType.trim().toLowerCase() != 'qrcode') {
      return null;
    }

    final link = linkItem.referrerLinkString.trim();
    if (link.isEmpty) return null;

    return _QrShareBlock(
      data: link,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black12),
        ),
        child: QrImageView(
          data: link,
          version: QrVersions.auto,
          size: 180,
          backgroundColor: Colors.white,
          gapless: false,
          errorCorrectionLevel: QrErrorCorrectLevel.M,
        ),
      ),
    );
  }

  String _referrerLinkAssetFor(ModelReferrerLink linkItem) {
    final type = linkItem.referrerLinkType.trim().toLowerCase();
    if (type == 'qrcode') {
      return 'assets/images/qr_code.png';
    }

    switch (linkItem.referrerLinkSource.trim().toLowerCase()) {
      case 'facebook':
        return 'assets/images/facebook_logo.png';
      case 'instagram':
        return 'assets/images/instagram_logo.png';
      case 'youtube':
      case 'google':
      case 'direct':
      case 'tiktok':
      case 'twitter':
      case 'linkedin':
      case 'whatsapp':
        return 'assets/images/google_logo.png';
      default:
        return 'assets/images/google_logo.png';
    }
  }

  String _capitalize(String value) {
    if (value.isEmpty) return value;
    if (value.length == 1) return value.toUpperCase();
    return value[0].toUpperCase() + value.substring(1);
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

class _QrShareBlock extends StatefulWidget {
  final String data;
  final Widget child;

  const _QrShareBlock({
    required this.data,
    required this.child,
  });

  @override
  State<_QrShareBlock> createState() => _QrShareBlockState();
}

class _QrShareBlockState extends State<_QrShareBlock> {
  final GlobalKey _boundaryKey = GlobalKey();

  Future<void> _shareQrCode() async {
    try {
      final boundary =
          _boundaryKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) return;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      final pngBytes = byteData.buffer.asUint8List();
      final fileName = 'referrer_qr.png';

      if (kIsWeb) {
        await Share.share(widget.data);
        return;
      }

      await Share.shareXFiles(
        [XFile.fromData(pngBytes, name: fileName, mimeType: 'image/png')],
        subject: 'Referrer QR Code',
        text: widget.data,
      );
    } catch (_) {
      if (mounted) {
        await Share.share(widget.data);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        RepaintBoundary(key: _boundaryKey, child: widget.child),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: _shareQrCode,
          icon: const Icon(Icons.share_outlined),
          label: const Text('Share QR Code'),
        ),
      ],
    );
  }
}

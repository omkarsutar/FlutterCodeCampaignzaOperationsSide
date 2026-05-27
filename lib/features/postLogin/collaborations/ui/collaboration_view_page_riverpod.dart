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

                      // Commission Config Detail Box
                      _buildCommissionTypeDetails(
                        theme,
                        collaboration,
                        baseCommissionRate,
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
    if (promoCode == null || promoCode.isEmpty) {
      return const SizedBox.shrink();
    }

    final date = collaboration.createdAt ?? DateTime.now();
    final months = [
      'jan',
      'feb',
      'mar',
      'apr',
      'may',
      'jun',
      'jul',
      'aug',
      'sep',
      'oct',
      'nov',
      'dec',
    ];
    final campaignCode = '${months[date.month - 1]}${date.year}';

    final instagramReferrer =
        'utm_source%3Dinstagram%26utm_campaign%3D$campaignCode%26utm_medium%3D$promoCode';
    final facebookReferrer =
        'utm_source%3Dfacebook%26utm_campaign%3D$campaignCode%26utm_medium%3D$promoCode';

    final instagramUrl =
        'https://play.google.com/store/apps/details?id=com.numeroshastra.client&referrer=$instagramReferrer';
    final facebookUrl =
        'https://play.google.com/store/apps/details?id=com.numeroshastra.client&referrer=$facebookReferrer';

    // Watch analytics counts
    final purchaseCountAsync = ref.watch(purchaseCountProvider(promoCode));
    final instagramInstallCountAsync = ref.watch(
      installCountProvider(instagramReferrer),
    );
    final facebookInstallCountAsync = ref.watch(
      installCountProvider(facebookReferrer),
    );

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
                  'Promo Code & Copyable Links',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              Tooltip(
                message: 'Refresh counts',
                child: IconButton(
                  icon: Icon(
                    Icons.refresh,
                    color: theme.colorScheme.primary,
                    size: 22,
                  ),
                  onPressed: () {
                    ref.invalidate(purchaseCountProvider(promoCode));
                    ref.invalidate(installCountProvider(instagramReferrer));
                    ref.invalidate(installCountProvider(facebookReferrer));
                    SnackbarUtils.showSuccess('Refreshing counts...');
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Promocode field with purchase count
          _buildCopyableField(
            context,
            theme,
            'Promo Code',
            promoCode,
            'Promo Code',
          ),
          const SizedBox(height: 4),
          _buildCountRow(
            theme,
            'Purchase Count',
            purchaseCountAsync,
            Icons.shopping_cart_outlined,
            Colors.deepPurple,
          ),
          const SizedBox(height: 16),

          // Instagram Bio Link field with install count
          _buildCopyableField(
            context,
            theme,
            'Instagram Bio Link',
            instagramUrl,
            'Instagram Bio Link',
            logoWidget: SizedBox(
              width: 20,
              height: 20,
              child: Image.asset('assets/images/instagram_logo.png'),
            ),
          ),
          const SizedBox(height: 4),
          _buildCountRow(
            theme,
            'Installed Count',
            instagramInstallCountAsync,
            Icons.install_mobile,
            Colors.pink,
          ),
          const SizedBox(height: 16),

          // Facebook Bio Link field with install count
          _buildCopyableField(
            context,
            theme,
            'Facebook Bio Link',
            facebookUrl,
            'Facebook Bio Link',
            logoWidget: SizedBox(
              width: 20,
              height: 20,
              child: Image.asset('assets/images/facebook_logo.png'),
            ),
          ),
          const SizedBox(height: 4),
          _buildCountRow(
            theme,
            'Installed Count',
            facebookInstallCountAsync,
            Icons.install_mobile,
            Colors.blue,
          ),
        ],
      ),
    );
  }

  /// Displays a count value with loading/error states
  Widget _buildCountRow(
    ThemeData theme,
    String label,
    AsyncValue<int> countAsync,
    IconData icon,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            '$label: ',
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
          countAsync.when(
            data: (count) => Text(
              '$count',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
                fontSize: 14,
              ),
            ),
            loading: () => const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            error: (err, _) => Text(
              'Error',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.red,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCopyableField(
    BuildContext context,
    ThemeData theme,
    String label,
    String text,
    String snackbarLabel, {
    Widget? logoWidget,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (logoWidget != null) ...[logoWidget, const SizedBox(width: 8)],
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Text(
                    text,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.copy, size: 20),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: text));
                  SnackbarUtils.showSuccess(
                    '$snackbarLabel copied to clipboard!',
                  );
                },
                color: theme.colorScheme.primary,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),
      ],
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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../../core/providers/core_providers.dart';
import '../../../../core/utils/dialogs.dart';
import '../../../../shared/widgets/custom_app_bar.dart';
import '../model/influencer_model.dart';
import '../providers/influencer_providers.dart';

class InfluencerViewPageRiverpod extends ConsumerWidget {
  final String entityId;

  const InfluencerViewPageRiverpod({super.key, required this.entityId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final influencerAsync = ref.watch(influencerByIdProvider(entityId));
    final isInitialized = ref.watch(rbacInitializationProvider);
    final rbacService = ref.watch(rbacServiceProvider);

    final roleName = ref.watch(roleNameProvider);
    final isAdmin = roleName?.toLowerCase() == 'admin';

    const rbacModule = 'influencer';
    final canUpdate = isInitialized && rbacService.canUpdate(rbacModule);
    final canDelete = isInitialized && rbacService.canDelete(rbacModule);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: CustomAppBar(
        title: 'Influencer Details',
        showBack: context.canPop(),
        actions: [
          if (canUpdate)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                context.pushNamed(
                  'editInfluencer',
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
      body: influencerAsync.when(
        data: (influencer) {
          if (influencer == null) {
            return const Center(child: Text('Influencer not found'));
          }

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile Image
                _buildProfileHeader(context, theme, influencer),

                // Details
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name
                      Text(
                        influencer.influencerName,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (influencer.influencerNameHindi != null &&
                          influencer.influencerNameHindi!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          influencer.influencerNameHindi!,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),

                      // Category
                      _buildInfoRow(
                        theme,
                        'Category',
                        influencer.influencerCategory,
                      ),

                      // Commission Rate (admin only)
                      if (isAdmin)
                        _buildInfoRow(
                          theme,
                          'Base Commission Rate',
                          '${influencer.baseCommissionRate}%',
                        ),

                      // Availability
                      _buildInfoRow(
                        theme,
                        'Status',
                        influencer.isAvailable ? 'Available' : 'Unavailable',
                        valueColor: influencer.isAvailable
                            ? Colors.green
                            : Colors.red,
                      ),

                      // Active
                      _buildInfoRow(
                        theme,
                        'Active',
                        influencer.isActive ? 'Active' : 'Inactive',
                        valueColor: influencer.isActive
                            ? Colors.green
                            : Colors.red,
                      ),

                      // Image URL (if exists)
                      if (influencer.influencerImageUrl != null &&
                          influencer.influencerImageUrl!.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        const Divider(),
                        const SizedBox(height: 16),
                        Text(
                          'Profile URL',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SelectableText(
                          influencer.influencerImageUrl!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
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
                'Error loading influencer',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(err.toString(), textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(influencerByIdProvider(entityId)),
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
    ModelInfluencer influencer,
  ) {
    return Container(
      width: double.infinity,
      height: 250,
      color: Colors.grey[200],
      child: influencer.influencerImageUrl != null &&
              influencer.influencerImageUrl!.isNotEmpty
          ? CachedNetworkImage(
              imageUrl: Uri.encodeFull(
                Uri.decodeFull(influencer.influencerImageUrl!),
              ),
              fit: BoxFit.cover,
              placeholder: (context, url) => const Center(
                child: CircularProgressIndicator(),
              ),
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

  Widget _buildInfoRow(
    ThemeData theme,
    String label,
    String value, {
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
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
                fontWeight: FontWeight.w600,
                color: valueColor ?? Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showDeleteDialog(BuildContext context, WidgetRef ref) async {
    final confirmed = await showConfirmDeleteWithTextDialog(
      context: context,
      title: 'Delete Influencer',
      content:
          'Are you sure you want to delete this influencer? This action cannot be undone.',
      entityNameLower: 'influencer',
    );

    if (confirmed) {
      try {
        await ref.read(influencerFormProvider.notifier).delete(entityId);
        if (context.mounted) {
          context.pop();
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting: $e')),
          );
        }
      }
    }
  }
}
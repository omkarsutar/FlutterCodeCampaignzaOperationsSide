import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../../core/providers/core_providers.dart';
import '../../../../core/services/entity_service.dart';
import '../model/influencer_model.dart';

class InfluencerListTile extends ConsumerWidget {
  final ModelInfluencer entity;
  final EntityAdapter<ModelInfluencer> adapter;
  final VoidCallback? onTap;

  const InfluencerListTile({
    super.key,
    required this.entity,
    required this.adapter,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final roleName = ref.watch(roleNameProvider);
    final isAdmin = roleName?.toLowerCase() == 'admin';

    final influencerName = entity.influencerName;
    final influencerCategory = entity.influencerCategory;
    final commissionRate = entity.baseCommissionRate;
    final imageUrl = entity.influencerImageUrl;
    final isAvailable = entity.isAvailable;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Influencer Image
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 60,
                  height: 60,
                  child: _buildInfluencerImage(imageUrl),
                ),
              ),
              const SizedBox(width: 12),
              // Influencer Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            influencerName,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        _buildAvailabilityBadge(theme, isAvailable),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _buildCategoryChip(theme, influencerCategory),
                        if (isAdmin) ...[
                          const SizedBox(width: 8),
                          _buildCommissionRate(theme, commissionRate),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfluencerImage(String? imageUrl) {
    if (imageUrl != null && imageUrl.isNotEmpty) {
      final encodedUrl = Uri.encodeFull(Uri.decodeFull(imageUrl));
      return CachedNetworkImage(
        imageUrl: encodedUrl,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          color: Colors.grey.shade200,
          child: const Center(
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
        errorWidget: (context, url, error) => _buildDefaultAvatar(),
      );
    }
    return _buildDefaultAvatar();
  }

  Widget _buildDefaultAvatar() {
    return Container(
      color: Colors.grey.shade200,
      child: const Center(
        child: Icon(
          Icons.person,
          color: Colors.grey,
          size: 32,
        ),
      ),
    );
  }

  Widget _buildAvailabilityBadge(ThemeData theme, bool isAvailable) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isAvailable
            ? Colors.green.withValues(alpha: 0.1)
            : Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        isAvailable ? 'Available' : 'Unavailable',
        style: theme.textTheme.labelSmall?.copyWith(
          color: isAvailable ? Colors.green : Colors.red,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildCategoryChip(ThemeData theme, String category) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        category,
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onPrimaryContainer,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildCommissionRate(ThemeData theme, double rate) {
    return Text(
      '${rate.toStringAsFixed(1)}% commission',
      style: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.secondary,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}
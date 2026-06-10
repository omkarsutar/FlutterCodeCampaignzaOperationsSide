import 'package:flutter/material.dart';
import '../../../../core/services/entity_service.dart';
import '../model/user_model.dart';

class UserListTile extends StatelessWidget {
  final ModelUser entity;
  final EntityAdapter<ModelUser> adapter;
  final VoidCallback? onTap;

  const UserListTile({
    super.key,
    required this.entity,
    required this.adapter,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final fullName =
        adapter.getFieldValue(entity, ModelUserFields.fullName)?.toString() ??
        'Unnamed User';
    final role =
        adapter.getLabelValue(entity, ModelUserFields.roleId)?.toString() ??
        'Role not set';
    final email =
        adapter.getFieldValue(entity, ModelUserFields.email)?.toString() ??
        'No email';
    final photoUrl =
        adapter.getFieldValue(entity, ModelUserFields.userPhotoUrl)?.toString();

    // Initials for avatar fallback
    final initials = fullName.isNotEmpty
        ? fullName.trim().split(' ').take(2).map((e) => e[0]).join()
        : '?';

    // Optional: status badge if you add is_active / is_available fields
    final isActive =
        adapter.getFieldValue(entity, 'is_active') as bool? ?? true;
    final isAvailable =
        adapter.getFieldValue(entity, 'is_available') as bool? ?? true;

    Color statusColor;
    String statusText;
    if (!isActive) {
      statusColor = Colors.red;
      statusText = 'INACTIVE';
    } else if (!isAvailable) {
      statusColor = Colors.orange;
      statusText = 'UNAVAILABLE';
    } else {
      statusColor = Colors.green;
      statusText = 'AVAILABLE';
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar Section
              Hero(
                tag: 'user_avatar_${entity.userId}',
                child: CircleAvatar(
                  radius: 28,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  backgroundImage:
                      (photoUrl != null && photoUrl.isNotEmpty)
                          ? NetworkImage(photoUrl)
                          : null,
                  child:
                      (photoUrl == null || photoUrl.isEmpty)
                          ? Text(
                            initials.toUpperCase(),
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: theme.colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                          : null,
                ),
              ),
              const SizedBox(width: 16),

              // Info Section
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Row 1: Full Name + Status Badge
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            fullName,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: statusColor, width: 0.5),
                          ),
                          child: Text(
                            statusText,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: statusColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Row 2: Email
                    Row(
                      children: [
                        Icon(
                          Icons.email_outlined,
                          size: 14,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            email,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Row 3: Role
                    Row(
                      children: [
                        Icon(
                          Icons.badge_outlined,
                          size: 14,
                          color: theme.colorScheme.primary.withValues(
                            alpha: 0.7,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          role,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

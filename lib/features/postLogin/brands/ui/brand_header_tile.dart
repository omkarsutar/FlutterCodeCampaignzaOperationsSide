import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_supabase_order_app_mobile/core/providers/core_providers.dart';
import 'package:flutter_supabase_order_app_mobile/core/providers/auth_providers.dart';
import 'package:flutter_supabase_order_app_mobile/features/postLogin/agencies/providers/agency_providers.dart';

class BrandHeaderTile extends ConsumerWidget {
  const BrandHeaderTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final roleName = ref.watch(roleNameProvider)?.toLowerCase();
    final isAdmin = roleName == 'admin';
    if (isAdmin) return const SizedBox.shrink();

    // Get Agency details
    final agencyNameAsync = ref.watch(currentAgencyNameProvider);
    final userProfile = ref.watch(userProfileProvider).value;
    final agencyId = userProfile?.preferredAgencyId;

    final valueStyle = theme.textTheme.bodyMedium?.copyWith(
      fontWeight: FontWeight.bold,
      fontSize: 14,
    );

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.55),
          width: 0.8,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: agencyNameAsync.when(
          data: (agencyName) => Row(
            children: [
              Icon(Icons.corporate_fare_outlined, color: theme.colorScheme.primary, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Agency: $agencyName',
                  style: valueStyle,
                ),
              ),
              if (agencyId != null && agencyId.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.visibility_outlined),
                  tooltip: 'View agency',
                  iconSize: 18,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                  onPressed: () => context.pushNamed(
                    'viewAgency',
                    pathParameters: {'id': agencyId},
                  ),
                ),
            ],
          ),
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        ),
      ),
    );
  }
}

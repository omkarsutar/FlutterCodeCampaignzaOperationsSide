import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/field_config.dart';
import '../../../../core/config/module_config.dart';
import '../../../../core/models/entity_meta.dart';
import '../../../../core/services/entity_service.dart';
import '../../../../core/providers/localization_provider.dart';
import '../../../../shared/widgets/custom_app_bar.dart';
import '../../../../shared/widgets/custom_drawer.dart';
import '../model/influencer_model.dart';
import '../providers/influencer_providers.dart';
import 'influencer_list_tile.dart';

class InfluencerListPageRiverpod extends ConsumerWidget {
  final EntityMeta entityMeta;
  final String idField;
  final List<FieldConfig> fieldConfigs;
  final String? timestampField;
  final String viewRouteName;
  final String newRouteName;
  final String rbacModule;
  final bool isSelectionMode;
  final SortingConfig? initialSorting;
  final ProviderListenable<AsyncValue<List<ModelInfluencer>>> streamProvider;
  final Provider<EntityAdapter<ModelInfluencer>> adapterProvider;
  final Provider<EntityService<ModelInfluencer>> serviceProvider;
  final List<String>? searchFields;

  const InfluencerListPageRiverpod({
    super.key,
    required this.entityMeta,
    required this.idField,
    required this.viewRouteName,
    required this.fieldConfigs,
    required this.streamProvider,
    required this.adapterProvider,
    required this.serviceProvider,
    this.searchFields,
    this.timestampField,
    required this.newRouteName,
    required this.rbacModule,
    this.isSelectionMode = false,
    this.initialSorting,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final entitiesAsync = ref.watch(streamProvider);
    final entityAdapter = ref.watch(adapterProvider);
    final l10n = ref.watch(l10nProvider);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      drawer: isSelectionMode ? null : const CustomDrawer(),
      appBar: CustomAppBar(
        title: isSelectionMode
            ? 'Select ${entityMeta.entityNamePlural}'
            : l10n['influencers'] ?? entityMeta.entityNamePlural,
        showBack: isSelectionMode,
      ),
      floatingActionButton: isSelectionMode
          ? null
          : FloatingActionButton.extended(
              onPressed: () => context.pushNamed(newRouteName),
              icon: const Icon(Icons.add),
              label: Text('Add ${entityMeta.entityName}'),
            ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.surface,
              theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.25),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: entitiesAsync.when(
          data: (entities) {
            if (entities.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.people_outline,
                      size: 64,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No influencers found',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: () => context.pushNamed(newRouteName),
                      icon: const Icon(Icons.add),
                      label: const Text('Add First Influencer'),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: entities.length,
              itemBuilder: (context, index) {
                final entity = entities[index];
                return InfluencerListTile(
                  entity: entity,
                  adapter: entityAdapter,
                  onTap: () {
                    if (isSelectionMode) {
                      context.pop(entity);
                    } else {
                      context.pushNamed(
                        viewRouteName,
                        pathParameters: {'id': entity.influencerId!},
                      );
                    }
                  },
                );
              },
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
                Text(
                  'Error loading ${entityMeta.entityNamePluralLower}',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  err.toString(),
                  style: theme.textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.invalidate(influencersStreamProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
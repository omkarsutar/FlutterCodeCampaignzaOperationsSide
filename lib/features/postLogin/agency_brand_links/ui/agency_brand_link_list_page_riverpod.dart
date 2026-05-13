import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/field_config.dart';
import '../../../../core/config/module_config.dart';
import '../../../../core/models/entity_meta.dart';
import '../../../../core/services/entity_service.dart';
import '../../../../shared/widgets/shared_widget_barrel.dart';
import 'package:flutter_supabase_order_app_mobile/features/postLogin/entity_page/entity_page_barrel.dart';
import '../agency_brand_link_barrel.dart';

class AgencyBrandLinkListPageRiverpod extends ConsumerStatefulWidget {
  final EntityMeta entityMeta;
  final String idField;
  final List<FieldConfig> fieldConfigs;
  final String? timestampField;
  final String viewRouteName;
  final String newRouteName;
  final String rbacModule;
  final bool isSelectionMode;
  final SortingConfig? initialSorting;

  // Search function
  final bool Function(ModelAgencyBrandLink entity, String query)? searchMatcher;
  final List<String>? searchFields;

  // Custom Item Builder
  final Widget Function(
    BuildContext context,
    ModelAgencyBrandLink entity,
    EntityAdapter<ModelAgencyBrandLink> adapter,
    VoidCallback onTap,
  )?
  customItemBuilder;

  const AgencyBrandLinkListPageRiverpod({
    super.key,
    required this.entityMeta,
    required this.idField,
    required this.viewRouteName,
    required this.fieldConfigs,
    this.searchMatcher,
    this.searchFields,
    this.timestampField,
    required this.newRouteName,
    required this.rbacModule,
    this.isSelectionMode = false,
    this.customItemBuilder,
    this.initialSorting,
  });

  @override
  ConsumerState<AgencyBrandLinkListPageRiverpod> createState() =>
      _AgencyBrandLinkListPageRiverpodState();
}

class _AgencyBrandLinkListPageRiverpodState
    extends ConsumerState<AgencyBrandLinkListPageRiverpod> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();

    // Set sorting configuration once when widget is created
    if (widget.initialSorting != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final service = ref.read(agencyBrandLinkServiceProvider);
        service.setSortingConfig(
          widget.initialSorting!.field,
          widget.initialSorting!.sortAscending,
        );
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final adapter = ref.watch(agencyBrandLinkAdapterProvider);
    final service = ref.watch(agencyBrandLinkServiceProvider);

    final listState = ref.watch(agencyBrandLinkListControllerProvider);
    final controller = ref.read(agencyBrandLinkListControllerProvider.notifier);

    // Watch the Backend Data
    final asyncEntities = listState.selectedAgencyId == null
        ? const AsyncValue<List<ModelAgencyBrandLink>>.loading()
        : ref.watch(
            agencyBrandLinksByAgencyProvider(listState.selectedAgencyId!),
          );

    // Sync local state when provider data changes
    if (listState.selectedAgencyId != null) {
      ref.listen<AsyncValue<List<ModelAgencyBrandLink>>>(
        agencyBrandLinksByAgencyProvider(listState.selectedAgencyId!),
        (previous, next) {
          next.whenData((data) {
            controller.setEntities(data);
          });
        },
      );
    }

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: CustomAppBar(
        title: 'Agency Brand Links',
        showBack: widget.isSelectionMode,
      ),
      drawer: widget.isSelectionMode ? null : const CustomDrawer(),
      floatingActionButton: widget.isSelectionMode
          ? null
          : CreateEntityButton(
              moduleName: widget.rbacModule,
              newRouteName: widget.newRouteName,
              entityLabel: widget.entityMeta.entityName,
              queryParameters: listState.selectedAgencyId != null
                  ? {'agencyId': listState.selectedAgencyId!}
                  : null,
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
        child: Column(
          children: [
            // 1. Collapsible Search Bar with Route Dropdown
            CollapsibleSearchBar(
              dropdown: Container(
                padding: const EdgeInsets.only(right: 8),
                child: AgencyDropdown(
                  initialAgencyId: listState.selectedAgencyId,
                  onAgencySelected: controller.setAgencyId,
                ),
              ),
              controller: _searchController,
              onChanged: controller.setSearchQuery,
            ),

            // 2. Scrollable Reorderable List Content
            Expanded(
              child: listState.selectedAgencyId == null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.alt_route_rounded,
                            size: 64,
                            color: theme.colorScheme.primary.withValues(
                              alpha: 0.5,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Please select an agency',
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Select an agency from the dropdown above to view brands.',
                            style: theme.textTheme.bodySmall,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : Builder(
                      builder: (context) {
                        // If still loading and no local entities, show loader from AsyncValue
                        if (listState.localEntities.isEmpty &&
                            asyncEntities.isLoading) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        if (listState.localEntities.isEmpty &&
                            asyncEntities.hasError) {
                          return Center(
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
                                  'Error loading data',
                                  style: theme.textTheme.titleMedium,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  asyncEntities.error.toString(),
                                  style: theme.textTheme.bodySmall,
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          );
                        }

                        // Use Controller for filtering
                        final filteredEntities = controller.getFilteredEntities(
                          adapter: adapter,
                          customMatcher: widget.searchMatcher,
                          searchFields: widget.searchFields,
                        );

                        if (filteredEntities.isEmpty) {
                          final isSearchEmpty =
                              listState.searchQuery.isNotEmpty;
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.inbox_outlined,
                                  size: 64,
                                  color: theme.colorScheme.onSurface.withValues(
                                    alpha: 0.3,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  isSearchEmpty
                                      ? 'No matching ${widget.entityMeta.entityNamePluralLower}'
                                      : 'No ${widget.entityMeta.entityNamePluralLower} in this agency',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: theme.colorScheme.onSurface
                                        .withValues(alpha: 0.6),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        final bool canReorder = listState.searchQuery.isEmpty;

                        return canReorder
                            ? ReorderableListView.builder(
                                padding: const EdgeInsets.only(bottom: 100),
                                itemCount: filteredEntities.length,
                                onReorder: (oldIndex, newIndex) => controller
                                    .reorder(oldIndex, newIndex, widget.idField)
                                    .catchError((e) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Failed to reorder: $e',
                                            ),
                                            backgroundColor:
                                                theme.colorScheme.error,
                                          ),
                                        );
                                      }
                                    }),
                                itemBuilder: (context, index) {
                                  final entity = filteredEntities[index];
                                  final key = ValueKey(
                                    adapter.getId(entity, widget.idField),
                                  );

                                  return Container(
                                    key: key,
                                    child: _buildItem(
                                      context,
                                      entity,
                                      adapter,
                                      service,
                                      listState.selectedAgencyId,
                                    ),
                                  );
                                },
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.only(bottom: 100),
                                itemCount: filteredEntities.length,
                                itemBuilder: (context, index) {
                                  final entity = filteredEntities[index];
                                  return _buildItem(
                                    context,
                                    entity,
                                    adapter,
                                    service,
                                    listState.selectedAgencyId,
                                  );
                                },
                              );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItem(
    BuildContext context,
    ModelAgencyBrandLink entity,
    EntityAdapter<ModelAgencyBrandLink> adapter,
    EntityService<ModelAgencyBrandLink> service,
    String? selectedAgencyId,
  ) {
    if (widget.customItemBuilder != null) {
      return widget.customItemBuilder!(context, entity, adapter, () async {
        await context.pushNamed(
          widget.viewRouteName,
          pathParameters: {
            'id': adapter.getId(entity, widget.idField).toString(),
          },
        );
        // Refresh data on return
        if (mounted && selectedAgencyId != null) {
          ref
              .read(agencyBrandLinkListControllerProvider.notifier)
              .setEntities([]); // Optional: clear list to show loading/refresh
          await Future.delayed(const Duration(milliseconds: 500));
          ref.invalidate(agencyBrandLinksByAgencyProvider(selectedAgencyId));
        }
      });
    }
    return EntityCard<ModelAgencyBrandLink>(
      entity: entity,
      adapter: adapter,
      entityService: service,
      fieldConfigs: widget.fieldConfigs.where((f) => f.visibleInList).toList(),
      idField: widget.idField,
      timestampField: widget.timestampField,
      entityLabel: widget.entityMeta.entityName,
      entityLabelLower: widget.entityMeta.entityNameLower,
      viewRouteName: widget.viewRouteName,
    );
  }
}

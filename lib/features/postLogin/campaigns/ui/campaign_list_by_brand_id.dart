import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_supabase_order_app_mobile/core/utils/json_utils.dart';
import 'package:flutter_supabase_order_app_mobile/features/postLogin/brands/brand_barrel.dart';
import 'package:flutter_supabase_order_app_mobile/features/postLogin/brands/ui/brand_list_tile.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_supabase_order_app_mobile/core/config/module_config.dart';
import '../../../../core/config/field_config.dart';
import '../../../../core/models/entity_meta.dart';
import 'package:flutter_supabase_order_app_mobile/shared/widgets/shared_widget_barrel.dart';
import '../model/campaign_model.dart';
import '../providers/campaign_list_controller.dart';
import '../providers/campaign_providers.dart';
import 'campaign_list_tile.dart';
import '../../cart/providers/cart_controller.dart';

/// Custom Campaign List Page - Riverpod & JSON based
///
/// Single Responsibility: Display campaigns with search, filtering, and navigation.
/// Focuses only on presentation and user interaction, delegating state management to Riverpod.
class CampaignListByBrandId extends ConsumerStatefulWidget {
  final EntityMeta entityMeta;
  final String idField;
  final List<FieldConfig> fieldConfigs;
  final String? timestampField;
  final String viewRouteName;
  final String newRouteName;
  final String rbacModule;
  final List<String>? searchFields;
  final SortingConfig? initialSorting;

  const CampaignListByBrandId({
    super.key,
    required this.entityMeta,
    required this.idField,
    required this.fieldConfigs,
    required this.timestampField,
    required this.viewRouteName,
    required this.newRouteName,
    required this.rbacModule,
    this.searchFields,
    this.initialSorting,
  });

  @override
  ConsumerState<CampaignListByBrandId> createState() =>
      _CampaignListByBrandIdState();
}

class _CampaignListByBrandIdState extends ConsumerState<CampaignListByBrandId> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();

    // Set sorting configuration once when widget is created
    if (widget.initialSorting != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final service = ref.read(campaignServiceProvider);
        service.setSortingConfig(
          widget.initialSorting!.field,
          widget.initialSorting!.sortAscending,
        );

        // Reset filters when entering this specialized view
        ref
            .read(campaignListControllerProvider('campaignList').notifier)
            .resetFilters(searchFields: widget.searchFields);
      });
    } else {
      // Even if no initial sorting, reset filters to ensure a clean state
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref
            .read(campaignListControllerProvider('campaignList').notifier)
            .resetFilters(searchFields: widget.searchFields);
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _updateSearch(String query) {
    ref
        .read(campaignListControllerProvider('campaignList').notifier)
        .setSearchQuery(query, searchFields: widget.searchFields);
  }

  String? _getFilterBrandId() {
    return GoRouterState.of(context).uri.queryParameters['filterBrandId'];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filterBrandId = _getFilterBrandId();

    // Watch the controller state (handles loading, errors, filtering)
    final listState = ref.watch(campaignListControllerProvider('campaignList'));

    final extra = GoRouterState.of(context).extra;
    final brand = extra is ModelBrand ? extra : null;
    prettyPrint(brand);

    final displayList = filterBrandId != null
        ? listState.filteredCampaigns
              .where((po) => po.poBrandId == filterBrandId)
              .toList()
        : listState.filteredCampaigns;

    final queryParams = getBrandQueryParams(context);

    return Scaffold(
      bottomNavigationBar: buildBrandBottomNav(
        context: context,
        ref: ref,
        tapCondition: queryParams.tapCondition,
        showBottomNav:
            queryParams.filterBrandId !=
            null, // only show if navigated from Brands
      ),
      backgroundColor: theme.colorScheme.surface,
      appBar: CustomAppBar(
        title: widget.entityMeta.entityNamePlural,
        showBack: queryParams.showBackButton,
      ),
      drawer: queryParams.showBackButton ? null : const CustomDrawer(),
      /* floatingActionButton: CreateEntityButton(
        moduleName: ModelCampaignFields.table,
        newRouteName: widget.newRouteName,
        entityLabel: widget.entityMeta.entityName,
      ), */
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
            AgencyLabelWidget(),
            // Search Bar
            if (filterBrandId == null)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText:
                        'Search ${widget.entityMeta.entityNamePluralLower}...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: listState.searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              ref
                                  .read(
                                    campaignListControllerProvider(
                                      'campaignList',
                                    ).notifier,
                                  )
                                  .clearSearch(
                                    searchFields: widget.searchFields,
                                  );
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    filled: true,
                    fillColor: theme.colorScheme.surface,
                  ),
                  onChanged: (val) => _updateSearch(val),
                ),
              ),
            if (brand != null) ...[
              BrandListTile(
                entity: brand,
                adapter: ref.watch(brandAdapterProvider),
                idField: ModelBrandFields.brandId,
                entityLabel: 'Brand',
                entityLabelLower: 'brand',
                viewRouteName: BrandsRoutesJson.viewRouteName,
                rbacModule: 'brands',
                onTap: () {
                  GoRouter.of(context).pushNamed(
                    BrandsRoutesJson.viewRouteName,
                    queryParameters: {'brand_id': brand.brandId!},
                  );
                },
              ),
              const Divider(),
            ],

            // Campaigns List
            Expanded(child: _buildListContent(theme, listState, displayList)),
          ],
        ),
      ),
    );
  }

  /// Builds the list content based on controller state
  /// Handles loading, error, and data states
  Widget _buildListContent(
    ThemeData theme,
    CampaignListState listState,
    List<ModelCampaign> displayList,
  ) {
    // Loading state
    if (listState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Error state
    if (listState.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text(
              'Error loading ${widget.entityMeta.entityNamePluralLower}',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              listState.error!,
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                ref
                    .read(
                      campaignListControllerProvider('campaignList').notifier,
                    )
                    .refreshData();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    // Empty state
    if (displayList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 64,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              listState.searchQuery.isEmpty
                  ? 'No ${widget.entityMeta.entityNamePluralLower} found'
                  : 'No matching ${widget.entityMeta.entityNamePluralLower}',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      );
    }

    return _buildList(displayList);
  }

  /// Builds the ListView of campaigns
  Widget _buildList(List<ModelCampaign> displayList) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: displayList.length + 1,
      itemBuilder: (context, index) {
        if (index < displayList.length) {
          final displayListItem = displayList[index];
          return CampaignListTile(
            entity: displayListItem,
            adapter: ref.watch(campaignAdapterProvider),
            onTap: () => ref
                .read(cartControllerProvider)
                .editCampaign(context, displayListItem),
          );
        } else {
          // Bottom padding for FAB
          return const SizedBox(height: 80);
        }
      },
    );
  }
}

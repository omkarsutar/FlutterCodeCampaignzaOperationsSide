import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
import '../../../../core/utils/core_utils_barrel.dart';
import '../../../../core/providers/core_providers.dart';
import '../../users/providers/user_providers.dart';
import 'widgets/campaign_header_tile.dart';

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
  final ScrollController _filterScrollController = ScrollController();

  String get _controllerKey => _getFilterBrandId() ?? 'campaignList';

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
            .read(campaignListControllerProvider(_controllerKey).notifier)
            .resetFilters(searchFields: widget.searchFields);
      });
    } else {
      // Even if no initial sorting, reset filters to ensure a clean state
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref
            .read(campaignListControllerProvider(_controllerKey).notifier)
            .resetFilters(searchFields: widget.searchFields);
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _filterScrollController.dispose();
    super.dispose();
  }

  void _updateSearch(String query) {
    ref
        .read(campaignListControllerProvider(_controllerKey).notifier)
        .setSearchQuery(query, searchFields: widget.searchFields);
  }

  String? _getFilterBrandId() {
    return GoRouterState.of(context).uri.queryParameters['filterBrandId'];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filterBrandId = _getFilterBrandId();

    final roleName = ref.watch(roleNameProvider)?.toLowerCase();
    final isAdmin = roleName == 'admin';

    // Watch the controller state (handles loading, errors, filtering)
    final listState = ref.watch(campaignListControllerProvider(_controllerKey));

    final extra = GoRouterState.of(context).extra;
    final brand = extra is ModelBrand ? extra : null;
    prettyPrint(brand);

    final displayList = listState.filteredCampaigns;

    final queryParams = getBrandQueryParams(context);

    final brandCampaigns = listState.allCampaigns;

    final Map<String, int> typeCounts = {
      'All': brandCampaigns.length,
      'Paid Ads': brandCampaigns.where((po) => po.effectiveCampaignType == CampaignType.paidAds).length,
      'Direct': brandCampaigns.where((po) => po.effectiveCampaignType == CampaignType.directBrandPromotions).length,
      'Collabs': brandCampaigns.where((po) => po.effectiveCampaignType == CampaignType.influencerCollaborations).length,
    };

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: CustomAppBar(
        title: widget.entityMeta.entityNamePlural,
        showBack: queryParams.showBackButton,
      ),
      drawer: queryParams.showBackButton ? null : const CustomDrawer(),
      floatingActionButton: (filterBrandId != null && brand != null)
          ? FloatingActionButton.extended(
              onPressed: () {
                final agencyId = ref.read(selectedAgencyIdProvider);

                if (agencyId == null) {
                  SnackbarUtils.showError('Missing agency ID');
                  return;
                }

                context.pushNamed(
                  widget.newRouteName,
                  queryParameters: {
                    'campaign_agency_id': agencyId,
                    'campaign_brand_id': filterBrandId,
                  },
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Campaign'),
            )
          : null,
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
            if (isAdmin)
              const AgencyLabelWidget()
            else
              CampaignHeaderTile(
                filterBrandId: filterBrandId,
                brandExtra: brand,
              ),
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
                                      _controllerKey,
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

            // Filter Pills
            _buildFilterPills(theme, listState, typeCounts),
            if (brand != null && isAdmin) ...[
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

  Widget _buildFilterPills(
    ThemeData theme,
    CampaignListState listState,
    Map<String, int> typeCounts,
  ) {
    final types = ['All', 'Paid Ads', 'Direct', 'Collabs'];

    return SizedBox(
      height: 50,
      child: ListView.builder(
        controller: _filterScrollController,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: types.length,
        itemBuilder: (context, index) {
          final typeName = types[index];
          final isSelected =
              (typeName == 'All' && listState.selectedStatus == null) ||
              (typeName.toLowerCase() == listState.selectedStatus?.toLowerCase());

          // Get pre-calculated count
          final count = typeCounts[typeName] ?? 0;

          Color pillColor;
          switch (typeName.toLowerCase()) {
            case 'paid ads':
              pillColor = Colors.blue;
              break;
            case 'direct':
              pillColor = Colors.green;
              break;
            case 'collabs':
              pillColor = Colors.orange;
              break;
            default:
              pillColor = theme.colorScheme.primary;
          }

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(
                '${typeName.toUpperCase()} ($count)',
                style: TextStyle(
                  color: isSelected ? Colors.white : pillColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              selected: isSelected,
              onSelected: (selected) {
                if (!mounted) return;
                // Scroll into view logic
                _scrollToTab(index);

                ref
                    .read(
                      campaignListControllerProvider('campaignList').notifier,
                    )
                    .setStatusFilter(
                      typeName == 'All' ? null : typeName,
                      searchFields: widget.searchFields,
                    );
              },
              selectedColor: pillColor,
              backgroundColor: pillColor.withValues(alpha: 0.1),
              checkmarkColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: pillColor, width: isSelected ? 0 : 1),
              ),
              showCheckmark: false,
            ),
          );
        },
      ),
    );
  }

  void _scrollToTab(int index) {
    const double itemWidth = 100.0; // Estimate
    final double offset = index * itemWidth;
    if (_filterScrollController.hasClients) {
      final double maxScroll = _filterScrollController.position.maxScrollExtent;
      final double target = offset.clamp(0.0, maxScroll);

      _filterScrollController.animateTo(
        target,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_supabase_order_app_mobile/core/config/module_config.dart';
import 'package:flutter_supabase_order_app_mobile/core/config/field_config.dart';
import 'package:flutter_supabase_order_app_mobile/core/models/entity_meta.dart';
import 'package:flutter_supabase_order_app_mobile/core/services/entity_service.dart';
import 'package:flutter_supabase_order_app_mobile/features/postLogin/entity_page/entity_page_barrel.dart';
import 'package:flutter_supabase_order_app_mobile/features/postLogin/brands/providers/brand_list_view_logic.dart';
import 'package:flutter_supabase_order_app_mobile/features/postLogin/brands/providers/brand_list_page_logic.dart';
import 'package:flutter_supabase_order_app_mobile/features/postLogin/brands/brand_barrel.dart';
import 'package:flutter_supabase_order_app_mobile/shared/widgets/shared_widget_barrel.dart';

/// Generic Riverpod version of Entity List Page
/// Can be used for any entity type (Role, Note, etc.)
class BrandListPageRiverpod extends ConsumerStatefulWidget {
  final EntityMeta entityMeta;
  final String idField;
  final List<FieldConfig> fieldConfigs;
  final String? timestampField;
  final String viewRouteName;
  final String newRouteName;
  final String rbacModule;
  final bool isSelectionMode;
  final String? routeIdField;
  final SortingConfig? initialSorting;

  // Riverpod providers
  final ProviderListenable<AsyncValue<List<ModelBrand>>> streamProvider;
  final Provider<EntityAdapter<ModelBrand>> adapterProvider;
  final Provider<EntityService<ModelBrand>> serviceProvider;

  // Search function
  final bool Function(ModelBrand entity, String query)? searchMatcher;
  final List<String>? searchFields;

  // Custom Item Builder
  final Widget Function(
    BuildContext context,
    ModelBrand entity,
    EntityAdapter<ModelBrand> adapter,
    VoidCallback onTap,
  )?
  customItemBuilder;

  const BrandListPageRiverpod({
    super.key,
    required this.entityMeta,
    required this.idField,
    required this.viewRouteName,
    required this.fieldConfigs,
    required this.streamProvider,
    required this.adapterProvider,
    required this.serviceProvider,
    this.searchMatcher,
    this.searchFields,
    this.timestampField,
    required this.newRouteName,
    required this.rbacModule,
    this.isSelectionMode = false,
    this.customItemBuilder,
    this.routeIdField,
    this.initialSorting,
  });

  @override
  ConsumerState<BrandListPageRiverpod> createState() =>
      _BrandListPageRiverpodState();
}

class _BrandListPageRiverpodState extends ConsumerState<BrandListPageRiverpod> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();

    // Set sorting configuration once when widget is created
    if (widget.initialSorting != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final service = ref.read(widget.serviceProvider);
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
    final entityAdapter = ref.watch(widget.adapterProvider);
    final entityService = ref.watch(widget.serviceProvider);

    final listState = ref.watch(brandListControllerProvider);
    final controller = ref.read(brandListControllerProvider.notifier);

    final queryParams = getBrandQueryParams(context);
    final tapCondition = queryParams.tapCondition;

    // Watch the processed data from logic provider
    final viewData = ref.watch(brandListViewLogicProvider(tapCondition));

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: CustomAppBar(
        title: getAppBarTitle(tapCondition),
        showBack: false,
      ),
      drawer: const CustomDrawer(),
      floatingActionButton: queryParams.isTapConditionEmpty
          ? CreateEntityButton(
              moduleName: widget.rbacModule,
              newRouteName: widget.newRouteName,
              entityLabel: widget.entityMeta.entityName,
              queryParameters:
                  listState.selectedRouteId != null &&
                      widget.routeIdField != null
                  ? {widget.routeIdField!: listState.selectedRouteId!}
                  : null,
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
            // Search Bar & Route Dropdown
            Row(
              children: [
                Expanded(
                  child: CollapsibleSearchBar(
                    dropdown: RouteDropdown(
                      initialRouteId: listState.selectedRouteId,
                      onRouteSelected: controller.setRouteId,
                      allowAll: true,
                    ),
                    controller: _searchController,
                    onChanged: controller.setSearchQuery,
                  ),
                ),
                if (viewData.brandCount != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${viewData.brandCount}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),

            // Entity List
            Expanded(
              child: _buildListContent(
                theme: theme,
                tapCondition: tapCondition,
                entityAdapter: entityAdapter,
                entityService: entityService,
                viewData: viewData,
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: buildBrandBottomNav(
        context: context,
        ref: ref,
        tapCondition: tapCondition,
        showBottomNav:
            tapCondition == 'listWithoutTodaysPOs' ||
            tapCondition == 'listWithTodaysEmptyPOs' ||
            tapCondition == 'listWithTodaysFilledPOs',
      ),
    );
  }

  /// Builds the list content based on processed data
  Widget _buildListContent({
    required ThemeData theme,
    required String? tapCondition,
    required EntityAdapter<ModelBrand> entityAdapter,
    required EntityService<ModelBrand> entityService,
    required ProcessedBrandListData viewData,
  }) {
    if (viewData.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (viewData.error != null) {
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
              viewData.error.toString(),
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    final brands = viewData.filteredBrands;

    if (brands.isEmpty) {
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
              'No ${widget.entityMeta.entityNamePluralLower} found',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      itemCount: brands.length,
      itemBuilder: (context, index) {
        final brand = brands[index];

        if (widget.customItemBuilder != null) {
          final onTap = getOnTapForBrand(
            context: context,
            entity: brand,
            adapter: entityAdapter,
            tapCondition: tapCondition,
          );

          return widget.customItemBuilder!(
            context,
            brand,
            entityAdapter,
            onTap,
          );
        }

        return EntityCard<ModelBrand>(
          entity: brand,
          adapter: entityAdapter,
          entityService: entityService,
          fieldConfigs: widget.fieldConfigs
              .where((f) => f.visibleInList)
              .toList(),
          idField: widget.idField,
          timestampField: widget.timestampField,
          entityLabel: widget.entityMeta.entityName,
          entityLabelLower: widget.entityMeta.entityNameLower,
          viewRouteName: widget.viewRouteName,
        );
      },
    );
  }

  /// Decides what happens when a brand tile is tapped
  VoidCallback getOnTapForBrand({
    required BuildContext context,
    required ModelBrand entity,
    required EntityAdapter<ModelBrand> adapter,
    required String? tapCondition,
  }) {
    return BrandListPageLogic.getOnTapForBrand(
      context: context,
      entity: entity,
      adapter: adapter,
      tapCondition: tapCondition,
      isSelectionMode: widget.isSelectionMode,
      viewRouteName: widget.viewRouteName,
      idField: widget.idField,
      handleCreatePO: (ctx, ent, adp) =>
          BrandListPageLogic.handleCreateCampaign(
            context: ctx,
            ref: ref,
            entity: ent,
            adapter: adp,
          ),
    );
  }
}

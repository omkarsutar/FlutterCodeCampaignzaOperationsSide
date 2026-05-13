import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/module_config.dart';
import '../../../core/routing/module_route_generator.dart';
import '../../../core/services/entity_service.dart';
import 'model/brand_model.dart';
import 'providers/brand_providers.dart';

import 'ui/brand_list_page_riverpod.dart';
import 'ui/brand_list_tile.dart';

/// JSON-based route generation for Brands module
class BrandsRoutesJson {
  static late ModuleConfig _config;
  static bool _initialized = false;

  /// Initialize and load JSON configuration
  static Future<void> initialize() async {
    if (_initialized) return;

    // Load configuration from JSON file
    _config = await ModuleConfig.loadFromAsset(
      'lib/features/postLogin/brands/brand_config.json',
    );

    // Create typed provider aliases
    final entityServiceProvider = Provider<EntityService<ModelBrand>>((ref) {
      return ref.watch(brandServiceProvider);
    });

    final entityAdapterProvider = Provider<EntityAdapter<ModelBrand>>((ref) {
      return ref.watch(brandAdapterProvider);
    });

    // Sorting is now configured in the list page's initState() method

    // Register module with route generator
    ModuleRouteRegistry.registerModule<ModelBrand>(
      config: _config,
      serviceProvider: entityServiceProvider,
      adapterProvider: entityAdapterProvider,
      streamProvider: brandsStreamProvider,
      entityByIdProvider: brandByIdProvider,
      formProvider: brandFormProvider,
      customListBuilder: (context, state) {
        return BrandListPageRiverpod(
          entityMeta: _config.entityMeta,
          idField: _config.table.idField,
          viewRouteName: _config.routes.viewRouteName,
          fieldConfigs: _config.fields,
          streamProvider: brandsStreamProvider,
          adapterProvider: entityAdapterProvider,
          serviceProvider: entityServiceProvider,
          newRouteName: _config.routes.newRouteName,
          rbacModule: _config.table.name,
          timestampField: _config.table.timestampField,
          initialSorting: _config.listPage?.sorting,
          searchFields: _config.listPage?.searchFields,
          agencyIdField: 'brands_primary_agency',
          isSelectionMode:
              state.uri.queryParameters['selection'] == 'true' ||
              state.uri.queryParameters['isSelectionMode'] == 'true',
          customItemBuilder: (context, entity, adapter, onTap) {
            return BrandListTile<ModelBrand>(
              entity: entity,
              adapter: adapter,
              idField: _config.table.idField,
              entityLabel: _config.entityMeta.entityName,
              entityLabelLower: _config.entityMeta.entityNameLower,
              viewRouteName: _config.routes.viewRouteName,
              rbacModule: _config.table.name,
              onTap: onTap,
            );
          },
        );
      },
    );

    _initialized = true;
  }

  /// Get routes (call after initialize)
  static List<GoRoute> get routes {
    if (!_initialized) {
      throw StateError(
        'BrandsRoutesJson not initialized. Call initialize() first.',
      );
    }
    return ModuleRouteRegistry.routes
        .where((route) => route.path.startsWith(_config.routes.basePath))
        .toList();
  }

  /// Route names (for navigation)
  static String get listRouteName => _config.routes.listRouteName;
  static String get newRouteName => _config.routes.newRouteName;
  static String get editRouteName => _config.routes.editRouteName;
  static String get viewRouteName => _config.routes.viewRouteName;

  /// Route paths
  static String get brands => _config.routes.listPath;
  static String get newBrand => _config.routes.newPath;
  static String editBrandRoute(String id) => _config.routes.editRoute(id);
  static String viewBrandRoute(String id) => _config.routes.viewRoute(id);
}

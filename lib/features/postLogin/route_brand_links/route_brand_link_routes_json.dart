import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/module_config.dart';
import '../../../core/routing/module_route_generator.dart';
import '../../../core/services/entity_service.dart';
import 'model/route_brand_link_model.dart';
import 'providers/route_brand_link_controller.dart';
import 'providers/route_brand_link_providers.dart';
import 'ui/route_brand_link_list_page_riverpod.dart';
import 'ui/route_brand_link_tile.dart';
import 'ui/route_brand_links_view_page_riverpod.dart';
import 'ui/route_brand_link_form_page_riverpod.dart';

/// JSON-based route generation for Route Brand Links module
/// Fully migrated to Riverpod - no GetIt dependency
class RouteBrandLinksRoutesJson {
  static late ModuleConfig _config;
  static bool _initialized = false;

  /// Initialize and load JSON configuration
  static Future<void> initialize() async {
    if (_initialized) return;

    // Load configuration from JSON file
    _config = await ModuleConfig.loadFromAsset(
      'lib/features/postLogin/route_brand_links/route_brand_link_config.json',
    );

    // Cache the configuration so providers can access it
    RouteBrandLinkConfigCache.config = _config;

    // Create typed provider aliases
    final entityServiceProvider = Provider<EntityService<ModelRouteBrandLink>>((
      ref,
    ) {
      return ref.watch(routeBrandLinkServiceProvider);
    });

    final entityAdapterProvider = Provider<EntityAdapter<ModelRouteBrandLink>>((
      ref,
    ) {
      return ref.watch(routeBrandLinkAdapterProvider);
    });

    // Sorting is now configured in the list page's initState() method
    // This ensures it's set on the correct Riverpod provider service instance

    // Register module with route generator
    ModuleRouteRegistry.registerModule<ModelRouteBrandLink>(
      config: _config,
      serviceProvider: entityServiceProvider,
      adapterProvider: entityAdapterProvider,
      streamProvider: routeBrandLinksStreamProvider,
      entityByIdProvider: routeBrandLinkByIdProvider,
      formProvider: routeBrandLinkFormProvider,
      customItemBuilder: (context, entity, adapter, onTap) =>
          RouteBrandLinkListTile(
            entity: entity,
            adapter: adapter,
            onTap: onTap,
          ),
      customListBuilder: (context, state) => RouteBrandLinkListPageRiverpod(
        entityMeta: _config.entityMeta,
        fieldConfigs: _config.fields,
        idField: _config.table.idField,
        timestampField: _config.table.timestampField,
        viewRouteName: _config.routes.viewRouteName,
        newRouteName: _config.routes.newRouteName,
        rbacModule: _config.table.name,
        initialSorting: _config.listPage?.sorting,
        // Search settings
        searchFields: _config.listPage?.searchFields,
        // Custom Item Builder
        customItemBuilder: (context, entity, adapter, onTap) =>
            RouteBrandLinkListTile(
              entity: entity,
              adapter: adapter,
              onTap: onTap,
            ),
      ),
      customViewBuilder: (context, entityId) =>
          RouteBrandLinksViewPageRiverpod<ModelRouteBrandLink>(
            entityId: entityId,
            entityMeta: _config.entityMeta,
            fieldConfigs: _config.fields,
            idField: _config.table.idField,
            timestampField: _config.table.timestampField,
            editRouteName: _config.routes.editRouteName,
            rbacModule: _config.table.name,
            entityByIdProvider: routeBrandLinkByIdProvider,
            adapterProvider: entityAdapterProvider,
            deleteFunction: (ref, id) async {
              final service = ref.read(entityServiceProvider);
              try {
                await service.delete(id);
                return true;
              } catch (e) {
                return false;
              }
            },
          ),
      customFormBuilder: (context, entityId) =>
          RouteBrandLinkFormPageRiverpod<ModelRouteBrandLink>(
            entityId: entityId,
            entityMeta: _config.entityMeta,
            fieldConfigs: _config.fields,
            listRouteName: _config.routes.listRouteName,
            rbacModule: _config.table.name,
            entityByIdProvider: routeBrandLinkByIdProvider,
            adapterProvider: entityAdapterProvider,
            onSave: (ref, fieldValues, id) async {
              final service = ref.read(entityServiceProvider);
              try {
                if (id != null) {
                  // Convert Map to ModelRouteBrandLink for update
                  final updateData =
                      RouteBrandLinkController.convertToModelRouteBrandLink(
                        fieldValues,
                      );
                  await service.update(id, updateData);
                } else {
                  // Convert Map to ModelRouteBrandLink for create
                  final createData =
                      RouteBrandLinkController.convertToModelRouteBrandLink(
                        fieldValues,
                      );
                  await service.create(createData);
                }
                return true;
              } catch (e) {
                return false;
              }
            },
          ),
    );

    _initialized = true;
  }

  /// Get routes (call after initialize)
  static List<GoRoute> get routes {
    if (!_initialized) {
      throw StateError(
        'RouteBrandLinksRoutesJson not initialized. Call initialize() first.',
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
  static String get routeBrandLinks => _config.routes.listPath;
  static String get newRouteBrandLink => _config.routes.newPath;
  static String editRouteBrandLinkRoute(String id) =>
      _config.routes.editRoute(id);
  static String viewRouteBrandLinkRoute(String id) =>
      _config.routes.viewRoute(id);
}

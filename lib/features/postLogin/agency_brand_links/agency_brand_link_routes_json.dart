import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/module_config.dart';
import '../../../core/routing/module_route_generator.dart';
import '../../../core/services/entity_service.dart';
import 'model/agency_brand_link_model.dart';
import 'providers/agency_brand_link_controller.dart';
import 'providers/agency_brand_link_providers.dart';
import 'ui/agency_brand_link_list_page_riverpod.dart';
import 'ui/agency_brand_link_tile.dart';
import 'ui/agency_brand_links_view_page_riverpod.dart';
import 'ui/agency_brand_link_form_page_riverpod.dart';

/// JSON-based route generation for Agency Brand Links module
/// Fully migrated to Riverpod - no GetIt dependency
class AgencyBrandLinksRoutesJson {
  static late ModuleConfig _config;
  static bool _initialized = false;

  /// Initialize and load JSON configuration
  static Future<void> initialize() async {
    if (_initialized) return;

    // Load configuration from JSON file
    _config = await ModuleConfig.loadFromAsset(
      'lib/features/postLogin/agency_brand_links/agency_brand_link_config.json',
    );

    // Cache the configuration so providers can access it
    AgencyBrandLinkConfigCache.config = _config;

    // Create typed provider aliases
    final entityServiceProvider = Provider<EntityService<ModelAgencyBrandLink>>(
      (ref) {
        return ref.watch(agencyBrandLinkServiceProvider);
      },
    );

    final entityAdapterProvider = Provider<EntityAdapter<ModelAgencyBrandLink>>(
      (ref) {
        return ref.watch(agencyBrandLinkAdapterProvider);
      },
    );

    // Register module with route generator
    ModuleRouteRegistry.registerModule<ModelAgencyBrandLink>(
      config: _config,
      serviceProvider: entityServiceProvider,
      adapterProvider: entityAdapterProvider,
      streamProvider: agencyBrandLinksStreamProvider,
      entityByIdProvider: agencyBrandLinkByIdProvider,
      formProvider: agencyBrandLinkFormProvider,
      customItemBuilder: (context, entity, adapter, onTap) =>
          AgencyBrandLinkListTile(
            entity: entity,
            adapter: adapter,
            onTap: onTap,
          ),
      customListBuilder: (context, state) => AgencyBrandLinkListPageRiverpod(
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
            AgencyBrandLinkListTile(
              entity: entity,
              adapter: adapter,
              onTap: onTap,
            ),
      ),
      customViewBuilder: (context, entityId) =>
          AgencyBrandLinksViewPageRiverpod<ModelAgencyBrandLink>(
            entityId: entityId,
            entityMeta: _config.entityMeta,
            fieldConfigs: _config.fields,
            idField: _config.table.idField,
            timestampField: _config.table.timestampField,
            editRouteName: _config.routes.editRouteName,
            rbacModule: _config.table.name,
            entityByIdProvider: agencyBrandLinkByIdProvider,
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
          AgencyBrandLinkFormPageRiverpod<ModelAgencyBrandLink>(
            entityId: entityId,
            entityMeta: _config.entityMeta,
            fieldConfigs: _config.fields,
            listRouteName: _config.routes.listRouteName,
            rbacModule: _config.table.name,
            entityByIdProvider: agencyBrandLinkByIdProvider,
            adapterProvider: entityAdapterProvider,
            onSave: (ref, fieldValues, id) async {
              final service = ref.read(entityServiceProvider);
              try {
                if (id != null) {
                  // Convert Map to ModelAgencyBrandLink for update
                  final updateData =
                      AgencyBrandLinkController.convertToModelAgencyBrandLink(
                        fieldValues,
                      );
                  await service.update(id, updateData);
                } else {
                  // Convert Map to ModelAgencyBrandLink for create
                  final createData =
                      AgencyBrandLinkController.convertToModelAgencyBrandLink(
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
        'AgencyBrandLinksRoutesJson not initialized. Call initialize() first.',
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
  static String get agencyBrandLinks => _config.routes.listPath;
  static String get newAgencyBrandLink => _config.routes.newPath;
  static String editAgencyBrandLinkRoute(String id) =>
      _config.routes.editRoute(id);
  static String viewAgencyBrandLinkRoute(String id) =>
      _config.routes.viewRoute(id);
}

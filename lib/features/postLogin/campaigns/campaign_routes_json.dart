import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'ui/campaign_list_by_shop_id.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/route_permission.dart';
import '../../../core/services/rbac_service.dart';

import '../../../core/config/module_config.dart';
import '../../../core/routing/module_route_generator.dart';
import '../../../core/services/entity_service.dart';
import 'model/campaign_model.dart';
import 'providers/campaign_providers.dart';
import 'ui/campaign_list_tile.dart';
import 'ui/campaign_list_page_riverpod.dart';

/// JSON-based route generation for Campaigns module
/// Fully migrated to Riverpod - no GetIt dependency
/// Strategy: Listen to campaign table, read from view_campaigns
/// Real-time sync enabled via Supabase Realtime subscriptions
class CampaignsRoutesJson {
  static late ModuleConfig _config;
  static bool _initialized = false;

  /// Initialize and load JSON configuration
  static Future<void> initialize() async {
    if (_initialized) return;

    // Load configuration from JSON file
    _config = await ModuleConfig.loadFromAsset(
      'lib/features/postLogin/campaigns/campaign_config.json',
    );

    // Cache the configuration so providers can access it
    CampaignConfigCache.config = _config;

    // Create typed provider aliases
    final entityServiceProvider = Provider<EntityService<ModelCampaign>>((ref) {
      return ref.watch(campaignServiceProvider);
    });

    final entityAdapterProvider = Provider<EntityAdapter<ModelCampaign>>((ref) {
      return ref.watch(campaignAdapterProvider);
    });

    // Sorting is now configured in the list page's initState() method
    // This ensures it's set on the correct Riverpod provider service instance

    // Register module with route generator
    ModuleRouteRegistry.registerModule<ModelCampaign>(
      config: _config,
      serviceProvider: entityServiceProvider,
      adapterProvider: entityAdapterProvider,
      streamProvider: campaignsStreamProvider,
      entityByIdProvider: campaignByIdProvider,
      formProvider: campaignFormProvider,
      customItemBuilder: (context, entity, adapter, onTap) {
        return CampaignListTile(entity: entity, adapter: adapter, onTap: onTap);
      },
      customListBuilder: (context, state) {
        final filterShopId = state.uri.queryParameters['filterShopId'];

        if (filterShopId != null) {
          return CampaignListByShopId(
            entityMeta: _config.entityMeta,
            idField: _config.table.idField,
            fieldConfigs: _config.fields,
            timestampField: _config.table.timestampField,
            viewRouteName: _config.routes.viewRouteName,
            newRouteName: _config.routes.newRouteName,
            rbacModule: _config.table.name,
            searchFields: _config.listPage?.searchFields,
            initialSorting: _config.listPage?.sorting,
          );
        }

        return CampaignListPageRiverpod(
          entityMeta: _config.entityMeta,
          idField: _config.table.idField,
          fieldConfigs: _config.fields,
          timestampField: _config.table.timestampField,
          viewRouteName: _config.routes.viewRouteName,
          newRouteName: _config.routes.newRouteName,
          rbacModule: _config.table.name,
          searchFields: _config.listPage?.searchFields,
          initialSorting: _config.listPage?.sorting,
        );
      },
    );

    // Register manual routes for RBAC
    ModuleRouteRegistry.registerRoutePermission(
      'campaign_collection',
      RoutePermission(moduleId: 'campaign', action: RbacAction.update),
    );

    _initialized = true;
  }

  /// Get routes (call after initialize)
  static List<GoRoute> get routes {
    if (!_initialized) {
      throw StateError(
        'CampaignRoutesJson not initialized. Call initialize() first.',
      );
    }
    return ModuleRouteRegistry.routes
        .where((route) => route.path.startsWith(_config.routes.basePath))
        .toList();
  }

  /// Helper properties to access route names
  static String get listRouteName => _config.routes.listRouteName;
  static String get newRouteName => _config.routes.newRouteName;
  static String get editRouteName => _config.routes.editRouteName;
  static String get viewRouteName => _config.routes.viewRouteName;

  /// Route paths
  static String get campaigns => _config.routes.listPath;
  static String get newCampaign => _config.routes.newPath;
  static String editCampaignRoute(String id) => _config.routes.editRoute(id);
  static String viewCampaignRoute(String id) => _config.routes.viewRoute(id);

  /* /// Helper methods to generate route paths
  static String get listPath => _config.routes.basePath;
  static String newPath() => '${_config.routes.basePath}/new';
  static String editPath(String poId) =>
      '${_config.routes.basePath}/$poId/edit';
  static String viewPath(String poId) => '${_config.routes.basePath}/$poId'; */
}

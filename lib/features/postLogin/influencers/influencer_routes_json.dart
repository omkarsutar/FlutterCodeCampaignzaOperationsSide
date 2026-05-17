import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/module_config.dart';
import '../../../core/routing/module_route_generator.dart';
import '../../../core/services/entity_service.dart';
import 'model/influencer_model.dart';
import 'providers/influencer_providers.dart';
import 'ui/influencer_list_page_riverpod.dart';
import 'ui/influencer_view_page_riverpod.dart';

/// JSON-based route generation for Influencers module
/// Fully migrated to Riverpod - no GetIt dependency
class InfluencerRoutesJson {
  static late ModuleConfig _config;
  static bool _initialized = false;

  /// Initialize and load JSON configuration
  static Future<void> initialize() async {
    if (_initialized) return;

    // Load configuration from JSON file
    _config = await ModuleConfig.loadFromAsset(
      'lib/features/postLogin/influencers/influencer_config.json',
    );

    // Create typed provider aliases
    final entityServiceProvider = Provider<EntityService<ModelInfluencer>>((ref) {
      return ref.watch(influencerServiceProvider);
    });

    final entityAdapterProvider = Provider<EntityAdapter<ModelInfluencer>>((ref) {
      return ref.watch(influencerAdapterProvider);
    });

    // Sorting is now configured in the list page's initState() method

    // Register module with route generator
    ModuleRouteRegistry.registerModule<ModelInfluencer>(
      config: _config,
      serviceProvider: entityServiceProvider,
      adapterProvider: entityAdapterProvider,
      streamProvider: influencersStreamProvider,
      entityByIdProvider: influencerByIdProvider,
      formProvider: influencerFormProvider,
      customListBuilder: (context, state) {
        final isSelectionMode =
            state.uri.queryParameters['selection'] == 'true';
        return InfluencerListPageRiverpod(
          entityMeta: _config.entityMeta,
          idField: _config.table.idField,
          viewRouteName: _config.routes.viewRouteName,
          fieldConfigs: _config.fields,
          streamProvider: influencersStreamProvider,
          adapterProvider: entityAdapterProvider,
          serviceProvider: entityServiceProvider,
          newRouteName: _config.routes.newRouteName,
          rbacModule: _config.table.name,
          timestampField: _config.table.timestampField,
          searchFields: _config.listPage?.searchFields,
          isSelectionMode: isSelectionMode,
          initialSorting: _config.listPage?.sorting,
        );
      },
      customViewBuilder: (context, entityId) {
        return InfluencerViewPageRiverpod(entityId: entityId);
      },
    );

    _initialized = true;
  }

  /// Get routes (call after initialize)
  static List<GoRoute> get routes {
    if (!_initialized) {
      throw StateError(
        'InfluencerRoutesJson not initialized. Call initialize() first.',
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
  static String get influencers => _config.routes.listPath;
  static String get newInfluencer => _config.routes.newPath;
  static String editInfluencerRoute(String id) => _config.routes.editRoute(id);
  static String viewInfluencerRoute(String id) => _config.routes.viewRoute(id);
}
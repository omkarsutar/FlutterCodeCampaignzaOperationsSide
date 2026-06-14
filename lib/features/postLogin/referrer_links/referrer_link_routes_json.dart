import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/module_config.dart';
import '../../../core/routing/module_route_generator.dart';
import '../../../core/services/entity_service.dart';
import 'model/referrer_link_model.dart';
import 'providers/referrer_link_providers.dart';

/// JSON-based route generation for Referrer Links module
/// Fully migrated to Riverpod - no GetIt dependency
class ReferrerLinksRoutesJson {
  static late ModuleConfig _config;
  static bool _initialized = false;

  /// Initialize and load JSON configuration
  static Future<void> initialize() async {
    if (_initialized) return;

    // Load configuration from JSON file
    _config = await ModuleConfig.loadFromAsset(
      'lib/features/postLogin/referrer_links/referrer_link_config.json',
    );

    // Create typed provider aliases
    final entityServiceProvider = Provider<EntityService<ModelReferrerLink>>((
      ref,
    ) {
      return ref.watch(referrerLinkServiceProvider);
    });

    final entityAdapterProvider = Provider<EntityAdapter<ModelReferrerLink>>((
      ref,
    ) {
      return ref.watch(referrerLinkAdapterProvider);
    });

    // Sorting is now configured in the list page's initState() method

    // Register module with route generator
    ModuleRouteRegistry.registerModule<ModelReferrerLink>(
      config: _config,
      serviceProvider: entityServiceProvider,
      adapterProvider: entityAdapterProvider,
      streamProvider: referrerLinksStreamProvider,
      entityByIdProvider: referrerLinkByIdProvider,
      formProvider: referrerLinkFormProvider,
    );

    _initialized = true;
  }

  /// Get routes (call after initialize)
  static List<GoRoute> get routes {
    if (!_initialized) {
      throw StateError(
        'ReferrerLinksRoutesJson not initialized. Call initialize() first.',
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
  static String get referrerLinksPath => _config.routes.listPath;
  static String get newReferrerLink => _config.routes.newPath;
  static String editReferrerLinkRoute(String id) =>
      _config.routes.editRoute(id);
  static String viewReferrerLinkRoute(String id) =>
      _config.routes.viewRoute(id);
}

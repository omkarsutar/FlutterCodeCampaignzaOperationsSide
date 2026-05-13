import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/module_config.dart';
import '../../../core/routing/module_route_generator.dart';
import '../../../core/services/entity_service.dart';
import 'model/agency_model.dart';
import 'providers/agency_providers.dart';

/// JSON-based route generation for Agency module
/// Fully migrated to Riverpod - no GetIt dependency
class AgenciesRoutesJson {
  static late ModuleConfig _config;
  static bool _initialized = false;

  /// Initialize and load JSON configuration
  static Future<void> initialize() async {
    if (_initialized) return;

    // Load configuration from JSON file
    _config = await ModuleConfig.loadFromAsset(
      'lib/features/postLogin/agencies/agency_config.json',
    );

    // Create typed provider aliases
    final entityServiceProvider = Provider<EntityService<ModelAgency>>((ref) {
      return ref.watch(agencyServiceProvider);
    });

    final entityAdapterProvider = Provider<EntityAdapter<ModelAgency>>((ref) {
      return ref.watch(agencyAdapterProvider);
    });

    // Sorting is now configured in the list page's initState() method

    // Register module with route generator
    ModuleRouteRegistry.registerModule<ModelAgency>(
      config: _config,
      serviceProvider: entityServiceProvider,
      adapterProvider: entityAdapterProvider,
      streamProvider: agenciesStreamProvider,
      entityByIdProvider: agencyByIdProvider,
      formProvider: agencyFormProvider,
    );

    _initialized = true;
  }

  /// Get routes (call after initialize)
  static List<GoRoute> get routes {
    if (!_initialized) {
      throw StateError(
        'AgenciesRoutesJson not initialized. Call initialize() first.',
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
  static String get agenciesPath => _config.routes.listPath;
  static String get newAgency => _config.routes.newPath;
  static String editAgencyRoute(String id) => _config.routes.editRoute(id);
  static String viewAgencyRoute(String id) => _config.routes.viewRoute(id);
}

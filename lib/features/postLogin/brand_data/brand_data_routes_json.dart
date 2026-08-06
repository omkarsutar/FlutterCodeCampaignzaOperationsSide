import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/module_config.dart';
import '../../../core/routing/module_route_generator.dart';
import '../../../core/services/entity_service.dart';
import 'model/brand_data_model.dart';
import 'providers/brand_data_providers.dart';

/// JSON-based route generation for Brand Data module
class BrandDataRoutesJson {
  static late ModuleConfig _config;
  static bool _initialized = false;

  /// Initialize and load JSON configuration
  static Future<void> initialize() async {
    if (_initialized) return;

    _config = await ModuleConfig.loadFromAsset(
      'lib/features/postLogin/brand_data/brand_data_config.json',
    );

    final entityServiceProvider = Provider<EntityService<ModelBrandData>>((
      ref,
    ) {
      return ref.watch(brandDataServiceProvider);
    });

    final entityAdapterProvider = Provider<EntityAdapter<ModelBrandData>>((
      ref,
    ) {
      return ref.watch(brandDataAdapterProvider);
    });

    ModuleRouteRegistry.registerModule<ModelBrandData>(
      config: _config,
      serviceProvider: entityServiceProvider,
      adapterProvider: entityAdapterProvider,
      streamProvider: brandDataStreamProvider,
      entityByIdProvider: brandDataByIdProvider,
      formProvider: brandDataFormProvider,
    );

    _initialized = true;
  }

  /// Get routes (call after initialize)
  static List<GoRoute> get routes {
    if (!_initialized) {
      throw StateError(
        'BrandDataRoutesJson not initialized. Call initialize() first.',
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
  static String get brandData => _config.routes.listPath;
  static String get newBrandData => _config.routes.newPath;
  static String editBrandDataRoute(String id) => _config.routes.editRoute(id);
  static String viewBrandDataRoute(String id) => _config.routes.viewRoute(id);
}

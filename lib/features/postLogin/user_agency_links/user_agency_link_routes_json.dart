import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/module_config.dart';
import '../../../core/routing/module_route_generator.dart';
import '../../../core/services/entity_service.dart';
import 'model/user_agency_link_model.dart';
import 'providers/user_agency_link_providers.dart';
import 'ui/user_agency_link_list_tile.dart';
import 'ui/user_agency_link_view_page_riverpod.dart';
import 'ui/user_agency_link_form_page.dart';

/// JSON-based route generation for User Agency Link Module
class UserAgencyLinkRoutesJson {
  static late ModuleConfig _config;
  static bool _initialized = false;

  /// Initialize and load JSON configuration
  static Future<void> initialize() async {
    if (_initialized) return;

    // Load configuration from JSON file
    _config = await ModuleConfig.loadFromAsset(
      'lib/features/postLogin/user_agency_links/user_agency_link_config.json',
    );

    // Create typed provider aliases
    final entityServiceProvider = Provider<EntityService<ModelUserAgencyLink>>((
      ref,
    ) {
      return ref.watch(userAgencyLinkServiceProvider);
    });

    final entityAdapterProvider = Provider<EntityAdapter<ModelUserAgencyLink>>((
      ref,
    ) {
      return ref.watch(userAgencyLinkAdapterProvider);
    });

    // Register module with route generator
    ModuleRouteRegistry.registerModule<ModelUserAgencyLink>(
      config: _config,
      serviceProvider: entityServiceProvider,
      adapterProvider: entityAdapterProvider,
      streamProvider: userAgencyLinksStreamProvider,
      entityByIdProvider: userAgencyLinkByIdProvider,
      formProvider: userAgencyLinkFormProvider,
      customItemBuilder: (context, entity, adapter, onTap) =>
          UserAgencyLinkListTile(
            entity: entity,
            adapter: adapter,
            onTap: onTap,
          ),
      customFormBuilder: (context, entityId) =>
          UserAgencyLinkFormPage<ModelUserAgencyLink>(
            entityId: entityId,
            entityMeta: _config.entityMeta,
            fieldConfigs: _config.fields,
            listRouteName: _config.routes.listRouteName,
            rbacModule: _config.table.name,
            entityByIdProvider: userAgencyLinkByIdProvider,
            adapterProvider: entityAdapterProvider,
            onSave: (ref, fieldValues, id) async {
              final notifier = ref.read(userAgencyLinkFormProvider.notifier);
              // Update fields
              for (final field in _config.fields) {
                if (fieldValues.containsKey(field.name)) {
                  notifier.updateField(field.name, fieldValues[field.name]);
                }
              }
              return await notifier.save(entityId: id);
            },
          ),
      customViewBuilder: (context, entityId) =>
          UserAgencyLinkViewPageRiverpod<ModelUserAgencyLink>(
            entityId: entityId,
            entityMeta: _config.entityMeta,
            fieldConfigs: _config.fields,
            idField: _config.table.idField,
            timestampField: _config.table.timestampField,
            editRouteName: _config.routes.editRouteName,
            rbacModule: _config.table.name,
            entityByIdProvider: userAgencyLinkByIdProvider,
            adapterProvider: entityAdapterProvider,
            deleteFunction: (ref, id) async {
              final notifier = ref.read(userAgencyLinkFormProvider.notifier);
              return await notifier.delete(id);
            },
          ),
    );

    _initialized = true;
  }

  /// Get routes (call after initialize)
  static List<GoRoute> get routes {
    if (!_initialized) {
      throw StateError(
        'UserAgencyLinkRoutesJson not initialized. Call initialize() first.',
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
  static String get userAgencyLinksPath => _config.routes.listPath;
}

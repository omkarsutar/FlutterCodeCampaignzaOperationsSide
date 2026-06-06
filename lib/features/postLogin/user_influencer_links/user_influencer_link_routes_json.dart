import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/module_config.dart';
import '../../../core/routing/module_route_generator.dart';
import '../../../core/services/entity_service.dart';
import 'model/user_influencer_link_model.dart';
import 'providers/user_influencer_link_providers.dart';
import 'ui/user_influencer_link_list_tile.dart';
import 'ui/user_influencer_link_view_page_riverpod.dart';
import 'ui/user_influencer_link_form_page.dart';

/// JSON-based route generation for User Influencer Link Module
class UserInfluencerLinkRoutesJson {
  static late ModuleConfig _config;
  static bool _initialized = false;

  /// Initialize and load JSON configuration
  static Future<void> initialize() async {
    if (_initialized) return;

    // Load configuration from JSON file
    _config = await ModuleConfig.loadFromAsset(
      'lib/features/postLogin/user_influencer_links/user_influencer_link_config.json',
    );

    // Create typed provider aliases
    final entityServiceProvider =
        Provider<EntityService<ModelUserInfluencerLink>>((ref) {
          return ref.watch(userInfluencerLinkServiceProvider);
        });

    final entityAdapterProvider =
        Provider<EntityAdapter<ModelUserInfluencerLink>>((ref) {
          return ref.watch(userInfluencerLinkAdapterProvider);
        });

    // Register module with route generator
    ModuleRouteRegistry.registerModule<ModelUserInfluencerLink>(
      config: _config,
      serviceProvider: entityServiceProvider,
      adapterProvider: entityAdapterProvider,
      streamProvider: userInfluencerLinksStreamProvider,
      entityByIdProvider: userInfluencerLinkByIdProvider,
      formProvider: userInfluencerLinkFormProvider,
      customItemBuilder: (context, entity, adapter, onTap) =>
          UserInfluencerLinkListTile(
            entity: entity,
            adapter: adapter,
            onTap: onTap,
          ),
      customFormBuilder: (context, entityId) =>
          UserInfluencerLinkFormPage<ModelUserInfluencerLink>(
            entityId: entityId,
            entityMeta: _config.entityMeta,
            fieldConfigs: _config.fields,
            listRouteName: _config.routes.listRouteName,
            rbacModule: _config.table.name,
            entityByIdProvider: userInfluencerLinkByIdProvider,
            adapterProvider: entityAdapterProvider,
            onSave: (ref, fieldValues, id) async {
              final notifier = ref.read(
                userInfluencerLinkFormProvider.notifier,
              );
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
          UserInfluencerLinkViewPageRiverpod<ModelUserInfluencerLink>(
            entityId: entityId,
            entityMeta: _config.entityMeta,
            fieldConfigs: _config.fields,
            idField: _config.table.idField,
            timestampField: _config.table.timestampField,
            editRouteName: _config.routes.editRouteName,
            rbacModule: _config.table.name,
            entityByIdProvider: userInfluencerLinkByIdProvider,
            adapterProvider: entityAdapterProvider,
            deleteFunction: (ref, id) async {
              final notifier = ref.read(
                userInfluencerLinkFormProvider.notifier,
              );
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
        'UserInfluencerLinkRoutesJson not initialized. Call initialize() first.',
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
  static String get userInfluencerLinksPath => _config.routes.listPath;
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../../core/services/entity_service.dart';

import '../../../../core/config/module_config.dart';

import '../adapter/route_brand_link_adapter.dart';
import '../model/route_brand_link_model.dart';
import '../service/route_brand_link_service_impl.dart';

/// Mapper provider
final routeBrandLinkMapperProvider =
    Provider<EntityMapper<ModelRouteBrandLink>>((ref) {
      return ModelRouteBrandLinkMapper();
    });

/// Cache for module configuration to avoid circular dependencies
class RouteBrandLinkConfigCache {
  static ModuleConfig? config;
}

/// Service provider
final routeBrandLinkServiceProvider = Provider<RouteBrandLinkServiceImpl>((
  ref,
) {
  // Extract initial sorting from cached config if available
  final initialSorting = RouteBrandLinkConfigCache.config?.listPage?.sorting;

  return RouteBrandLinkServiceImpl(
    ref.watch(routeBrandLinkMapperProvider),
    ref.watch(supabaseClientProvider),
    ref.watch(loggerServiceProvider),
    initialSorting: initialSorting,
  );
});

/// Adapter provider
final routeBrandLinkAdapterProvider = Provider<RouteBrandLinkAdapter>((ref) {
  return RouteBrandLinkAdapter();
});

/// Fetches all route-brand links with automatic disposal
/// Uses StreamProvider for real-time updates
final routeBrandLinksStreamProvider =
    StreamProvider.autoDispose<List<ModelRouteBrandLink>>((ref) {
      final service = ref.read(routeBrandLinkServiceProvider);
      return service.streamEntities();
    });

/// Fetches a single route-brand link by ID
final routeBrandLinkByIdProvider = FutureProvider.autoDispose
    .family<ModelRouteBrandLink?, String>((ref, linkId) async {
      final service = ref.read(routeBrandLinkServiceProvider);
      return await service.fetchById(linkId);
    });

/// Fetches route-brand links for a specific route ID using the view/RPC
final routeBrandLinksByRouteProvider = StreamProvider.autoDispose
    .family<List<ModelRouteBrandLink>, String>((ref, routeId) {
      final service = ref.read(routeBrandLinkServiceProvider);
      return service.streamEntitiesByRoute(routeId);
    });

/// State provider for managing route-brand link creation/editing
final routeBrandLinkFormProvider =
    StateNotifierProvider.autoDispose<
      RouteBrandLinkFormNotifier,
      RouteBrandLinkFormState
    >((ref) => RouteBrandLinkFormNotifier(ref));

/// Form state for route-brand link
class RouteBrandLinkFormState {
  final String? routeId;
  final String? brandId;
  final int? visitOrder;
  final bool isLoading;
  final String? error;

  RouteBrandLinkFormState({
    this.routeId,
    this.brandId,
    this.visitOrder,
    this.isLoading = false,
    this.error,
  });

  RouteBrandLinkFormState copyWith({
    String? routeId,
    String? brandId,
    int? visitOrder,
    bool? isLoading,
    String? error,
  }) {
    return RouteBrandLinkFormState(
      routeId: routeId ?? this.routeId,
      brandId: brandId ?? this.brandId,
      visitOrder: visitOrder ?? this.visitOrder,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Notifier for managing route-brand link form state
class RouteBrandLinkFormNotifier
    extends StateNotifier<RouteBrandLinkFormState> {
  final Ref ref;

  RouteBrandLinkFormNotifier(this.ref) : super(RouteBrandLinkFormState());

  bool _mounted = true;

  @override
  void dispose() {
    _mounted = false;
    super.dispose();
  }

  void updateRouteId(String routeId) {
    if (!_mounted) return;
    state = state.copyWith(routeId: routeId, error: null);
  }

  void updateBrandId(String brandId) {
    if (!_mounted) return;
    state = state.copyWith(brandId: brandId, error: null);
  }

  void updateVisitOrder(int visitOrder) {
    if (!_mounted) return;
    state = state.copyWith(visitOrder: visitOrder, error: null);
  }

  Future<bool> saveEntity({String? entityId}) async {
    if (!_mounted) return false;
    if (state.routeId == null || state.brandId == null) {
      state = state.copyWith(error: 'Route and Brand must be selected');
      return false;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final service = ref.read(routeBrandLinkServiceProvider);
      final entity = ModelRouteBrandLink(
        linkId: entityId,
        routeId: state.routeId!,
        brandId: state.brandId!,
        visitOrder: state.visitOrder,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (entityId == null) {
        // Create new entity
        await service.create(entity);
      } else {
        // Update existing entity
        await service.update(entityId, entity);
      }

      if (!_mounted) return true;
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      if (!_mounted) return false;
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to save route-brand link: $e',
      );
      return false;
    }
  }

  Future<bool> deleteEntity(String entityId) async {
    if (!_mounted) return false;
    state = state.copyWith(isLoading: true, error: null);

    try {
      final service = ref.read(routeBrandLinkServiceProvider);
      await service.delete(entityId);
      if (!_mounted) return true;
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      if (!_mounted) return false;
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to delete route-brand link: $e',
      );
      return false;
    }
  }

  void loadEntity(ModelRouteBrandLink entity) {
    if (!_mounted) return;
    state = state.copyWith(
      routeId: entity.routeId,
      brandId: entity.brandId,
      visitOrder: entity.visitOrder,
    );
  }

  void reset() {
    if (!_mounted) return;
    state = RouteBrandLinkFormState();
  }

  /// Generic update method for ModuleRouteGenerator
  void updateField(String field, dynamic value) {
    if (!_mounted) return;
    switch (field) {
      case ModelRouteBrandLinkFields.routeId:
        updateRouteId(value as String);
        break;
      case ModelRouteBrandLinkFields.brandId:
        updateBrandId(value as String);
        break;
      case ModelRouteBrandLinkFields.visitOrder:
        final intValue = value == null
            ? null
            : (value is int ? value : int.tryParse(value.toString()));
        if (intValue != null) {
          updateVisitOrder(intValue);
        }
        break;
    }
  }

  /// Generic save method for ModuleRouteGenerator
  Future<bool> save({String? entityId}) => saveEntity(entityId: entityId);

  /// Generic delete method for ModuleRouteGenerator
  Future<bool> delete(String id) => deleteEntity(id);
}

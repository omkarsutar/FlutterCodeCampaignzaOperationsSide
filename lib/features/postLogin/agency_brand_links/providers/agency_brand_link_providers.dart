import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../../core/services/entity_service.dart';

import '../../../../core/config/module_config.dart';

import '../adapter/agency_brand_link_adapter.dart';
import '../model/agency_brand_link_model.dart';
import '../service/agency_brand_link_service_impl.dart';

/// Mapper provider
final agencyBrandLinkMapperProvider =
    Provider<EntityMapper<ModelAgencyBrandLink>>((ref) {
      return ModelAgencyBrandLinkMapper();
    });

/// Cache for module configuration to avoid circular dependencies
class AgencyBrandLinkConfigCache {
  static ModuleConfig? config;
}

/// Service provider
final agencyBrandLinkServiceProvider = Provider<AgencyBrandLinkServiceImpl>((
  ref,
) {
  // Extract initial sorting from cached config if available
  final initialSorting = AgencyBrandLinkConfigCache.config?.listPage?.sorting;

  return AgencyBrandLinkServiceImpl(
    ref.watch(agencyBrandLinkMapperProvider),
    ref.watch(supabaseClientProvider),
    ref.watch(loggerServiceProvider),
    initialSorting: initialSorting,
  );
});

/// Adapter provider
final agencyBrandLinkAdapterProvider = Provider<AgencyBrandLinkAdapter>((ref) {
  return AgencyBrandLinkAdapter();
});

/// Fetches all agency-brand links with automatic disposal
/// Uses StreamProvider for real-time updates
final agencyBrandLinksStreamProvider =
    StreamProvider.autoDispose<List<ModelAgencyBrandLink>>((ref) {
      final service = ref.read(agencyBrandLinkServiceProvider);
      return service.streamEntities();
    });

/// Fetches a single agency-brand link by ID
final agencyBrandLinkByIdProvider = FutureProvider.autoDispose
    .family<ModelAgencyBrandLink?, String>((ref, linkId) async {
      final service = ref.read(agencyBrandLinkServiceProvider);
      return await service.fetchById(linkId);
    });

/// Fetches agency-brand links for a specific agency ID using the view/RPC
final agencyBrandLinksByAgencyProvider = StreamProvider.autoDispose
    .family<List<ModelAgencyBrandLink>, String>((ref, agencyId) {
      final service = ref.read(agencyBrandLinkServiceProvider);
      return service.streamEntitiesByRoute(agencyId);
    });

/// State provider for managing agency-brand link creation/editing
final agencyBrandLinkFormProvider =
    StateNotifierProvider.autoDispose<
      AgencyBrandLinkFormNotifier,
      AgencyBrandLinkFormState
    >((ref) => AgencyBrandLinkFormNotifier(ref));

/// Form state for agency-brand link
class AgencyBrandLinkFormState {
  final String? agencyId;
  final String? brandId;
  final int? visitOrder;
  final bool isLoading;
  final String? error;

  AgencyBrandLinkFormState({
    this.agencyId,
    this.brandId,
    this.visitOrder,
    this.isLoading = false,
    this.error,
  });

  AgencyBrandLinkFormState copyWith({
    String? agencyId,
    String? brandId,
    int? visitOrder,
    bool? isLoading,
    String? error,
  }) {
    return AgencyBrandLinkFormState(
      agencyId: agencyId ?? this.agencyId,
      brandId: brandId ?? this.brandId,
      visitOrder: visitOrder ?? this.visitOrder,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Notifier for managing agency-brand link form state
class AgencyBrandLinkFormNotifier
    extends StateNotifier<AgencyBrandLinkFormState> {
  final Ref ref;

  AgencyBrandLinkFormNotifier(this.ref) : super(AgencyBrandLinkFormState());

  bool _mounted = true;

  @override
  void dispose() {
    _mounted = false;
    super.dispose();
  }

  void updateAgencyId(String agencyId) {
    if (!_mounted) return;
    state = state.copyWith(agencyId: agencyId, error: null);
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
    if (state.agencyId == null || state.brandId == null) {
      state = state.copyWith(error: 'Agency and Brand must be selected');
      return false;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final service = ref.read(agencyBrandLinkServiceProvider);
      final entity = ModelAgencyBrandLink(
        linkId: entityId,
        agencyId: state.agencyId!,
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
        error: 'Failed to save agency-brand link: $e',
      );
      return false;
    }
  }

  Future<bool> deleteEntity(String entityId) async {
    if (!_mounted) return false;
    state = state.copyWith(isLoading: true, error: null);

    try {
      final service = ref.read(agencyBrandLinkServiceProvider);
      await service.deleteEntityById(entityId);
      if (!_mounted) return true;
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      if (!_mounted) return false;
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to delete agency-brand link: $e',
      );
      return false;
    }
  }

  void loadEntity(ModelAgencyBrandLink entity) {
    if (!_mounted) return;
    state = state.copyWith(
      agencyId: entity.agencyId,
      brandId: entity.brandId,
      visitOrder: entity.visitOrder,
    );
  }

  void reset() {
    if (!_mounted) return;
    state = AgencyBrandLinkFormState();
  }

  /// Generic update method for ModuleRouteGenerator
  void updateField(String field, dynamic value) {
    if (!_mounted) return;
    switch (field) {
      case ModelAgencyBrandLinkFields.agencyId:
        updateAgencyId(value as String);
        break;
      case ModelAgencyBrandLinkFields.brandId:
        updateBrandId(value as String);
        break;
      case ModelAgencyBrandLinkFields.visitOrder:
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

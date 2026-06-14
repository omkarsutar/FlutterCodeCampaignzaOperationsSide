import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../../core/services/entity_service.dart';
import '../adapter/referrer_link_adapter.dart';
import '../model/referrer_link_model.dart';
import '../service/referrer_link_service_impl.dart';

/// Mapper provider
final referrerLinkMapperProvider = Provider<EntityMapper<ModelReferrerLink>>((
  ref,
) {
  return ModelReferrerLinkMapper();
});

/// Service provider
final referrerLinkServiceProvider = Provider<ReferrerLinkServiceImpl>((ref) {
  return ReferrerLinkServiceImpl(
    ref.watch(referrerLinkMapperProvider),
    ref.watch(supabaseClientProvider),
    ref.watch(loggerServiceProvider),
  );
});

/// Adapter provider
final referrerLinkAdapterProvider = Provider<ReferrerLinkAdapter>((ref) {
  return ReferrerLinkAdapter();
});

/// Fetches all Referrer Links with automatic disposal
/// Uses StreamProvider for real-time updates
final referrerLinksStreamProvider =
    StreamProvider.autoDispose<List<ModelReferrerLink>>((ref) {
      final service = ref.read(referrerLinkServiceProvider);
      return service.streamEntities();
    });

/// Fetches a single Referrer Link by ID
final referrerLinkByIdProvider = FutureProvider.autoDispose
    .family<ModelReferrerLink?, String>((ref, moduleId) async {
      final service = ref.read(referrerLinkServiceProvider);
      return await service.fetchById(moduleId);
    });

/// State provider for managing Referrer Link creation/editing
final referrerLinkFormProvider =
    StateNotifierProvider.autoDispose<
      ReferrerLinkFormNotifier,
      ReferrerLinkFormState
    >((ref) => ReferrerLinkFormNotifier(ref));

/// Form state for Referrer Link
class ReferrerLinkFormState {
  final String moduleName;
  final String moduleDescription;
  final bool isActive;
  final bool isLoading;
  final String? error;

  ReferrerLinkFormState({
    this.moduleName = '',
    this.moduleDescription = '',
    this.isActive = true,
    this.isLoading = false,
    this.error,
  });

  ReferrerLinkFormState copyWith({
    String? moduleName,
    String? moduleDescription,
    bool? isActive,
    bool? isLoading,
    String? error,
  }) {
    return ReferrerLinkFormState(
      moduleName: moduleName ?? this.moduleName,
      moduleDescription: moduleDescription ?? this.moduleDescription,
      isActive: isActive ?? this.isActive,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Notifier for managing Referrer Link form state
class ReferrerLinkFormNotifier extends StateNotifier<ReferrerLinkFormState> {
  final Ref ref;

  ReferrerLinkFormNotifier(this.ref) : super(ReferrerLinkFormState());

  @override
  void dispose() {
    _mounted = false;
    super.dispose();
  }

  bool _mounted = true;

  void updateModuleName(String name) {
    if (!_mounted) return;
    state = state.copyWith(moduleName: name, error: null);
  }

  void updateModuleDescription(String description) {
    if (!_mounted) return;
    state = state.copyWith(moduleDescription: description, error: null);
  }

  void updateIsActive(bool isActive) {
    if (!_mounted) return;
    state = state.copyWith(isActive: isActive, error: null);
  }

  void loadEntity(ModelReferrerLink entity) {
    if (!_mounted) return;
    state = ReferrerLinkFormState(
      moduleName: entity.moduleName,
      moduleDescription: entity.moduleDescription ?? '',
      isActive: entity.isActive,
    );
  }

  Future<bool> saveEntity({String? entityId}) async {
    if (!_mounted) return false;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final service = ref.read(referrerLinkServiceProvider);

      final entity = ModelReferrerLink(
        moduleId: entityId,
        moduleName: state.moduleName,
        moduleDescription: state.moduleDescription.isEmpty
            ? null
            : state.moduleDescription,
        isActive: state.isActive,
      );

      if (entityId == null) {
        // Create new
        await service.create(entity);
      } else {
        // Update existing
        await service.update(entityId, entity);
      }

      if (_mounted) {
        state = state.copyWith(isLoading: false);
      }
      return true;
    } catch (e) {
      if (_mounted) {
        state = state.copyWith(isLoading: false, error: e.toString());
      }
      return false;
    }
  }

  Future<bool> deleteEntity(String entityId) async {
    if (!_mounted) return false;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final service = ref.read(referrerLinkServiceProvider);
      await service.deleteEntityById(entityId);

      if (_mounted) {
        state = state.copyWith(isLoading: false);
      }
      return true;
    } catch (e) {
      if (_mounted) {
        state = state.copyWith(isLoading: false, error: e.toString());
      }
      return false;
    }
  }

  /// Generic update method for ModuleRouteGenerator
  void updateField(String field, dynamic value) {
    if (!_mounted) return;
    switch (field) {
      case ModelReferrerLinkFields.moduleName:
        updateModuleName(value as String);
        break;
      case ModelReferrerLinkFields.moduleDescription:
        updateModuleDescription(value as String);
        break;
      case ModelReferrerLinkFields.isActive:
        updateIsActive(value as bool);
        break;
    }
  }

  /// Generic save method for ModuleRouteGenerator
  Future<bool> save({String? entityId}) => saveEntity(entityId: entityId);

  /// Generic delete method for ModuleRouteGenerator
  Future<bool> delete(String id) => deleteEntity(id);
}

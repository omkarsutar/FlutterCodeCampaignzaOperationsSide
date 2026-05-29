import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/auth_providers.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../../core/services/entity_service.dart';
import '../adapter/agency_adapter.dart';
import '../model/agency_model.dart';
import '../service/agency_service_impl.dart';

/// Mapper provider
final agencyMapperProvider = Provider<EntityMapper<ModelAgency>>((ref) {
  return ModelAgencyMapper();
});

/// Service provider
final agencyServiceProvider = Provider<AgencyServiceImpl>((ref) {
  return AgencyServiceImpl(
    ref.watch(agencyMapperProvider),
    ref.watch(supabaseClientProvider),
    ref.watch(loggerServiceProvider),
  );
});

/// Adapter provider
final agencyAdapterProvider = Provider<RouteAdapter>((ref) {
  return RouteAdapter();
});

/// Fetches all agencies with automatic disposal
/// Uses StreamProvider for real-time updates
final agenciesStreamProvider = StreamProvider.autoDispose<List<ModelAgency>>((
  ref,
) {
  final service = ref.read(agencyServiceProvider);
  return service.streamEntities();
});

/// Fetches a single agency by ID
final agencyByIdProvider = FutureProvider.autoDispose
    .family<ModelAgency?, String>((ref, agencyId) async {
      final service = ref.read(agencyServiceProvider);
      return await service.fetchById(agencyId);
    });

/// Provider for the current user's agency name
final currentAgencyNameProvider = FutureProvider.autoDispose<String>((
  ref,
) async {
  final userProfile = ref.watch(userProfileProvider).value;
  final agencyId = userProfile?.preferredAgencyId;
  if (agencyId == null || agencyId.isEmpty) return 'All Agencies';

  try {
    final agency = await ref.watch(agencyByIdProvider(agencyId).future);
    return agency?.agencyName ?? 'Unknown';
  } catch (e) {
    return 'Unknown';
  }
});

/// State provider for managing agency creation/editing
final agencyFormProvider =
    StateNotifierProvider.autoDispose<AgencyFormNotifier, AgencyFormState>(
      (ref) => AgencyFormNotifier(ref),
    );

/// Form state for agency
class AgencyFormState {
  final String agencyName;
  final String agencyNote;
  final bool isActive;
  final bool isLoading;
  final String? error;

  AgencyFormState({
    this.agencyName = '',
    this.agencyNote = '',
    this.isActive = true,
    this.isLoading = false,
    this.error,
  });

  AgencyFormState copyWith({
    String? agencyName,
    String? agencyNote,
    bool? isActive,
    bool? isLoading,
    String? error,
  }) {
    return AgencyFormState(
      agencyName: agencyName ?? this.agencyName,
      agencyNote: agencyNote ?? this.agencyNote,
      isActive: isActive ?? this.isActive,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Notifier for managing agency form state
class AgencyFormNotifier extends StateNotifier<AgencyFormState> {
  final Ref ref;

  AgencyFormNotifier(this.ref) : super(AgencyFormState());

  @override
  void dispose() {
    _mounted = false;
    super.dispose();
  }

  bool _mounted = true;

  void updateAgencyName(String name) {
    if (!_mounted) return;
    state = state.copyWith(agencyName: name, error: null);
  }

  void updateAgencyNote(String note) {
    if (!_mounted) return;
    state = state.copyWith(agencyNote: note, error: null);
  }

  void updateIsActive(bool isActive) {
    if (!_mounted) return;
    state = state.copyWith(isActive: isActive, error: null);
  }

  void loadEntity(ModelAgency entity) {
    if (!_mounted) return;
    state = AgencyFormState(
      agencyName: entity.agencyName,
      agencyNote: entity.agencyNote ?? '',
      isActive: entity.isActive,
    );
  }

  Future<bool> saveEntity({String? entityId}) async {
    if (!_mounted) return false;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final service = ref.read(agencyServiceProvider);

      final entity = ModelAgency(
        agencyId: entityId,
        agencyName: state.agencyName,
        agencyNote: state.agencyNote.isEmpty ? null : state.agencyNote,
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
      final service = ref.read(agencyServiceProvider);
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
      case ModelAgencyFields.agencyName:
        updateAgencyName(value as String);
        break;
      case ModelAgencyFields.agencyNote:
        updateAgencyNote(value as String);
        break;
      case ModelAgencyFields.isActive:
        updateIsActive(value as bool);
        break;
    }
  }

  /// Generic save method for ModuleRouteGenerator
  Future<bool> save({String? entityId}) => saveEntity(entityId: entityId);

  /// Generic delete method for ModuleRouteGenerator
  Future<bool> delete(String id) => deleteEntity(id);
}

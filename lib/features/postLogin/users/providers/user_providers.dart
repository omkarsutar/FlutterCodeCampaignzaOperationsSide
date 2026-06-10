import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../../core/services/entity_service.dart';
import '../adapter/user_adapter.dart';
import '../model/user_model.dart';
import '../service/user_service_impl.dart';
import '../../agencies/agency_barrel.dart';
import '../../../../core/providers/auth_providers.dart';

/// Mapper provider
final userMapperProvider = Provider<EntityMapper<ModelUser>>((ref) {
  return ModelUserMapper();
});

/// Service provider
final userServiceProvider = Provider<UserServiceImpl>((ref) {
  return UserServiceImpl(
    ref.watch(userMapperProvider),
    ref.watch(supabaseClientProvider),
    ref.watch(loggerServiceProvider),
  );
});

/// Adapter provider
final userAdapterProvider = Provider<UserAdapter>((ref) {
  return UserAdapter();
});

/// Fetches all agencies for the current user
final userAgenciesProvider = FutureProvider.autoDispose<List<ModelAgency>>((
  ref,
) async {
  final user = ref.watch(userProfileProvider).value;
  if (user == null) return [];

  final roleName = ref.watch(roleNameProvider);
  final isAdmin =
      roleName?.toLowerCase() == 'admin' ||
      roleName?.toLowerCase() == 'administrator';

  final client = ref.watch(supabaseClientProvider);

  if (isAdmin) {
    // Admins see all agencies in the dropdown/list
    final response = await client
        .from(ModelAgencyFields.table)
        .select(
          '${ModelAgencyFields.agencyId}, ${ModelAgencyFields.agencyName}',
        )
        .eq(ModelAgencyFields.isActive, true)
        .order(ModelAgencyFields.agencyName, ascending: true);

    return (response as List)
        .map(
          (e) => ModelAgency(
            agencyId: e[ModelAgencyFields.agencyId],
            agencyName: e[ModelAgencyFields.agencyName] ?? 'Unknown',
          ),
        )
        .toList();
  }

  // Use view_user_agency_link to avoid join ambiguity and get labels directly
  final response = await client
      .from('view_user_agency_link')
      .select('agency_id, agency_id_label')
      .eq('user_id', user.userId);

  return (response as List)
      .map(
        (e) => ModelAgency(
          agencyId: e['agency_id'],
          agencyName: e['agency_id_label'] ?? 'Unknown',
        ),
      )
      .toList();
});

/// Provider for the currently selected agency ID
/// Defaults to the first agency in userAgenciesProvider if not set
final selectedAgencyIdProvider = StateProvider<String?>((ref) {
  // If user is admin, default to null (All Agencies)
  final roleName = ref.watch(roleNameProvider);
  final isAdmin =
      roleName?.toLowerCase() == 'admin' ||
      roleName?.toLowerCase() == 'administrator';
  if (isAdmin) return null;

  final userAgencies = ref.watch(userAgenciesProvider).value;
  if (userAgencies != null && userAgencies.isNotEmpty) {
    return userAgencies.first.agencyId;
  }
  return null;
});

/// Fetches all Users with automatic disposal
/// Uses StreamProvider for real-time updates
final usersStreamProvider = StreamProvider.autoDispose<List<ModelUser>>((ref) {
  final service = ref.read(userServiceProvider);
  return service.streamEntities();
});

/// Fetches a single User by ID
final userByIdProvider = FutureProvider.autoDispose.family<ModelUser?, String>((
  ref,
  userId,
) async {
  final service = ref.read(userServiceProvider);
  return await service.fetchById(userId);
});

/// State provider for managing User creation/editing
final userFormProvider =
    StateNotifierProvider.autoDispose<UserFormNotifier, UserFormState>((ref) {
      return UserFormNotifier(ref);
    });

/// Form state for User
class UserFormState {
  final String fullName;
  final String? roleId;
  final bool isLoading;
  final String? error;

  UserFormState({
    this.fullName = '',
    this.roleId,
    this.isLoading = false,
    this.error,
  });

  UserFormState copyWith({
    String? fullName,
    String? roleId,
    bool? isLoading,
    String? error,
  }) {
    return UserFormState(
      fullName: fullName ?? this.fullName,
      roleId: roleId ?? this.roleId,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Notifier for managing User form state
class UserFormNotifier extends StateNotifier<UserFormState> {
  final Ref ref;

  UserFormNotifier(this.ref) : super(UserFormState());

  @override
  void dispose() {
    _mounted = false;
    super.dispose();
  }

  bool _mounted = true;

  void updateFullName(String name) {
    if (!_mounted) return;
    state = state.copyWith(fullName: name, error: null);
  }

  void updateRoleId(String? roleId) {
    if (!_mounted) return;
    state = state.copyWith(roleId: roleId, error: null);
  }

  /// Generic update method for ModuleRouteGenerator
  void updateField(String field, dynamic value) {
    if (!_mounted) return;
    switch (field) {
      case ModelUserFields.fullName:
        updateFullName(value as String);
        break;
      case ModelUserFields.roleId:
        updateRoleId(value as String?);
        break;
    }
  }

  Future<bool> saveEntity({String? entityId}) async {
    if (!_mounted) return false;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final service = ref.read(userServiceProvider);

      final entity = ModelUser(
        userId:
            entityId ?? '', // entityId ignored on create usually, or generated
        fullName: state.fullName,
        roleId: state.roleId,
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

  /// Generic save method for ModuleRouteGenerator
  Future<bool> save({String? entityId}) => saveEntity(entityId: entityId);

  /// Generic delete method for ModuleRouteGenerator
  Future<bool> delete(String id) async {
    if (!_mounted) return false;

    state = state.copyWith(isLoading: true, error: null);
    try {
      final service = ref.read(userServiceProvider);
      await service.deleteEntityById(id);
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
}

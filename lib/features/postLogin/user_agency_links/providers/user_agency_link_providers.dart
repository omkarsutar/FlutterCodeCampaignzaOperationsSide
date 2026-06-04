import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../../core/services/entity_service.dart';
import '../service/user_agency_link_service_impl.dart';
import '../adapter/user_agency_link_adapter.dart';
import '../model/user_agency_link_model.dart';

/// Mapper provider
final userAgencyLinkMapperProvider =
    Provider<EntityMapper<ModelUserAgencyLink>>((ref) {
      return ModelUserAgencyLinkMapper();
    });

/// Service provider
final userAgencyLinkServiceProvider = Provider<UserAgencyLinkServiceImpl>((
  ref,
) {
  return UserAgencyLinkServiceImpl(
    ref.watch(userAgencyLinkMapperProvider),
    ref.watch(supabaseClientProvider),
    ref.watch(loggerServiceProvider),
  );
});

/// Adapter provider
final userAgencyLinkAdapterProvider = Provider<UserAgencyLinkAdapter>((ref) {
  return UserAgencyLinkAdapter();
});

/// Fetches all links with automatic disposal
final userAgencyLinksStreamProvider =
    StreamProvider.autoDispose<List<ModelUserAgencyLink>>((ref) {
      final service = ref.read(userAgencyLinkServiceProvider);
      return service.streamEntities();
    });

/// Fetches a single link by ID
final userAgencyLinkByIdProvider = FutureProvider.autoDispose
    .family<ModelUserAgencyLink?, String>((ref, id) async {
      final service = ref.read(userAgencyLinkServiceProvider);
      return await service.fetchById(id);
    });

/// State provider for managing form state
final userAgencyLinkFormProvider =
    StateNotifierProvider.autoDispose<
      UserAgencyLinkFormNotifier,
      UserAgencyLinkFormState
    >((ref) {
      return UserAgencyLinkFormNotifier(ref);
    });

/// Form state
class UserAgencyLinkFormState {
  final String? userId;
  final String? agencyId;
  final bool isLoading;
  final String? error;

  UserAgencyLinkFormState({
    this.userId,
    this.agencyId,
    this.isLoading = false,
    this.error,
  });

  UserAgencyLinkFormState copyWith({
    String? userId,
    String? agencyId,
    bool? isLoading,
    String? error,
  }) {
    return UserAgencyLinkFormState(
      userId: userId ?? this.userId,
      agencyId: agencyId ?? this.agencyId,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Notifier for managing form state
class UserAgencyLinkFormNotifier
    extends StateNotifier<UserAgencyLinkFormState> {
  final Ref ref;

  UserAgencyLinkFormNotifier(this.ref) : super(UserAgencyLinkFormState());

  @override
  void dispose() {
    _mounted = false;
    super.dispose();
  }

  bool _mounted = true;

  void updateUserId(String? userId) {
    if (!_mounted) return;
    state = state.copyWith(userId: userId, error: null);
  }

  void updateAgencyId(String? agencyId) {
    if (!_mounted) return;
    state = state.copyWith(agencyId: agencyId, error: null);
  }

  /// Generic update method for ModuleRouteGenerator
  void updateField(String field, dynamic value) {
    if (!_mounted) return;
    switch (field) {
      case ModelUserAgencyLinkFields.userId:
        updateUserId(value as String?);
        break;
      case ModelUserAgencyLinkFields.agencyId:
        updateAgencyId(value as String?);
        break;
    }
  }

  Future<bool> saveEntity({String? entityId}) async {
    if (!_mounted) return false;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final service = ref.read(userAgencyLinkServiceProvider);

      // Validation
      if (state.userId == null || state.agencyId == null) {
        throw Exception('User and Agency are required');
      }

      final entity = ModelUserAgencyLink(
        linkId: entityId ?? '',
        userId: state.userId!,
        agencyId: state.agencyId!,
      );

      if (entityId == null) {
        await service.create(entity);
      } else {
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

  /// Generic delete method
  Future<bool> delete(String id) async {
    if (!_mounted) return false;
    state = state.copyWith(isLoading: true, error: null);
    try {
      final service = ref.read(userAgencyLinkServiceProvider);
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

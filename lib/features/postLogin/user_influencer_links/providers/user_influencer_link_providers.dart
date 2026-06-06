import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../../core/services/entity_service.dart';
import '../service/user_influencer_link_service_impl.dart';
import '../adapter/user_influencer_link_adapter.dart';
import '../model/user_influencer_link_model.dart';

/// Mapper provider
final userInfluencerLinkMapperProvider =
    Provider<EntityMapper<ModelUserInfluencerLink>>((ref) {
      return ModelUserInfluencerLinkMapper();
    });

/// Service provider
final userInfluencerLinkServiceProvider =
    Provider<UserInfluencerLinkServiceImpl>((ref) {
      return UserInfluencerLinkServiceImpl(
        ref.watch(userInfluencerLinkMapperProvider),
        ref.watch(supabaseClientProvider),
        ref.watch(loggerServiceProvider),
      );
    });

/// Adapter provider
final userInfluencerLinkAdapterProvider = Provider<UserInfluencerLinkAdapter>((
  ref,
) {
  return UserInfluencerLinkAdapter();
});

/// Fetches all links with automatic disposal
final userInfluencerLinksStreamProvider =
    StreamProvider.autoDispose<List<ModelUserInfluencerLink>>((ref) {
      final service = ref.read(userInfluencerLinkServiceProvider);
      return service.streamEntities();
    });

/// Fetches a single link by ID
final userInfluencerLinkByIdProvider = FutureProvider.autoDispose
    .family<ModelUserInfluencerLink?, String>((ref, id) async {
      final service = ref.read(userInfluencerLinkServiceProvider);
      return await service.fetchById(id);
    });

/// State provider for managing form state
final userInfluencerLinkFormProvider =
    StateNotifierProvider.autoDispose<
      UserInfluencerLinkFormNotifier,
      UserInfluencerLinkFormState
    >((ref) {
      return UserInfluencerLinkFormNotifier(ref);
    });

/// Form state
class UserInfluencerLinkFormState {
  final String? userId;
  final String? influencerId;
  final bool isLoading;
  final String? error;

  UserInfluencerLinkFormState({
    this.userId,
    this.influencerId,
    this.isLoading = false,
    this.error,
  });

  UserInfluencerLinkFormState copyWith({
    String? userId,
    String? influencerId,
    bool? isLoading,
    String? error,
  }) {
    return UserInfluencerLinkFormState(
      userId: userId ?? this.userId,
      influencerId: influencerId ?? this.influencerId,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Notifier for managing form state
class UserInfluencerLinkFormNotifier
    extends StateNotifier<UserInfluencerLinkFormState> {
  final Ref ref;

  UserInfluencerLinkFormNotifier(this.ref)
    : super(UserInfluencerLinkFormState());

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

  void updateInfluencerId(String? influencerId) {
    if (!_mounted) return;
    state = state.copyWith(influencerId: influencerId, error: null);
  }

  /// Generic update method for ModuleRouteGenerator
  void updateField(String field, dynamic value) {
    if (!_mounted) return;
    switch (field) {
      case ModelUserInfluencerLinkFields.userId:
        updateUserId(value as String?);
        break;
      case ModelUserInfluencerLinkFields.influencerId:
        updateInfluencerId(value as String?);
        break;
    }
  }

  Future<bool> saveEntity({String? entityId}) async {
    if (!_mounted) return false;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final service = ref.read(userInfluencerLinkServiceProvider);

      // Validation
      if (state.userId == null || state.influencerId == null) {
        throw Exception('User and Influencer are required');
      }

      final entity = ModelUserInfluencerLink(
        linkId: entityId ?? '',
        userId: state.userId!,
        influencerId: state.influencerId!,
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
      final service = ref.read(userInfluencerLinkServiceProvider);
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

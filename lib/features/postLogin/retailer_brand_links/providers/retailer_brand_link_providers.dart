import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../../core/services/entity_service.dart';
import '../service/retailer_brand_link_service_impl.dart';
import '../adapter/retailer_brand_link_adapter.dart';
import '../model/retailer_brand_link_model.dart';

/// Mapper provider
final retailerBrandLinkMapperProvider =
    Provider<EntityMapper<ModelRetailerBrandLink>>((ref) {
      return ModelRetailerBrandLinkMapper();
    });

/// Service provider
final retailerBrandLinkServiceProvider = Provider<RetailerBrandLinkServiceImpl>(
  (ref) {
    return RetailerBrandLinkServiceImpl(
      ref.watch(retailerBrandLinkMapperProvider),
      ref.watch(supabaseClientProvider),
      ref.watch(loggerServiceProvider),
    );
  },
);

/// Adapter provider
final retailerBrandLinkAdapterProvider = Provider<RetailerBrandLinkAdapter>((
  ref,
) {
  return RetailerBrandLinkAdapter();
});

/// Fetches all links with automatic disposal
final retailerBrandLinksStreamProvider =
    StreamProvider.autoDispose<List<ModelRetailerBrandLink>>((ref) {
      final service = ref.read(retailerBrandLinkServiceProvider);
      return service.streamEntities();
    });

/// Fetches a single link by ID
final retailerBrandLinkByIdProvider = FutureProvider.autoDispose
    .family<ModelRetailerBrandLink?, String>((ref, id) async {
      final service = ref.read(retailerBrandLinkServiceProvider);
      return await service.fetchById(id);
    });

/// State provider for managing form state
final retailerBrandLinkFormProvider =
    StateNotifierProvider.autoDispose<
      RetailerBrandLinkFormNotifier,
      RetailerBrandLinkFormState
    >((ref) {
      return RetailerBrandLinkFormNotifier(ref);
    });

/// Form state
class RetailerBrandLinkFormState {
  final String? userId;
  final String? brandId;
  final bool isLoading;
  final String? error;

  RetailerBrandLinkFormState({
    this.userId,
    this.brandId,
    this.isLoading = false,
    this.error,
  });

  RetailerBrandLinkFormState copyWith({
    String? userId,
    String? brandId,
    bool? isLoading,
    String? error,
  }) {
    return RetailerBrandLinkFormState(
      userId: userId ?? this.userId,
      brandId: brandId ?? this.brandId,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Notifier for managing form state
class RetailerBrandLinkFormNotifier
    extends StateNotifier<RetailerBrandLinkFormState> {
  final Ref ref;

  RetailerBrandLinkFormNotifier(this.ref) : super(RetailerBrandLinkFormState());

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

  void updateBrandId(String? brandId) {
    if (!_mounted) return;
    state = state.copyWith(brandId: brandId, error: null);
  }

  /// Generic update method for ModuleRouteGenerator
  void updateField(String field, dynamic value) {
    if (!_mounted) return;
    switch (field) {
      case ModelRetailerBrandLinkFields.userId:
        updateUserId(value as String?);
        break;
      case ModelRetailerBrandLinkFields.brandId:
        updateBrandId(value as String?);
        break;
    }
  }

  Future<bool> saveEntity({String? entityId}) async {
    if (!_mounted) return false;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final service = ref.read(retailerBrandLinkServiceProvider);

      // Validation
      if (state.userId == null || state.brandId == null) {
        throw Exception('User and Brand are required');
      }

      final entity = ModelRetailerBrandLink(
        linkId: entityId ?? '',
        userId: state.userId!,
        brandId: state.brandId!,
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
      final service = ref.read(retailerBrandLinkServiceProvider);
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

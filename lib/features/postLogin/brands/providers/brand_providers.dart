import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../../core/services/entity_service.dart';
import '../adapter/brand_adapter.dart';
import '../model/brand_model.dart';
import '../service/brand_service_impl.dart';

// ============================================================================
// SERVICE, MAPPER AND ADAPTER PROVIDERS
// ============================================================================

/// Mapper provider
final brandMapperProvider = Provider<EntityMapper<ModelBrand>>((ref) {
  return ModelBrandMapper();
});

/// Service provider
final brandServiceProvider = Provider<BrandServiceImpl>((ref) {
  return BrandServiceImpl(
    ref.watch(brandMapperProvider),
    ref.watch(supabaseClientProvider),
    ref.watch(loggerServiceProvider),
  );
});

/// Adapter provider
final brandAdapterProvider = Provider<BrandAdapter>((ref) {
  return BrandAdapter();
});

/// Fetches all brands with automatic disposal
/// Uses StreamProvider for real-time updates
final brandsStreamProvider = StreamProvider.autoDispose<List<ModelBrand>>((
  ref,
) {
  final service = ref.read(brandServiceProvider);
  return service.streamEntities();
});

/// Fetches a single brand by ID
final brandByIdProvider = FutureProvider.autoDispose
    .family<ModelBrand?, String>((ref, brandId) async {
      final service = ref.read(brandServiceProvider);
      return await service.fetchById(brandId);
    });

/// State provider for managing brand creation/editing
final brandFormProvider =
    StateNotifierProvider.autoDispose<BrandFormNotifier, BrandFormState>(
      (ref) => BrandFormNotifier(ref),
    );

// ============================================================================
// FORM STATE AND NOTIFIER
// ============================================================================

/// Form state for brand creation/editing
class BrandFormState {
  final String brandName;
  final String? brandsPrimaryAgency;
  final String? brandNote;
  final String? hiddenNote;
  final String? brandMobile1;
  final String? brandMobile2;
  final String? brandPersonName;
  final bool? isActive;
  final String? brandLocationUrl;
  final String? brandLandmark;
  final String? brandAddress;
  final String? brandPhotoId;
  final String? brandPhotoUrl;
  final double? brandLat;
  final double? brandLong;
  final String? androidAppId;
  final String? websiteUrl;
  final bool isLoading;
  final String? error;

  BrandFormState({
    this.brandName = '',
    this.brandsPrimaryAgency,
    this.brandNote,
    this.hiddenNote,
    this.brandMobile1,
    this.brandMobile2,
    this.brandPersonName,
    this.isActive = true,
    this.brandLocationUrl,
    this.brandLandmark,
    this.brandAddress,
    this.brandPhotoId,
    this.brandPhotoUrl,
    this.brandLat,
    this.brandLong,
    this.androidAppId,
    this.websiteUrl,
    this.isLoading = false,
    this.error,
  });

  BrandFormState copyWith({
    String? brandName,
    String? brandsPrimaryAgency,
    String? brandNote,
    String? hiddenNote,
    String? brandMobile1,
    String? brandMobile2,
    String? brandPersonName,
    bool? isActive,
    String? brandLocationUrl,
    String? brandLandmark,
    String? brandAddress,
    String? brandPhotoId,
    String? brandPhotoUrl,
    double? brandLat,
    double? brandLong,
    String? androidAppId,
    String? websiteUrl,
    bool? isLoading,
    String? error,
  }) {
    return BrandFormState(
      brandName: brandName ?? this.brandName,
      brandsPrimaryAgency: brandsPrimaryAgency ?? this.brandsPrimaryAgency,
      brandNote: brandNote ?? this.brandNote,
      hiddenNote: hiddenNote ?? this.hiddenNote,
      brandMobile1: brandMobile1 ?? this.brandMobile1,
      brandMobile2: brandMobile2 ?? this.brandMobile2,
      brandPersonName: brandPersonName ?? this.brandPersonName,
      isActive: isActive ?? this.isActive,
      brandLocationUrl: brandLocationUrl ?? this.brandLocationUrl,
      brandLandmark: brandLandmark ?? this.brandLandmark,
      brandAddress: brandAddress ?? this.brandAddress,
      brandPhotoId: brandPhotoId ?? this.brandPhotoId,
      brandPhotoUrl: brandPhotoUrl ?? this.brandPhotoUrl,
      brandLat: brandLat ?? this.brandLat,
      brandLong: brandLong ?? this.brandLong,
      androidAppId: androidAppId ?? this.androidAppId,
      websiteUrl: websiteUrl ?? this.websiteUrl,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Notifier for managing brand form state
class BrandFormNotifier extends StateNotifier<BrandFormState> {
  final Ref ref;
  bool _mounted = true;

  BrandFormNotifier(this.ref) : super(BrandFormState());

  @override
  void dispose() {
    _mounted = false;
    super.dispose();
  }

  void updateField(String fieldName, dynamic value) {
    if (!_mounted) return;

    switch (fieldName) {
      case ModelBrandFields.brandName:
        state = state.copyWith(brandName: value as String, error: null);
        break;
      case ModelBrandFields.brandsPrimaryAgency:
        state = state.copyWith(
          brandsPrimaryAgency: value as String?,
          error: null,
        );
        break;
      case ModelBrandFields.brandNote:
        state = state.copyWith(brandNote: value as String?, error: null);
        break;
      case ModelBrandFields.hiddenNote:
        state = state.copyWith(hiddenNote: value as String?, error: null);
        break;
      case ModelBrandFields.brandMobile1:
        state = state.copyWith(brandMobile1: value as String?, error: null);
        break;
      case ModelBrandFields.brandMobile2:
        state = state.copyWith(brandMobile2: value as String?, error: null);
        break;
      case ModelBrandFields.brandPersonName:
        state = state.copyWith(brandPersonName: value as String?, error: null);
        break;
      case ModelBrandFields.isActive:
        state = state.copyWith(isActive: value as bool?, error: null);
        break;
      case ModelBrandFields.brandLocationUrl:
        state = state.copyWith(brandLocationUrl: value as String?, error: null);
        break;
      case ModelBrandFields.brandLandmark:
        state = state.copyWith(brandLandmark: value as String?, error: null);
        break;
      case ModelBrandFields.brandAddress:
        state = state.copyWith(brandAddress: value as String?, error: null);
        break;
      case ModelBrandFields.brandPhotoId:
        state = state.copyWith(brandPhotoId: value as String?, error: null);
        break;
      case ModelBrandFields.brandPhotoUrl:
        state = state.copyWith(brandPhotoUrl: value as String?, error: null);
        break;
      case ModelBrandFields.brandLat:
        state = state.copyWith(
          brandLat: value != null ? double.tryParse(value.toString()) : null,
          error: null,
        );
        break;
      case ModelBrandFields.brandLong:
        state = state.copyWith(
          brandLong: value != null ? double.tryParse(value.toString()) : null,
          error: null,
        );
        break;
      case ModelBrandFields.androidAppId:
        state = state.copyWith(androidAppId: value as String?, error: null);
        break;
      case ModelBrandFields.websiteUrl:
        state = state.copyWith(websiteUrl: value as String?, error: null);
        break;
    }
  }

  Future<bool> saveEntity({String? entityId}) async {
    if (!_mounted) return false;

    // Validation
    if (state.brandName.trim().isEmpty) {
      state = state.copyWith(error: 'Brand name is required');
      return false;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final service = ref.read(brandServiceProvider);
      final entity = ModelBrand(
        brandId: entityId,
        brandName: state.brandName.trim(),
        brandsPrimaryAgency: state.brandsPrimaryAgency,
        brandNote: state.brandNote,
        hiddenNote: state.hiddenNote,
        brandMobile1: state.brandMobile1,
        brandMobile2: state.brandMobile2,
        brandPersonName: state.brandPersonName,
        isActive: state.isActive ?? true,
        brandLocationUrl: state.brandLocationUrl,
        brandLandmark: state.brandLandmark,
        brandAddress: state.brandAddress,
        brandPhotoId: state.brandPhotoId,
        brandPhotoUrl: state.brandPhotoUrl,
        brandLat: state.brandLat,
        brandLong: state.brandLong,
        androidAppId: state.androidAppId,
        websiteUrl: state.websiteUrl,
      );

      if (entityId == null) {
        // Create new brand
        await service.create(entity);
      } else {
        // Update existing brand
        await service.update(entityId, entity);
      }

      if (!_mounted) return true;
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      if (!_mounted) return false;
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to save brand: $e',
      );
      return false;
    }
  }

  Future<bool> deleteEntity(String entityId) async {
    if (!_mounted) return false;
    state = state.copyWith(isLoading: true, error: null);

    try {
      final service = ref.read(brandServiceProvider);
      await service.delete(entityId);
      if (!_mounted) return true;
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      if (!_mounted) return false;
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to delete brand: $e',
      );
      return false;
    }
  }

  void loadEntity(ModelBrand entity) {
    if (!_mounted) return;
    state = BrandFormState(
      brandName: entity.brandName,
      brandsPrimaryAgency: entity.brandsPrimaryAgency,
      brandNote: entity.brandNote,
      hiddenNote: entity.hiddenNote,
      brandMobile1: entity.brandMobile1,
      brandMobile2: entity.brandMobile2,
      brandPersonName: entity.brandPersonName,
      isActive: entity.isActive,
      brandLocationUrl: entity.brandLocationUrl,
      brandLandmark: entity.brandLandmark,
      brandAddress: entity.brandAddress,
      brandPhotoId: entity.brandPhotoId,
      brandPhotoUrl: entity.brandPhotoUrl,
      brandLat: entity.brandLat,
      brandLong: entity.brandLong,
      androidAppId: entity.androidAppId,
      websiteUrl: entity.websiteUrl,
    );
  }

  void reset() {
    if (!_mounted) return;
    state = BrandFormState();
  }

  /// Generic save method for ModuleRouteGenerator
  Future<bool> save({String? entityId}) => saveEntity(entityId: entityId);

  /// Generic delete method for ModuleRouteGenerator
  Future<bool> delete(String id) => deleteEntity(id);
}

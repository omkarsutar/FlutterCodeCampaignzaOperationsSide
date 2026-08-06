import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../../core/services/entity_service.dart';
import '../adapter/brand_data_adapter.dart';
import '../model/brand_data_model.dart';
import '../service/brand_data_mapper.dart';
import '../service/brand_data_service_impl.dart';

/// Mapper provider
final brandDataMapperProvider = Provider<EntityMapper<ModelBrandData>>((ref) {
  return BrandDataMapper();
});

/// Service provider
final brandDataServiceProvider = Provider<BrandDataServiceImpl>((ref) {
  return BrandDataServiceImpl(
    ref.watch(brandDataMapperProvider),
    ref.watch(supabaseClientProvider),
    ref.watch(loggerServiceProvider),
  );
});

/// Adapter provider
final brandDataAdapterProvider = Provider<BrandDataAdapter>((ref) {
  return BrandDataAdapter();
});

/// Fetches all brand data with automatic disposal
/// Uses StreamProvider for real-time updates
final brandDataStreamProvider =
    StreamProvider.autoDispose<List<ModelBrandData>>((ref) {
      final service = ref.read(brandDataServiceProvider);
      return service.streamEntities();
    });

/// Fetches a single brand data entity by ID
final brandDataByIdProvider = FutureProvider.autoDispose
    .family<ModelBrandData?, String>((ref, id) async {
      final service = ref.read(brandDataServiceProvider);
      return await service.fetchById(id);
    });

/// State provider for managing brand data creation/editing
final brandDataFormProvider =
    StateNotifierProvider.autoDispose<
      BrandDataFormNotifier,
      BrandDataFormState
    >((ref) => BrandDataFormNotifier(ref));

class BrandDataFormState {
  final String brandName;
  final String? brandPhotoUrl;
  final String? websiteUrl;
  final String? androidAppId;
  final String? metaPixelId;
  final String? gmbProfileUrl;
  final String? gmbReviewTexts;
  final String? gmbReviewTextsHi;
  final String? gmbReviewTextsMr;
  final String? whatsappNo;
  final String? whatsappMsgText;
  final String? youtubeUrl;
  final String? instagramUrl;
  final String? facebookUrl;
  final bool isActive;
  final bool isLoading;
  final String? error;

  BrandDataFormState({
    this.brandName = '',
    this.brandPhotoUrl,
    this.websiteUrl,
    this.androidAppId,
    this.metaPixelId,
    this.gmbProfileUrl,
    this.gmbReviewTexts,
    this.gmbReviewTextsHi,
    this.gmbReviewTextsMr,
    this.whatsappNo,
    this.whatsappMsgText,
    this.youtubeUrl,
    this.instagramUrl,
    this.facebookUrl,
    this.isActive = true,
    this.isLoading = false,
    this.error,
  });

  BrandDataFormState copyWith({
    String? brandName,
    String? brandPhotoUrl,
    String? websiteUrl,
    String? androidAppId,
    String? metaPixelId,
    String? gmbProfileUrl,
    String? gmbReviewTexts,
    String? gmbReviewTextsHi,
    String? gmbReviewTextsMr,
    String? whatsappNo,
    String? whatsappMsgText,
    String? youtubeUrl,
    String? instagramUrl,
    String? facebookUrl,
    bool? isActive,
    bool? isLoading,
    String? error,
  }) {
    return BrandDataFormState(
      brandName: brandName ?? this.brandName,
      brandPhotoUrl: brandPhotoUrl ?? this.brandPhotoUrl,
      websiteUrl: websiteUrl ?? this.websiteUrl,
      androidAppId: androidAppId ?? this.androidAppId,
      metaPixelId: metaPixelId ?? this.metaPixelId,
      gmbProfileUrl: gmbProfileUrl ?? this.gmbProfileUrl,
      gmbReviewTexts: gmbReviewTexts ?? this.gmbReviewTexts,
      gmbReviewTextsHi: gmbReviewTextsHi ?? this.gmbReviewTextsHi,
      gmbReviewTextsMr: gmbReviewTextsMr ?? this.gmbReviewTextsMr,
      whatsappNo: whatsappNo ?? this.whatsappNo,
      whatsappMsgText: whatsappMsgText ?? this.whatsappMsgText,
      youtubeUrl: youtubeUrl ?? this.youtubeUrl,
      instagramUrl: instagramUrl ?? this.instagramUrl,
      facebookUrl: facebookUrl ?? this.facebookUrl,
      isActive: isActive ?? this.isActive,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class BrandDataFormNotifier extends StateNotifier<BrandDataFormState> {
  final Ref ref;
  bool _mounted = true;

  BrandDataFormNotifier(this.ref) : super(BrandDataFormState());

  @override
  void dispose() {
    _mounted = false;
    super.dispose();
  }

  void updateField(String fieldName, dynamic value) {
    if (!_mounted) return;

    switch (fieldName) {
      case ModelBrandDataFields.brandName:
        state = state.copyWith(brandName: value as String, error: null);
        break;
      case ModelBrandDataFields.brandPhotoUrl:
        state = state.copyWith(brandPhotoUrl: value as String?, error: null);
        break;
      case ModelBrandDataFields.websiteUrl:
        state = state.copyWith(websiteUrl: value as String?, error: null);
        break;
      case ModelBrandDataFields.androidAppId:
        state = state.copyWith(androidAppId: value as String?, error: null);
        break;
      case ModelBrandDataFields.metaPixelId:
        state = state.copyWith(metaPixelId: value as String?, error: null);
        break;
      case ModelBrandDataFields.gmbProfileUrl:
        state = state.copyWith(gmbProfileUrl: value as String?, error: null);
        break;
      case ModelBrandDataFields.gmbReviewTexts:
        state = state.copyWith(gmbReviewTexts: value as String?, error: null);
        break;
      case ModelBrandDataFields.gmbReviewTextsHi:
        state = state.copyWith(gmbReviewTextsHi: value as String?, error: null);
        break;
      case ModelBrandDataFields.gmbReviewTextsMr:
        state = state.copyWith(gmbReviewTextsMr: value as String?, error: null);
        break;
      case ModelBrandDataFields.whatsappNo:
        state = state.copyWith(whatsappNo: value as String?, error: null);
        break;
      case ModelBrandDataFields.whatsappMsgText:
        state = state.copyWith(whatsappMsgText: value as String?, error: null);
        break;
      case ModelBrandDataFields.youtubeUrl:
        state = state.copyWith(youtubeUrl: value as String?, error: null);
        break;
      case ModelBrandDataFields.instagramUrl:
        state = state.copyWith(instagramUrl: value as String?, error: null);
        break;
      case ModelBrandDataFields.facebookUrl:
        state = state.copyWith(facebookUrl: value as String?, error: null);
        break;
      case ModelBrandDataFields.isActive:
        state = state.copyWith(isActive: value as bool? ?? false, error: null);
        break;
    }
  }

  Future<bool> saveEntity({String? entityId}) async {
    if (!_mounted) return false;

    if (state.brandName.trim().isEmpty) {
      state = state.copyWith(error: 'Brand name is required');
      return false;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final service = ref.read(brandDataServiceProvider);
      final entity = ModelBrandData(
        id: entityId,
        brandName: state.brandName.trim(),
        brandPhotoUrl: state.brandPhotoUrl,
        websiteUrl: state.websiteUrl,
        androidAppId: state.androidAppId,
        metaPixelId: state.metaPixelId,
        gmbProfileUrl: state.gmbProfileUrl,
        gmbReviewTexts: _parseMultilineToList(state.gmbReviewTexts),
        gmbReviewTextsHi: _parseMultilineToList(state.gmbReviewTextsHi),
        gmbReviewTextsMr: _parseMultilineToList(state.gmbReviewTextsMr),
        whatsappNo: state.whatsappNo,
        whatsappMsgText: state.whatsappMsgText,
        youtubeUrl: state.youtubeUrl,
        instagramUrl: state.instagramUrl,
        facebookUrl: state.facebookUrl,
        isActive: state.isActive,
      );

      if (entityId == null) {
        await service.create(entity);
      } else {
        await service.update(entityId, entity);
      }

      if (!_mounted) return true;
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      if (!_mounted) return false;
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to save brand data: $e',
      );
      return false;
    }
  }

  Future<bool> deleteEntity(String entityId) async {
    if (!_mounted) return false;
    state = state.copyWith(isLoading: true, error: null);

    try {
      final service = ref.read(brandDataServiceProvider);
      await service.delete(entityId);
      if (!_mounted) return true;
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      if (!_mounted) return false;
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to delete brand data: $e',
      );
      return false;
    }
  }

  void loadEntity(ModelBrandData entity) {
    if (!_mounted) return;
    state = BrandDataFormState(
      brandName: entity.brandName,
      brandPhotoUrl: entity.brandPhotoUrl,
      websiteUrl: entity.websiteUrl,
      androidAppId: entity.androidAppId,
      metaPixelId: entity.metaPixelId,
      gmbProfileUrl: entity.gmbProfileUrl,
      gmbReviewTexts: entity.gmbReviewTexts?.join('\n'),
      gmbReviewTextsHi: entity.gmbReviewTextsHi?.join('\n'),
      gmbReviewTextsMr: entity.gmbReviewTextsMr?.join('\n'),
      whatsappNo: entity.whatsappNo,
      whatsappMsgText: entity.whatsappMsgText,
      youtubeUrl: entity.youtubeUrl,
      instagramUrl: entity.instagramUrl,
      facebookUrl: entity.facebookUrl,
      isActive: entity.isActive,
    );
  }

  void reset() {
    if (!_mounted) return;
    state = BrandDataFormState();
  }

  /// Generic save method for ModuleRouteGenerator
  Future<bool> save({String? entityId}) => saveEntity(entityId: entityId);

  /// Generic delete method for ModuleRouteGenerator
  Future<bool> delete(String id) => deleteEntity(id);

  List<String>? _parseMultilineToList(String? text) {
    if (text == null || text.trim().isEmpty) return null;
    return text
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
  }
}

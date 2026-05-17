import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../../core/services/entity_service.dart';
import '../adapter/influencer_adapter.dart';
import '../model/influencer_model.dart';
import '../service/influencer_service_impl.dart';

/// Mapper provider
final influencerMapperProvider = Provider<EntityMapper<ModelInfluencer>>((ref) {
  return ModelInfluencerMapper();
});

/// Service provider
final influencerServiceProvider = Provider<InfluencerServiceImpl>((ref) {
  return InfluencerServiceImpl(
    ref.watch(influencerMapperProvider),
    ref.watch(supabaseClientProvider),
    ref.watch(loggerServiceProvider),
  );
});

/// Adapter provider
final influencerAdapterProvider = Provider<InfluencerAdapter>((ref) {
  return InfluencerAdapter();
});

/// Fetches all influencers with automatic disposal
/// Uses StreamProvider for real-time updates
final influencersStreamProvider = StreamProvider.autoDispose<List<ModelInfluencer>>((
  ref,
) {
  final service = ref.read(influencerServiceProvider);
  return service.streamEntities();
});

/// Centralized provider for influencer category types
final influencerCategoriesProvider = Provider<List<Map<String, String>>>((ref) {
  return [
    {'Instagram': 'Instagram'},
    {'YouTube': 'YouTube'},
    {'TikTok': 'TikTok'},
    {'Facebook': 'Facebook'},
    {'Twitter': 'Twitter'},
    {'LinkedIn': 'LinkedIn'},
    {'Other': 'Other'},
  ];
});

/// Fetches a single influencer by ID
final influencerByIdProvider = FutureProvider.autoDispose
    .family<ModelInfluencer?, String>((ref, influencerId) async {
      final service = ref.read(influencerServiceProvider);
      return await service.fetchById(influencerId);
    });

/// State provider for managing influencer creation/editing
final influencerFormProvider =
    StateNotifierProvider.autoDispose<InfluencerFormNotifier, InfluencerFormState>(
      (ref) => InfluencerFormNotifier(ref),
    );

/// Form state for Influencer
class InfluencerFormState {
  final String influencerCategory;
  final String influencerName;
  final String influencerNameHindi;
  final double baseCommissionRate;
  final bool isActive;
  final bool isAvailable;
  final String influencerImageUrl;
  final bool isLoading;
  final String? error;

  const InfluencerFormState({
    this.influencerCategory = '',
    this.influencerName = '',
    this.influencerNameHindi = '',
    this.baseCommissionRate = 0.0,
    this.isActive = true,
    this.isAvailable = true,
    this.influencerImageUrl = '',
    this.isLoading = false,
    this.error,
  });

  InfluencerFormState copyWith({
    String? influencerCategory,
    String? influencerName,
    String? influencerNameHindi,
    double? baseCommissionRate,
    bool? isActive,
    bool? isAvailable,
    String? influencerImageUrl,
    bool? isLoading,
    String? error,
  }) {
    return InfluencerFormState(
      influencerCategory: influencerCategory ?? this.influencerCategory,
      influencerName: influencerName ?? this.influencerName,
      influencerNameHindi: influencerNameHindi ?? this.influencerNameHindi,
      baseCommissionRate: baseCommissionRate ?? this.baseCommissionRate,
      isActive: isActive ?? this.isActive,
      isAvailable: isAvailable ?? this.isAvailable,
      influencerImageUrl: influencerImageUrl ?? this.influencerImageUrl,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  factory InfluencerFormState.fromEntity(ModelInfluencer entity) {
    return InfluencerFormState(
      influencerCategory: entity.influencerCategory,
      influencerName: entity.influencerName,
      influencerNameHindi: entity.influencerNameHindi ?? '',
      baseCommissionRate: entity.baseCommissionRate,
      isActive: entity.isActive,
      isAvailable: entity.isAvailable,
      influencerImageUrl: entity.influencerImageUrl ?? '',
    );
  }
}

/// Notifier for managing Influencer form state
class InfluencerFormNotifier extends StateNotifier<InfluencerFormState> {
  final Ref ref;
  bool _mounted = true;

  InfluencerFormNotifier(this.ref) : super(InfluencerFormState());

  @override
  void dispose() {
    _mounted = false;
    super.dispose();
  }

  void updateInfluencerCategory(String category) {
    if (!_mounted) return;
    state = state.copyWith(influencerCategory: category, error: null);
  }

  void updateInfluencerName(String name) {
    if (!_mounted) return;
    state = state.copyWith(influencerName: name, error: null);
  }

  void updateInfluencerNameHindi(String name) {
    if (!_mounted) return;
    state = state.copyWith(influencerNameHindi: name, error: null);
  }

  void updateBaseCommissionRate(double rate) {
    if (!_mounted) return;
    state = state.copyWith(baseCommissionRate: rate, error: null);
  }

  void updateIsActive(bool isActive) {
    if (!_mounted) return;
    state = state.copyWith(isActive: isActive, error: null);
  }

  void updateIsAvailable(bool value) {
    if (!_mounted) return;
    state = state.copyWith(isAvailable: value);
  }

  void updateInfluencerImageUrl(String value) {
    if (!_mounted) return;
    state = state.copyWith(influencerImageUrl: value);
  }

  /// Generic update method for ModuleRouteGenerator
  void updateField(String field, dynamic value) {
    if (!_mounted) return;
    switch (field) {
      case ModelInfluencerFields.influencerCategory:
        updateInfluencerCategory(value as String);
        break;
      case ModelInfluencerFields.influencerName:
        updateInfluencerName(value as String);
        break;
      case ModelInfluencerFields.influencerNameHindi:
        updateInfluencerNameHindi(value as String);
        break;
      case ModelInfluencerFields.baseCommissionRate:
        updateBaseCommissionRate(
          value is double ? value : double.tryParse(value.toString()) ?? 0.0,
        );
        break;
      case ModelInfluencerFields.isActive:
        updateIsActive(value as bool);
        break;
      case ModelInfluencerFields.isAvailable:
        updateIsAvailable(value as bool);
        break;
      case ModelInfluencerFields.influencerImageUrl:
        updateInfluencerImageUrl(value as String);
        break;
    }
  }

  Future<bool> saveEntity({String? entityId}) async {
    if (!_mounted) return false;

    // Basic validation
    if (state.influencerCategory.trim().isEmpty) {
      state = state.copyWith(error: 'Category is required');
      return false;
    }
    if (state.influencerName.trim().isEmpty) {
      state = state.copyWith(error: 'Name is required');
      return false;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final service = ref.read(influencerServiceProvider);
      final entity = ModelInfluencer(
        influencerId: entityId,
        influencerCategory: state.influencerCategory.trim(),
        influencerName: state.influencerName.trim(),
        influencerNameHindi: state.influencerNameHindi.trim(),
        baseCommissionRate: state.baseCommissionRate,
        isActive: state.isActive,
        isAvailable: state.isAvailable,
        influencerImageUrl: state.influencerImageUrl.trim(),
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
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to save ${influencerEntityMeta.entityNameLower}: $e',
        );
      }
      return false;
    }
  }

  Future<bool> deleteEntity(String entityId) async {
    if (!_mounted) return false;
    state = state.copyWith(isLoading: true, error: null);

    try {
      final service = ref.read(influencerServiceProvider);
      await service.deleteEntityById(entityId);

      if (_mounted) {
        state = state.copyWith(isLoading: false);
      }
      return true;
    } catch (e) {
      if (_mounted) {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to delete ${influencerEntityMeta.entityNameLower}: $e',
        );
      }
      return false;
    }
  }

  void loadEntity(ModelInfluencer entity) {
    if (!_mounted) return;
    state = InfluencerFormState(
      influencerCategory: entity.influencerCategory,
      influencerName: entity.influencerName,
      influencerNameHindi: entity.influencerNameHindi ?? '',
      baseCommissionRate: entity.baseCommissionRate,
      isActive: entity.isActive,
      isAvailable: entity.isAvailable,
      influencerImageUrl: entity.influencerImageUrl ?? '',
    );
  }

  void reset() {
    if (!_mounted) return;
    state = InfluencerFormState();
  }

  /// Generic save method for ModuleRouteGenerator
  Future<bool> save({String? entityId}) => saveEntity(entityId: entityId);

  /// Generic delete method for ModuleRouteGenerator
  Future<bool> delete(String id) => deleteEntity(id);
}
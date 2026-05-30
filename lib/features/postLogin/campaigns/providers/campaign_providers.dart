import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../../core/services/entity_service.dart';
import 'package:collection/collection.dart';
import '../../../../core/config/module_config.dart';

import '../adapter/campaign_adapter.dart';
import '../model/campaign_model.dart';
import '../service/campaign_service_impl.dart';

/// Mapper provider
final campaignMapperProvider = Provider<EntityMapper<ModelCampaign>>((ref) {
  return ModelCampaignMapper();
});

/// Cache for module configuration to avoid circular dependencies
class CampaignConfigCache {
  static ModuleConfig? config;
}

/// Service provider
final campaignServiceProvider = Provider<CampaignServiceImpl>((ref) {
  // Extract initial sorting from cached config if available
  final initialSorting = CampaignConfigCache.config?.listPage?.sorting;

  return CampaignServiceImpl(
    ref.watch(campaignMapperProvider),
    ref.watch(supabaseClientProvider),
    ref.watch(loggerServiceProvider),
    ref,
    initialSorting: initialSorting,
  );
});

/// Adapter provider
final campaignAdapterProvider = Provider<CampaignAdapter>((ref) {
  return CampaignAdapter();
});

/// Real-time stream of all campaigns
/// Uses StreamProvider.autoDispose for automatic cleanup when page is unmounted
/// Strategy: Listen to campaign table, read from view_campaigns
/// The stream automatically updates when any campaign is created, updated, or deleted
final campaignsStreamProvider = StreamProvider.autoDispose<List<ModelCampaign>>(
  (ref) {
    final service = ref.read(campaignServiceProvider);
    return service.streamEntities();
  },
);

/// Fetch a single campaign by ID
/// Uses FutureProvider.autoDispose.family for efficient caching and cleanup
final campaignByIdProvider = FutureProvider.autoDispose
    .family<ModelCampaign?, String>((ref, poId) async {
      final service = ref.read(campaignServiceProvider);
      return await service.fetchById(poId);
    });

/// State provider for managing campaign creation/editing
/// Uses StateNotifierProvider.autoDispose for form state management
final campaignFormProvider =
    StateNotifierProvider.autoDispose<CampaignFormNotifier, CampaignFormState>(
      (ref) => CampaignFormNotifier(ref),
    );

final campaignStreamByIdProvider =
    StreamProvider.family<ModelCampaign?, String>((ref, poId) {
      return ref
          .watch(campaignServiceProvider)
          .streamEntities()
          .map((orders) => orders.firstWhereOrNull((o) => o.poId == poId));
    });

/// Persistent search query for PO list
final campaignSearchProvider = StateProvider.family.autoDispose<String, String>(
  (ref, key) => '',
);

/// Persistent status filter for PO list
final campaignStatusFilterProvider = StateProvider.family
    .autoDispose<String?, String>((ref, key) => 'confirmed');

/// Fetch a single campaign by ID

/// Form state for campaign
class CampaignFormState {
  final String campaignName;
  final DateTime? validFrom;
  final DateTime? validUntil;
  final String poAgencyId;
  final String poBrandId;
  final double? poTotalAmount;
  final int? poLineItemCount;
  final String? userComment;
  final double? profitToBrand;
  final double? poLat;
  final double? poLong;
  final String? status;
  final bool isLoading;
  final String? error;

  CampaignFormState({
    this.campaignName = '',
    this.validFrom,
    this.validUntil,
    this.poAgencyId = '',
    this.poBrandId = '',
    this.poTotalAmount,
    this.poLineItemCount,
    this.userComment,
    this.profitToBrand,
    this.poLat,
    this.poLong,
    this.status = 'confirmed',
    this.isLoading = false,
    this.error,
  });

  CampaignFormState copyWith({
    String? campaignName,
    DateTime? validFrom,
    DateTime? validUntil,
    String? poAgencyId,
    String? poBrandId,
    double? poTotalAmount,
    int? poLineItemCount,
    String? userComment,
    double? profitToBrand,
    double? poLat,
    double? poLong,
    String? status,
    bool? isLoading,
    String? error,
  }) {
    return CampaignFormState(
      campaignName: campaignName ?? this.campaignName,
      validFrom: validFrom ?? this.validFrom,
      validUntil: validUntil ?? this.validUntil,
      poAgencyId: poAgencyId ?? this.poAgencyId,
      poBrandId: poBrandId ?? this.poBrandId,
      poTotalAmount: poTotalAmount ?? this.poTotalAmount,
      poLineItemCount: poLineItemCount ?? this.poLineItemCount,
      userComment: userComment ?? this.userComment,
      profitToBrand: profitToBrand ?? this.profitToBrand,
      poLat: poLat ?? this.poLat,
      poLong: poLong ?? this.poLong,
      status: status ?? this.status,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Notifier for managing campaign form state
class CampaignFormNotifier extends StateNotifier<CampaignFormState> {
  final Ref ref;
  bool _mounted = true;

  CampaignFormNotifier(this.ref) : super(CampaignFormState());

  @override
  void dispose() {
    _mounted = false;
    super.dispose();
  }

  void updateField(String fieldName, dynamic value) {
    if (!_mounted) return;

    switch (fieldName) {
      case ModelCampaignFields.campaignName:
        state = state.copyWith(campaignName: value as String, error: null);
        break;
      case ModelCampaignFields.validFrom:
        state = state.copyWith(
          validFrom: value != null ? DateTime.tryParse(value.toString()) : null,
          error: null,
        );
        break;
      case ModelCampaignFields.validUntil:
        state = state.copyWith(
          validUntil: value != null ? DateTime.tryParse(value.toString()) : null,
          error: null,
        );
        break;
      case ModelCampaignFields.poAgencyId:
        state = state.copyWith(poAgencyId: value as String, error: null);
        break;
      case ModelCampaignFields.poBrandId:
        state = state.copyWith(poBrandId: value as String, error: null);
        break;
      case ModelCampaignFields.poTotalAmount:
        state = state.copyWith(
          poTotalAmount: value != null
              ? double.tryParse(value.toString())
              : null,
          error: null,
        );
        break;
      case ModelCampaignFields.poLineItemCount:
        state = state.copyWith(
          poLineItemCount: value != null
              ? int.tryParse(value.toString())
              : null,
          error: null,
        );
        break;
      case ModelCampaignFields.userComment:
        state = state.copyWith(userComment: value as String?, error: null);
        break;
      case ModelCampaignFields.profitToBrand:
        state = state.copyWith(
          profitToBrand: value != null
              ? double.tryParse(value.toString())
              : null,
          error: null,
        );
        break;
      case ModelCampaignFields.poLat:
        state = state.copyWith(
          poLat: value != null ? double.tryParse(value.toString()) : null,
          error: null,
        );
        break;
      case ModelCampaignFields.poLong:
        state = state.copyWith(
          poLong: value != null ? double.tryParse(value.toString()) : null,
          error: null,
        );
        break;
      case ModelCampaignFields.status:
        state = state.copyWith(status: value as String?, error: null);
        break;
    }
  }

  Future<bool> saveEntity({String? entityId}) async {
    if (!_mounted) return false;

    // Validation
    if (state.campaignName.trim().isEmpty) {
      state = state.copyWith(error: 'Campaign Name is required');
      return false;
    }
    if (state.poAgencyId.trim().isEmpty) {
      state = state.copyWith(error: 'Agency is required');
      return false;
    }
    if (state.poBrandId.trim().isEmpty) {
      state = state.copyWith(error: 'Brand is required');
      return false;
    }
    if (state.validFrom == null) {
      state = state.copyWith(error: 'Valid From date is required');
      return false;
    }
    if (state.validUntil == null) {
      state = state.copyWith(error: 'Valid Until date is required');
      return false;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final service = ref.read(campaignServiceProvider);
      final entity = ModelCampaign(
        poId: entityId,
        campaignName: state.campaignName.trim(),
        validFrom: state.validFrom,
        validUntil: state.validUntil,
        poAgencyId: state.poAgencyId.trim(),
        poBrandId: state.poBrandId.trim(),
        poTotalAmount: state.poTotalAmount,
        poLineItemCount: state.poLineItemCount,
        userComment: state.userComment,
        profitToBrand: state.profitToBrand,
        poLat: state.poLat,
        poLong: state.poLong,
        status: state.status,
      );

      if (entityId == null) {
        // Create new campaign
        await service.create(entity);
      } else {
        // Update existing campaign
        await service.update(entityId, entity);
      }

      if (!_mounted) return true;
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      if (!_mounted) return false;
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to save campaign: $e',
      );
      return false;
    }
  }

  Future<bool> deleteEntity(String entityId) async {
    if (!_mounted) return false;
    state = state.copyWith(isLoading: true, error: null);

    try {
      final service = ref.read(campaignServiceProvider);
      await service.deleteEntityById(entityId);
      if (!_mounted) return true;
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      if (!_mounted) return false;
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to delete campaign: $e',
      );
      return false;
    }
  }

  void loadEntity(ModelCampaign entity) {
    if (!_mounted) return;
    state = CampaignFormState(
      campaignName: entity.campaignName ?? '',
      validFrom: entity.validFrom,
      validUntil: entity.validUntil,
      poAgencyId: entity.poAgencyId ?? '',
      poBrandId: entity.poBrandId ?? '',
      poTotalAmount: entity.poTotalAmount,
      poLineItemCount: entity.poLineItemCount,
      userComment: entity.userComment,
      profitToBrand: entity.profitToBrand,
      poLat: entity.poLat,
      poLong: entity.poLong,
      status: entity.status ?? 'confirmed',
    );
  }

  void reset() {
    if (!_mounted) return;
    state = CampaignFormState();
  }

  /// Generic save method for ModuleRouteGenerator
  Future<bool> save({String? entityId}) => saveEntity(entityId: entityId);

  /// Generic delete method for ModuleRouteGenerator
  Future<bool> delete(String id) => deleteEntity(id);
}

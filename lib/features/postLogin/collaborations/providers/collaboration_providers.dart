import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../../core/services/entity_service.dart';

import '../adapter/collaboration_adapter.dart';
import '../model/collaboration_model.dart';
import '../service/collaboration_service_impl.dart';
import 'collaboration_summary_controller.dart';

/// Mapper provider
final collaborationMapperProvider = Provider<EntityMapper<ModelCollaboration>>((
  ref,
) {
  return ModelCollaborationMapper();
});

/// Service provider
final collaborationServiceProvider = Provider<CollaborationServiceImpl>((ref) {
  return CollaborationServiceImpl(
    ref.watch(collaborationMapperProvider),
    ref.watch(supabaseClientProvider),
    ref.watch(loggerServiceProvider),
  );
});

/// Adapter provider
final collaborationAdapterProvider = Provider<CollaborationAdapter>((ref) {
  return CollaborationAdapter();
});

/// Real-time stream of all Collaborations with automatic disposal
/// Uses StreamProvider for real-time updates
final collaborationsStreamProvider =
    StreamProvider.autoDispose<List<ModelCollaboration>>((ref) {
      final service = ref.read(collaborationServiceProvider);
      return service.streamEntities();
    });

/// Fetches a single Collaboration by ID
final collaborationByIdProvider = FutureProvider.autoDispose
    .family<ModelCollaboration?, String>((ref, collaborationId) async {
      final service = ref.read(collaborationServiceProvider);
      return await service.fetchById(collaborationId);
    });

/// State provider for managing Collaboration creation/editing
final collaborationFormProvider =
    StateNotifierProvider.autoDispose<
      CollaborationFormNotifier,
      CollaborationFormState
    >((ref) => CollaborationFormNotifier(ref));

/// Form state for Collaboration
/// Form state for Collaboration
class CollaborationFormState {
  final String campaignId;
  final String influencerId;
  final CommissionType commissionType;
  final double? commissionRate;
  final double? fixedAmount;
  final String? barterDescription;
  final double agreedCommissionAmount;
  final bool isAcceptedByInfluencer;
  final bool isLoading;
  final String? error;

  CollaborationFormState({
    this.campaignId = '',
    this.influencerId = '',
    this.commissionType = CommissionType.percentage,
    this.commissionRate,
    this.fixedAmount,
    this.barterDescription,
    this.agreedCommissionAmount = 0.0,
    this.isAcceptedByInfluencer = false,
    this.isLoading = false,
    this.error,
  });

  CollaborationFormState copyWith({
    String? campaignId,
    String? influencerId,
    CommissionType? commissionType,
    double? commissionRate,
    double? fixedAmount,
    String? barterDescription,
    double? agreedCommissionAmount,
    bool? isAcceptedByInfluencer,
    bool? isLoading,
    String? error,
  }) {
    return CollaborationFormState(
      campaignId: campaignId ?? this.campaignId,
      influencerId: influencerId ?? this.influencerId,
      commissionType: commissionType ?? this.commissionType,
      commissionRate: commissionRate ?? this.commissionRate,
      fixedAmount: fixedAmount ?? this.fixedAmount,
      barterDescription: barterDescription ?? this.barterDescription,
      agreedCommissionAmount: agreedCommissionAmount ?? this.agreedCommissionAmount,
      isAcceptedByInfluencer: isAcceptedByInfluencer ?? this.isAcceptedByInfluencer,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Notifier for managing Collaboration form state
class CollaborationFormNotifier extends StateNotifier<CollaborationFormState> {
  final Ref ref;
  bool _mounted = true;

  CollaborationFormNotifier(this.ref) : super(CollaborationFormState());

  @override
  void dispose() {
    _mounted = false;
    super.dispose();
  }

  void updateField(String fieldName, dynamic value) {
    if (!_mounted) return;
    switch (fieldName) {
      case ModelCollaborationFields.campaignId:
        state = state.copyWith(campaignId: value?.toString() ?? '', error: null);
        break;
      case ModelCollaborationFields.influencerId:
        state = state.copyWith(influencerId: value?.toString() ?? '', error: null);
        break;
      case ModelCollaborationFields.commissionType:
        if (value is CommissionType) {
          state = state.copyWith(commissionType: value, error: null);
        } else if (value != null) {
          state = state.copyWith(
            commissionType: CommissionType.fromString(value.toString()),
            error: null,
          );
        }
        break;
      case ModelCollaborationFields.commissionRate:
        state = state.copyWith(
          commissionRate: value != null ? double.tryParse(value.toString()) : null,
          error: null,
        );
        break;
      case ModelCollaborationFields.fixedAmount:
        state = state.copyWith(
          fixedAmount: value != null ? double.tryParse(value.toString()) : null,
          error: null,
        );
        break;
      case ModelCollaborationFields.barterDescription:
        state = state.copyWith(barterDescription: value?.toString(), error: null);
        break;
      case ModelCollaborationFields.agreedCommissionAmount:
        state = state.copyWith(
          agreedCommissionAmount: double.tryParse(value?.toString() ?? '0.0') ?? 0.0,
          error: null,
        );
        break;
      case ModelCollaborationFields.isAcceptedByInfluencer:
        state = state.copyWith(
          isAcceptedByInfluencer: value == true,
          error: null,
        );
        break;
    }
  }

  Future<bool> saveEntity({String? entityId}) async {
    if (!_mounted) return false;
    state = state.copyWith(isLoading: true, error: null);

    try {
      final service = ref.read(collaborationServiceProvider);
      final entity = ModelCollaboration(
        collaborationId: entityId,
        campaignId: state.campaignId.trim(),
        influencerId: state.influencerId.trim(),
        commissionType: state.commissionType,
        commissionRate: state.commissionRate,
        fixedAmount: state.fixedAmount,
        barterDescription: state.barterDescription?.trim(),
        agreedCommissionAmount: state.agreedCommissionAmount,
        isAcceptedByInfluencer: state.isAcceptedByInfluencer,
      );

      if (entityId == null) {
        // Create new collaboration
        await service.create(entity);
      } else {
        // Update existing collaboration
        await service.update(entityId, entity);
      }

      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      if (!_mounted) return false;
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> deleteEntity(String id) async {
    if (!_mounted) return false;
    state = state.copyWith(isLoading: true, error: null);

    try {
      final service = ref.read(collaborationServiceProvider);
      await service.delete(id);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      if (!_mounted) return false;
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  void reset() {
    if (!_mounted) return;
    state = CollaborationFormState();
  }

  /// Generic save method for ModuleRouteGenerator
  Future<bool> save({String? entityId}) => saveEntity(entityId: entityId);

  /// Generic delete method for ModuleRouteGenerator
  Future<bool> delete(String id) => deleteEntity(id);
}

/// Collaboration Stream by PO ID (filtered by parent PO)
final collaborationsByPoIdProvider = StreamProvider.autoDispose
    .family<List<ModelCollaboration>, String>((ref, poId) {
      if (poId.isEmpty) {
        return Stream.value([]);
      }

      final service = ref.read(collaborationServiceProvider);
      return service.streamItemsByPo(poId);
    });

/// Provider for processed PO summary items (sorted/grouped logic)
final processedPoSummaryItemsProvider = Provider.autoDispose
    .family<AsyncValue<List<ModelCollaboration>>, String>((ref, poId) {
      final itemsAsync = ref.watch(collaborationsByPoIdProvider(poId));
      final isGrouped = ref.watch(collaborationSummaryGroupedProvider);

      return itemsAsync.whenData((items) {
        if (!isGrouped) return items;

        final sortedItems = List<ModelCollaboration>.from(items);
        sortedItems.sort((a, b) {
          final typeA =
              a.resolvedLabels['product_type_label']?.toString() ?? '';
          final typeB =
              b.resolvedLabels['product_type_label']?.toString() ?? '';
          return typeA.compareTo(typeB);
        });
        return sortedItems;
      });
    });

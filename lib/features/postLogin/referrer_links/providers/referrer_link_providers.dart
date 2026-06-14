import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../../core/services/entity_service.dart';
import '../adapter/referrer_link_adapter.dart';
import '../model/referrer_link_model.dart';
import '../service/referrer_link_service_impl.dart';

/// Mapper provider
final referrerLinkMapperProvider = Provider<EntityMapper<ModelReferrerLink>>((
  ref,
) {
  return ModelReferrerLinkMapper();
});

/// Service provider
final referrerLinkServiceProvider = Provider<ReferrerLinkServiceImpl>((ref) {
  return ReferrerLinkServiceImpl(
    ref.watch(referrerLinkMapperProvider),
    ref.watch(supabaseClientProvider),
    ref.watch(loggerServiceProvider),
  );
});

/// Adapter provider
final referrerLinkAdapterProvider = Provider<ReferrerLinkAdapter>((ref) {
  return ReferrerLinkAdapter();
});

/// Streams referrer links for a campaign (campaign-level/direct/paid links)
final referrerLinksForCampaignProvider =
    StreamProvider.autoDispose.family<List<ModelReferrerLink>, String>((ref, campaignId) {
      final service = ref.read(referrerLinkServiceProvider);
      return service.streamLinksForCampaign(campaignId);
    });

/// Streams referrer links for a collaboration
final referrerLinksForCollaborationProvider =
    StreamProvider.autoDispose.family<List<ModelReferrerLink>, String>((ref, collaborationId) {
      final service = ref.read(referrerLinkServiceProvider);
      return service.streamLinksForCollaboration(collaborationId);
    });

/// Fetches all Referrer Links with automatic disposal
final referrerLinksStreamProvider =
    StreamProvider.autoDispose<List<ModelReferrerLink>>((ref) {
      final service = ref.read(referrerLinkServiceProvider);
      return service.streamEntities();
    });

/// Fetches a single Referrer Link by ID
final referrerLinkByIdProvider = FutureProvider.autoDispose
    .family<ModelReferrerLink?, String>((ref, referrerLinkId) async {
      final service = ref.read(referrerLinkServiceProvider);
      return await service.fetchById(referrerLinkId);
    });

/// State provider for managing Referrer Link creation/editing
final referrerLinkFormProvider =
    StateNotifierProvider.autoDispose<
      ReferrerLinkFormNotifier,
      ReferrerLinkFormState
    >((ref) => ReferrerLinkFormNotifier(ref));

/// Form state for Referrer Link
class ReferrerLinkFormState {
  final String referrerLinkString;
  final String referrerLinkType;
  final String campaignId;
  final String campaignType;
  final String collaborationId;
  final String referrerLinkSource;
  final bool isLoading;
  final String? error;

  ReferrerLinkFormState({
    this.referrerLinkString = '',
    this.referrerLinkType = 'plain',
    this.campaignId = '',
    this.campaignType = '',
    this.collaborationId = '',
    this.referrerLinkSource = '',
    this.isLoading = false,
    this.error,
  });

  ReferrerLinkFormState copyWith({
    String? referrerLinkString,
    String? referrerLinkType,
    String? campaignId,
    String? campaignType,
    String? collaborationId,
    String? referrerLinkSource,
    bool? isLoading,
    String? error,
  }) {
    return ReferrerLinkFormState(
      referrerLinkString: referrerLinkString ?? this.referrerLinkString,
      referrerLinkType: referrerLinkType ?? this.referrerLinkType,
      campaignId: campaignId ?? this.campaignId,
      campaignType: campaignType ?? this.campaignType,
      collaborationId: collaborationId ?? this.collaborationId,
      referrerLinkSource: referrerLinkSource ?? this.referrerLinkSource,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Notifier for managing Referrer Link form state
class ReferrerLinkFormNotifier extends StateNotifier<ReferrerLinkFormState> {
  final Ref ref;

  ReferrerLinkFormNotifier(this.ref) : super(ReferrerLinkFormState());

  @override
  void dispose() {
    _mounted = false;
    super.dispose();
  }

  bool _mounted = true;

  void updateReferrerLinkString(String value) {
    if (!_mounted) return;
    state = state.copyWith(referrerLinkString: value, error: null);
  }

  void updateReferrerLinkType(String value) {
    if (!_mounted) return;
    state = state.copyWith(referrerLinkType: value, error: null);
  }

  void updateCampaignId(String value) {
    if (!_mounted) return;
    state = state.copyWith(campaignId: value, error: null);
  }

  void updateCampaignType(String value) {
    if (!_mounted) return;
    state = state.copyWith(campaignType: value, error: null);
  }

  void updateCollaborationId(String value) {
    if (!_mounted) return;
    state = state.copyWith(collaborationId: value, error: null);
  }

  void updateReferrerLinkSource(String value) {
    if (!_mounted) return;
    state = state.copyWith(referrerLinkSource: value, error: null);
  }

  void loadEntity(ModelReferrerLink entity) {
    if (!_mounted) return;
    state = ReferrerLinkFormState(
      referrerLinkString: entity.referrerLinkString,
      referrerLinkType: entity.referrerLinkType,
      campaignId: entity.campaignId ?? '',
      campaignType: entity.campaignType,
      collaborationId: entity.collaborationId ?? '',
      referrerLinkSource: entity.referrerLinkSource,
    );
  }

  Future<bool> saveEntity({String? entityId}) async {
    if (!_mounted) return false;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final service = ref.read(referrerLinkServiceProvider);

      final entity = ModelReferrerLink(
        referrerLinkId: entityId,
        referrerLinkString: state.referrerLinkString,
        referrerLinkType: state.referrerLinkType,
        campaignId: state.campaignId.isEmpty ? null : state.campaignId,
        campaignType: state.campaignType,
        collaborationId: state.collaborationId.isEmpty ? null : state.collaborationId,
        referrerLinkSource: state.referrerLinkSource,
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

  Future<bool> deleteEntity(String entityId) async {
    if (!_mounted) return false;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final service = ref.read(referrerLinkServiceProvider);
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
      case ModelReferrerLinkFields.referrerLinkString:
        updateReferrerLinkString(value as String);
        break;
      case ModelReferrerLinkFields.referrerLinkType:
        updateReferrerLinkType(value as String);
        break;
      case ModelReferrerLinkFields.campaignId:
        updateCampaignId(value as String);
        break;
      case ModelReferrerLinkFields.campaignType:
        updateCampaignType(value as String);
        break;
      case ModelReferrerLinkFields.collaborationId:
        updateCollaborationId(value as String);
        break;
      case ModelReferrerLinkFields.referrerLinkSource:
        updateReferrerLinkSource(value as String);
        break;
    }
  }

  /// Generic save method for ModuleRouteGenerator
  Future<bool> save({String? entityId}) => saveEntity(entityId: entityId);

  /// Generic delete method for ModuleRouteGenerator
  Future<bool> delete(String id) => deleteEntity(id);
}

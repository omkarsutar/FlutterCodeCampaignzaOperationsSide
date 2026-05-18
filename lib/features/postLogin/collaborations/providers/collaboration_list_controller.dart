import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../influencers/influencer_barrel.dart';
import '../model/collaboration_model.dart';
import 'collaboration_providers.dart';
import '../service/collaboration_service_impl.dart';

// State definition
class CollaborationListState {
  final bool isLoading;
  final String? error;
  final List<ModelCollaboration> items;
  final List<ModelInfluencer> influencers;
  final String? lastModifiedItemId;
  final bool isNewItemAdded;

  const CollaborationListState({
    this.isLoading = true,
    this.error,
    this.items = const [],
    this.influencers = const [],
    this.lastModifiedItemId,
    this.isNewItemAdded = false,
  });

  CollaborationListState copyWith({
    bool? isLoading,
    String? error,
    List<ModelCollaboration>? items,
    List<ModelInfluencer>? influencers,
    String? Function()? lastModifiedItemId,
    bool? isNewItemAdded,
  }) {
    return CollaborationListState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      items: items ?? this.items,
      influencers: influencers ?? this.influencers,
      lastModifiedItemId: lastModifiedItemId != null
          ? lastModifiedItemId()
          : this.lastModifiedItemId,
      isNewItemAdded: isNewItemAdded ?? this.isNewItemAdded,
    );
  }
}

// Controller
class CollaborationListController
    extends AutoDisposeFamilyAsyncNotifier<CollaborationListState, String> {
  CollaborationServiceImpl get _service =>
      ref.read(collaborationServiceProvider);
  Timer? _clearTimer;

  @override
  Future<CollaborationListState> build(String poId) async {
    try {
      // Use cached influencers stream
      final influencers = await ref.watch(influencersStreamProvider.future);

      // Fetch Collaborations (service now handles sorting)
      final items = poId.isEmpty
          ? await _service.fetchAll()
          : await _service.fetchEntitiesByPo(poId);

      return CollaborationListState(
        isLoading: false,
        items: items,
        influencers: influencers,
      );
    } catch (e) {
      return CollaborationListState(isLoading: false, error: e.toString());
    }
  }

  Future<bool> addItem(ModelCollaboration item, String poId) async {
    try {
      final currentData = state.value;
      if (currentData == null) return false;

      final newItem = await _service.insertEntityForPo(item, poId);
      state = AsyncValue.data(
        currentData.copyWith(
          items: [newItem, ...currentData.items],
          lastModifiedItemId: () => newItem.collaborationId,
          isNewItemAdded: true,
        ),
      );
      _startClearTimer();
      return true;
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      return false;
    }
  }

  void _startClearTimer() {
    _clearTimer?.cancel();
    _clearTimer = Timer(const Duration(milliseconds: 1500), () {
      final currentData = state.value;
      if (currentData != null) {
        state = AsyncValue.data(
          currentData.copyWith(
            lastModifiedItemId: () => null,
            isNewItemAdded: false,
          ),
        );
      }
    });
  }

  Future<bool> updateItem(
    ModelCollaboration item,
    String poId, {
    bool moveToTop = false,
  }) async {
    try {
      if (item.collaborationId == null) {
        throw Exception("Item ID missing for update");
      }
      await _service.update(item.collaborationId!, item);
      final currentData = state.value;
      if (currentData != null) {
        List<ModelCollaboration> updatedItems;
        if (moveToTop) {
          final others = currentData.items.where(
            (i) => i.collaborationId != item.collaborationId,
          );
          updatedItems = [item, ...others];
        } else {
          updatedItems = currentData.items
              .map((i) => i.collaborationId == item.collaborationId ? item : i)
              .toList();
        }

        state = AsyncValue.data(
          currentData.copyWith(
            items: updatedItems,
            lastModifiedItemId: () => item.collaborationId,
            isNewItemAdded: false,
          ),
        );
        _startClearTimer();
      } else {
        state = await AsyncValue.guard(() => build(poId));
      }
      return true;
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      return false;
    }
  }

  Future<bool> deleteItem(String itemId, String poId) async {
    try {
      await _service.delete(itemId);
      state = await AsyncValue.guard(() => build(poId));
      return true;
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      return false;
    }
  }
}

final collaborationListControllerProvider = AsyncNotifierProvider.autoDispose
    .family<CollaborationListController, CollaborationListState, String>(
      () => CollaborationListController(),
    );

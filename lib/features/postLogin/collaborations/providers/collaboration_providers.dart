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
class CollaborationFormState {
  final String poId;
  final String itemId;
  final int itemQuantity;
  final double itemPrice;
  final double itemSellRate;
  final double? profitToShop;
  final bool isLoading;
  final String? error;

  CollaborationFormState({
    this.poId = '',
    this.itemId = '',
    this.itemQuantity = 0,
    this.itemPrice = 0.0,
    this.itemSellRate = 0.0,
    this.profitToShop,
    this.isLoading = false,
    this.error,
  });

  CollaborationFormState copyWith({
    String? poId,
    String? itemId,
    int? itemQuantity,
    double? itemPrice,
    double? itemSellRate,
    double? profitToShop,
    bool? isLoading,
    String? error,
  }) {
    return CollaborationFormState(
      poId: poId ?? this.poId,
      itemId: itemId ?? this.itemId,
      itemQuantity: itemQuantity ?? this.itemQuantity,
      itemPrice: itemPrice ?? this.itemPrice,
      itemSellRate: itemSellRate ?? this.itemSellRate,
      profitToShop: profitToShop ?? this.profitToShop,
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

  void updatePoId(String poId) {
    if (!_mounted) return;
    state = state.copyWith(poId: poId, error: null);
  }

  void updateItemId(String itemId) {
    if (!_mounted) return;
    state = state.copyWith(itemId: itemId, error: null);
  }

  void updateItemQuantity(int quantity) {
    if (!_mounted) return;
    state = state.copyWith(itemQuantity: quantity, error: null);
  }

  void updateItemPrice(double price) {
    if (!_mounted) return;
    state = state.copyWith(itemPrice: price, error: null);
  }

  void updateItemSellRate(double sellRate) {
    if (!_mounted) return;
    state = state.copyWith(itemSellRate: sellRate, error: null);
  }

  void updateProfitToShop(double? profit) {
    if (!_mounted) return;
    state = state.copyWith(profitToShop: profit, error: null);
  }

  void setLoading(bool isLoading) {
    if (!_mounted) return;
    state = state.copyWith(isLoading: isLoading);
  }

  void setError(String? error) {
    if (!_mounted) return;
    state = state.copyWith(error: error);
  }

  void reset() {
    if (!_mounted) return;
    state = CollaborationFormState();
  }
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

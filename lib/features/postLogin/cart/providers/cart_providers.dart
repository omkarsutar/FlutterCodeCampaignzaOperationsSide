import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../collaborations/model/collaboration_model.dart';
import '../../influencers/influencer_barrel.dart';

class CartState {
  final List<ModelCollaboration> items;
  final bool isLoading;
  final String? error;
  final String? lastModifiedItemId;
  final bool isPromptAcknowledged;
  final bool isNewItemAdded;

  final String? brandId;
  final String? agencyId;
  final String? campaignId;
  final String? status;
  final int? itemCountInPo;

  CartState({
    this.items = const [],
    this.isLoading = false,
    this.error,
    this.lastModifiedItemId,
    this.isPromptAcknowledged = false,
    this.isNewItemAdded = false,
    this.brandId,
    this.agencyId,
    this.campaignId,
    this.status,
    this.itemCountInPo,
  });

  double get totalAmount =>
      items.fold(0, (sum, item) => sum + (item.agreedCommissionAmount ?? 0));
  double get totalProfit => 0.0;

  bool get isReadOnly {
    if (status == null) return false;
    final s = status!.toLowerCase();
    return s != 'pending' && s != 'confirmed';
  }

  CartState copyWith({
    List<ModelCollaboration>? items,
    bool? isLoading,
    String? error,
    String? Function()? lastModifiedItemId,
    bool? isPromptAcknowledged,
    bool? isNewItemAdded,
    String? Function()? brandId,
    String? Function()? agencyId,
    String? Function()? campaignId,
    String? Function()? status,
    int? Function()? itemCountInPo,
  }) {
    return CartState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      lastModifiedItemId: lastModifiedItemId != null
          ? lastModifiedItemId()
          : this.lastModifiedItemId,
      isPromptAcknowledged: isPromptAcknowledged ?? this.isPromptAcknowledged,
      isNewItemAdded: isNewItemAdded ?? this.isNewItemAdded,
      brandId: brandId != null ? brandId() : this.brandId,
      agencyId: agencyId != null ? agencyId() : this.agencyId,
      campaignId: campaignId != null ? campaignId() : this.campaignId,
      status: status != null ? status() : this.status,
      itemCountInPo: itemCountInPo != null
          ? itemCountInPo()
          : this.itemCountInPo,
    );
  }
}

class CartNotifier extends Notifier<CartState> {
  Timer? _clearTimer;

  @override
  CartState build() {
    return CartState();
  }

  void setItems(List<ModelCollaboration> items) {
    state = state.copyWith(
      items: items,
      isLoading: false,
      isPromptAcknowledged: false, // Reset for newly loaded items
    );
  }

  void loadOrderIntoCart({
    required String brandId,
    required String agencyId,
    required String campaignId,
    required String status,
    required int itemCountInPo,
    required List<ModelCollaboration> items,
  }) {
    state = state.copyWith(
      items: items,
      brandId: () => brandId,
      agencyId: () => agencyId,
      campaignId: () => campaignId,
      status: () => status,
      itemCountInPo: () => itemCountInPo,
      isLoading: false,
      isPromptAcknowledged: true,
    );
  }

  void setOrderDetails({
    String? brandId,
    String? agencyId,
    String? campaignId,
    String? status,
    int? itemCountInPo,
  }) {
    state = state.copyWith(
      brandId: () => brandId,
      agencyId: () => agencyId,
      campaignId: () => campaignId,
      status: () => status,
      itemCountInPo: () => itemCountInPo,
    );
  }

  void markPromptAsAcknowledged() {
    state = state.copyWith(isPromptAcknowledged: true);
  }

  void addItem(ModelCollaboration item) {
    // Check if influencer already exists in cart, if so update/replace it
    final index = state.items.indexWhere((i) => i.influencerId == item.influencerId);
    if (index != -1) {
      final otherItems = state.items
          .where((i) => i.influencerId != item.influencerId)
          .toList();
      state = state.copyWith(
        items: [item, ...otherItems],
        lastModifiedItemId: () => item.collaborationId,
        isPromptAcknowledged: true,
        isNewItemAdded: true,
      );
      _startClearTimer();
    } else {
      // Assign a unique local ID if missing
      final itemWithId = item.collaborationId == null
          ? item.copyWith(
              collaborationId: DateTime.now().microsecondsSinceEpoch.toString(),
            )
          : item;
      state = state.copyWith(
        items: [itemWithId, ...state.items],
        lastModifiedItemId: () => itemWithId.collaborationId,
        isPromptAcknowledged: true, // Manual action acknowledges the state
        isNewItemAdded: true,
      );
      _startClearTimer();
    }
  }

  void _startClearTimer() {
    _clearTimer?.cancel();
    _clearTimer = Timer(const Duration(milliseconds: 1500), () {
      state = state.copyWith(
        lastModifiedItemId: () => null,
        isNewItemAdded: false,
      );
    });
  }

  void updateItem(ModelCollaboration updatedItem, {bool moveToTop = false}) {
    if (moveToTop) {
      // Remove the item from its current position and prepend it
      final otherItems = state.items
          .where((item) => item.collaborationId != updatedItem.collaborationId)
          .toList();
      state = state.copyWith(
        items: [updatedItem, ...otherItems],
        lastModifiedItemId: () => updatedItem.collaborationId,
        isPromptAcknowledged: true,
        isNewItemAdded: false,
      );
      _startClearTimer();
    } else {
      // Standard update in place
      state = state.copyWith(
        items: state.items.map((item) {
          return item.collaborationId == updatedItem.collaborationId
              ? updatedItem
              : item;
        }).toList(),
        lastModifiedItemId: () => updatedItem.collaborationId,
        isPromptAcknowledged: true,
        isNewItemAdded: false,
      );
      _startClearTimer();
    }
  }

  void updateQuantity(String collaborationId, double change) {
    // Dummy stub for backward compatibility
  }

  void removeItem(String collaborationId) {
    state = state.copyWith(
      items: state.items
          .where((item) => item.collaborationId != collaborationId)
          .toList(),
    );
  }

  void clearCart() {
    state = state.copyWith(
      items: [],
      isPromptAcknowledged: false,
      brandId: () => null,
      agencyId: () => null,
      campaignId: () => null,
      status: () => null,
      itemCountInPo: () => null,
    );
  }
}

final cartProvider = NotifierProvider<CartNotifier, CartState>(() {
  return CartNotifier();
});

final isEditingCartItemProvider = StateProvider<bool>((ref) => false);

final selectedInfluencerForAdditionProvider = StateProvider<ModelInfluencer?>(
  (ref) => null,
);

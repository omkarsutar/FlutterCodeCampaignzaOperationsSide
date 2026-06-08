import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/config/module_config.dart';
import '../../users/providers/user_providers.dart';
import 'brand_providers.dart';
import 'brands_by_po_status_provider.dart';

class BrandListState {
  final String searchQuery;
  final String? selectedRouteId;
  final SortingConfig? currentSorting;

  const BrandListState({
    this.searchQuery = '',
    this.selectedRouteId,
    this.currentSorting,
  });

  BrandListState copyWith({
    String? searchQuery,
    String? selectedRouteId,
    SortingConfig? currentSorting,
  }) {
    return BrandListState(
      searchQuery: searchQuery ?? this.searchQuery,
      selectedRouteId: selectedRouteId ?? this.selectedRouteId,
      currentSorting: currentSorting ?? this.currentSorting,
    );
  }
}

class BrandListController extends AutoDisposeNotifier<BrandListState> {
  @override
  BrandListState build() {
    // Initialize with selected agency
    final selectedAgencyId = ref.watch(selectedAgencyIdProvider);
    final service = ref.read(brandServiceProvider);

    return BrandListState(
      selectedRouteId: selectedAgencyId,
      currentSorting: service.sortField != null
          ? SortingConfig(
              field: service.sortField!,
              sortAscending: service.sortAscending,
            )
          : null,
    );
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query.toLowerCase());
  }

  void setRouteId(String? agencyId) {
    state = state.copyWith(selectedRouteId: agencyId);
  }

  void setSorting(SortingConfig? sorting) {
    if (sorting != null) {
      ref
          .read(brandServiceProvider)
          .setSortingConfig(sorting.field, sorting.sortAscending);
    }
    state = state.copyWith(currentSorting: sorting);
    refreshData();
  }

  Future<void> refreshData() async {
    ref.invalidate(regularBrandsProvider(state.selectedRouteId));
    await ref.read(regularBrandsProvider(state.selectedRouteId).future);
  }
}

final brandListControllerProvider =
    NotifierProvider.autoDispose<BrandListController, BrandListState>(
      () => BrandListController(),
    );

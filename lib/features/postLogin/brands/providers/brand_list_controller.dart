import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/user_profile_state_provider.dart';
import '../../../../core/config/module_config.dart';
import 'brand_providers.dart';

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
    // Initialize with user's preferred route
    final profile = ref.watch(userProfileStateProvider).profile;
    final service = ref.read(brandServiceProvider);

    return BrandListState(
      selectedRouteId: profile?.preferredRouteId,
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

  void setRouteId(String? routeId) {
    state = state.copyWith(selectedRouteId: routeId);
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
    final _ = ref.refresh(brandsStreamProvider.future);
  }
}

final brandListControllerProvider =
    NotifierProvider.autoDispose<BrandListController, BrandListState>(
      () => BrandListController(),
    );

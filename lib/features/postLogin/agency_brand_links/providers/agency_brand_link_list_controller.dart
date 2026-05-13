import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/user_profile_state_provider.dart';
import '../../../../core/services/entity_service.dart';
import '../model/agency_brand_link_model.dart';
import 'agency_brand_link_providers.dart';

class AgencyBrandLinkListState {
  final String searchQuery;
  final String? selectedAgencyId;
  final List<ModelAgencyBrandLink> localEntities;
  final bool isSearchActive; // If we want to move this here too

  const AgencyBrandLinkListState({
    this.searchQuery = '',
    this.selectedAgencyId,
    this.localEntities = const [],
    this.isSearchActive = false,
  });

  AgencyBrandLinkListState copyWith({
    String? searchQuery,
    String? selectedAgencyId,
    List<ModelAgencyBrandLink>? localEntities,
    bool? isSearchActive,
  }) {
    return AgencyBrandLinkListState(
      searchQuery: searchQuery ?? this.searchQuery,
      selectedAgencyId: selectedAgencyId ?? this.selectedAgencyId,
      localEntities: localEntities ?? this.localEntities,
      isSearchActive: isSearchActive ?? this.isSearchActive,
    );
  }
}

class AgencyBrandLinkListController
    extends AutoDisposeNotifier<AgencyBrandLinkListState> {
  @override
  AgencyBrandLinkListState build() {
    // Initialize with user's preferred route
    final profile = ref.watch(userProfileStateProvider).profile;
    return AgencyBrandLinkListState(selectedAgencyId: profile?.preferredAgencyId);
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query.toLowerCase());
  }

  void setAgencyId(String? agencyId) {
    if (agencyId == null) return;
    state = state.copyWith(
      selectedAgencyId: agencyId,
      localEntities: [], // Clear on new route
    );
  }

  /// Syncs local entities with data from the source/provider
  void setEntities(List<ModelAgencyBrandLink> entities) {
    // Only update if the list content has actually changed or we are empty?
    // For now, always sync to keep fresh data.
    state = state.copyWith(localEntities: entities);
  }

  @override
  bool updateShouldNotify(
    AgencyBrandLinkListState previous,
    AgencyBrandLinkListState next,
  ) {
    return previous.searchQuery != next.searchQuery ||
        previous.selectedAgencyId != next.selectedAgencyId ||
        previous.isSearchActive != next.isSearchActive ||
        previous.localEntities != next.localEntities;
  }

  // Reorder logic
  Future<void> reorder(int oldIndex, int newIndex, String idField) async {
    if (newIndex > oldIndex) newIndex -= 1;

    final currentList = state.localEntities;
    final originalList = List<ModelAgencyBrandLink>.from(currentList);

    // 1. Optimistic Update
    final items = List<ModelAgencyBrandLink>.from(currentList);
    final item = items.removeAt(oldIndex);
    items.insert(newIndex, item);

    final updatedList = items.asMap().entries.map((entry) {
      final index = entry.key;
      final entity = entry.value;
      return entity.copyWith(visitOrder: index + 1);
    }).toList();

    state = state.copyWith(localEntities: updatedList);

    // 2. Call Backend
    final movedEntity = updatedList[newIndex];
    final adapter = ref.read(agencyBrandLinkAdapterProvider);
    final linkId = adapter.getId(movedEntity, idField).toString();
    final newPosition = newIndex + 1;

    try {
      final service = ref.read(agencyBrandLinkServiceProvider);
      await service.reorderAgencyBrandLink(linkId, newPosition);
    } catch (e) {
      // Revert on error
      state = state.copyWith(localEntities: originalList);
      rethrow; // Let UI handle error display
    }
  }

  // Helper filter logic
  List<ModelAgencyBrandLink> getFilteredEntities({
    bool Function(ModelAgencyBrandLink, String)? customMatcher,
    List<String>? searchFields,
    required EntityAdapter<ModelAgencyBrandLink> adapter,
  }) {
    if (state.searchQuery.isEmpty) return state.localEntities;

    return state.localEntities.where((entity) {
      if (customMatcher != null) {
        return customMatcher(entity, state.searchQuery);
      }

      if (searchFields != null && searchFields.isNotEmpty) {
        for (final fieldName in searchFields) {
          dynamic value;
          if (fieldName.endsWith('_label')) {
            final base = fieldName.replaceAll(RegExp(r'_label$'), '');
            value = adapter.getLabelValue(entity, base);
          } else {
            value = adapter.getFieldValue(entity, fieldName);
          }
          if (value != null &&
              value.toString().toLowerCase().contains(state.searchQuery)) {
            return true;
          }
        }
        return false;
      }
      return true;
    }).toList();
  }
}

final agencyBrandLinkListControllerProvider =
    NotifierProvider.autoDispose<
      AgencyBrandLinkListController,
      AgencyBrandLinkListState
    >(() => AgencyBrandLinkListController());

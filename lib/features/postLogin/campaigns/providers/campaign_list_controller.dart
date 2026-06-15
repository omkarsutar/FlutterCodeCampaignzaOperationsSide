import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/entity_service.dart';
import '../../../../core/config/module_config.dart';
import '../model/campaign_model.dart';
import '../providers/campaign_providers.dart';

/// State for Campaign List
class CampaignListState {
  final String searchQuery;
  final String? selectedStatus; // Added status filter
  final List<ModelCampaign> allCampaigns; // Original unfiltered list
  final List<ModelCampaign> filteredCampaigns; // Filtered results
  final SortingConfig? currentSorting;
  final bool isLoading;
  final String? error;

  const CampaignListState({
    this.searchQuery = '',
    this.selectedStatus,
    this.allCampaigns = const [],
    this.filteredCampaigns = const [],
    this.currentSorting,
    this.isLoading = true,
    this.error,
  });

  CampaignListState copyWith({
    String? searchQuery,
    String? selectedStatus,
    bool clearStatus = false,
    List<ModelCampaign>? allCampaigns,
    List<ModelCampaign>? filteredCampaigns,
    SortingConfig? currentSorting,
    bool? isLoading,
    String? error,
  }) {
    return CampaignListState(
      searchQuery: searchQuery ?? this.searchQuery,
      selectedStatus: clearStatus
          ? null
          : (selectedStatus ?? this.selectedStatus),
      allCampaigns: allCampaigns ?? this.allCampaigns,
      filteredCampaigns: filteredCampaigns ?? this.filteredCampaigns,
      currentSorting: currentSorting ?? this.currentSorting,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class CampaignListController
    extends AutoDisposeFamilyNotifier<CampaignListState, String> {
  String? get brandId {
    // Check if arg is a brand ID (e.g. from CampaignListByBrandId)
    // In this app, arg is often 'campaignList' or a specific brand ID
    return arg == 'campaignList' ? null : arg;
  }

  @override
  CampaignListState build(String arg) {
    final posAsync = ref.watch(campaignsStreamProvider(brandId));
    final service = ref.read(campaignServiceProvider);
    final searchQuery = ref.watch(campaignSearchProvider(arg));
    final statusFilter = ref.watch(campaignStatusFilterProvider(arg));

    if (posAsync.isLoading) {
      return CampaignListState(
        isLoading: true,
        searchQuery: searchQuery,
        selectedStatus: statusFilter,
        currentSorting: service.sortField != null
            ? SortingConfig(
                field: service.sortField!,
                sortAscending: service.sortAscending,
              )
            : null,
      );
    }

    if (posAsync.hasError) {
      return CampaignListState(
        isLoading: false,
        searchQuery: searchQuery,
        selectedStatus: statusFilter,
        error: 'Failed to load campaigns: ${posAsync.error}',
        currentSorting: service.sortField != null
            ? SortingConfig(
                field: service.sortField!,
                sortAscending: service.sortAscending,
              )
            : null,
      );
    }

    final pos = posAsync.value ?? [];
    final adapter = ref.read(campaignAdapterProvider);

    // Use watched state for filtering
    final filteredAndSorted = _filterAndSortCampaigns(
      pos,
      searchQuery,
      statusFilter,
      adapter,
    );

    return CampaignListState(
      searchQuery: searchQuery,
      selectedStatus: statusFilter,
      allCampaigns: pos,
      filteredCampaigns: filteredAndSorted,
      currentSorting: service.sortField != null
          ? SortingConfig(
              field: service.sortField!,
              sortAscending: service.sortAscending,
            )
          : null,
      isLoading: false,
      error: null,
    );
  }

  /// Updates the search query and filters the list
  void setSearchQuery(String query, {List<String>? searchFields}) {
    // Update persistent provider - this will trigger build automatically
    ref.read(campaignSearchProvider(arg).notifier).state = query.toLowerCase();
  }

  /// Updates the status filter and filters the list
  void setStatusFilter(String? status, {List<String>? searchFields}) {
    // Update persistent provider - this will trigger build automatically
    ref.read(campaignStatusFilterProvider(arg).notifier).state = status;
  }

  void setSorting(SortingConfig? sorting, {List<String>? searchFields}) {
    if (sorting != null) {
      ref
          .read(campaignServiceProvider)
          .setSortingConfig(sorting.field, sorting.sortAscending);
    }

    state = state.copyWith(
      currentSorting: sorting,
      isLoading: true, // Trigger loading state during refresh
    );

    refreshData();
  }

  /// Filters and sorts campaigns
  List<ModelCampaign> _filterAndSortCampaigns(
    List<ModelCampaign> pos,
    String query,
    String? status,
    EntityAdapter<ModelCampaign> adapter, {
    List<String>? searchFields,
  }) {
    var result = pos;

    // 1. Campaign Type Filter
    if (status != null && status.isNotEmpty && status.toLowerCase() != 'all') {
      result = result.where((po) {
        final type = po.effectiveCampaignType;
        if (status.toLowerCase() == 'paid ads') {
          return type == CampaignType.paidAds;
        } else if (status.toLowerCase() == 'direct') {
          return type == CampaignType.directBrandPromotions;
        } else if (status.toLowerCase() == 'collabs') {
          return type == CampaignType.influencerCollaborations;
        }
        return true;
      }).toList();
    }

    // 2. Search Filter
    if (query.isNotEmpty) {
      result = result.where((po) {
        // Use provided search fields if available
        if (searchFields != null && searchFields.isNotEmpty) {
          for (final fieldName in searchFields) {
            dynamic value;
            if (fieldName.endsWith('_label')) {
              final baseFieldName = fieldName.replaceFirst(
                RegExp(r'_label$'),
                '',
              );
              value = adapter.getLabelValue(po, baseFieldName);
            } else {
              value = adapter.getFieldValue(po, fieldName);
            }

            if (value != null &&
                value.toString().toLowerCase().contains(query)) {
              return true;
            }
          }
        } else {
          // Default fallback search logic
          if (po.poId?.toLowerCase().contains(query) ?? false) return true;

          final brandName = adapter
              .getLabelValue(po, ModelCampaignFields.poBrandId)
              ?.toString()
              .toLowerCase();
          if (brandName?.contains(query) ?? false) return true;

          final routeName = adapter
              .getLabelValue(po, ModelCampaignFields.poAgencyId)
              ?.toString()
              .toLowerCase();
          if (routeName?.contains(query) ?? false) return true;

          if (po.effectiveStatusLabel.toLowerCase().contains(query)) return true;
          if (po.userComment?.toLowerCase().contains(query) ?? false) {
            return true;
          }
        }

        return false;
      }).toList();
    }

    return result;
  }

  /// Refreshes the campaigns data
  Future<void> refreshData() async {
    ref.invalidate(campaignsStreamProvider(brandId));
    await ref.read(campaignsStreamProvider(brandId).future);
  }

  /// Clears the search query
  void clearSearch({List<String>? searchFields}) {
    setSearchQuery('', searchFields: searchFields);
  }

  /// Resets all filters (search and status)
  void resetFilters({List<String>? searchFields}) {
    ref.read(campaignSearchProvider(arg).notifier).state = '';
    ref.read(campaignStatusFilterProvider(arg).notifier).state = null;
  }
}

/// Provider for Campaign List Controller
/// Key: 'campaignList' to isolate state per page instance
final campaignListControllerProvider = NotifierProvider.autoDispose
    .family<CampaignListController, CampaignListState, String>(
      () => CampaignListController(),
    );

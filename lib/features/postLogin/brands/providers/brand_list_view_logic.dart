import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../model/brand_model.dart';
import 'brand_list_controller.dart';
import 'brand_providers.dart';
import 'brands_by_po_status_provider.dart';

class ProcessedBrandListData {
  final List<ModelBrand> filteredBrands;
  final int? brandCount;
  final bool isLoading;
  final Object? error;

  ProcessedBrandListData({
    required this.filteredBrands,
    this.brandCount,
    this.isLoading = false,
    this.error,
  });
}

final brandListViewLogicProvider = Provider.autoDispose<ProcessedBrandListData>((ref) {
  final listState = ref.watch(brandListControllerProvider);
  final adapter = ref.watch(brandAdapterProvider);

  // Configuration (matching BrandRoutesJson)
  const agencyIdField = 'brands_primary_agency';
  const searchFields = ['brand_name', 'brand_person_name'];

  List<ModelBrand> filterAndSort(List<ModelBrand> entities) {
    var result = entities;

    // 1. Route Filter
    if (listState.selectedRouteId != null) {
      result = result.where((entity) {
        final routeVal = adapter.getFieldValue(entity, agencyIdField);
        return routeVal.toString() == listState.selectedRouteId;
      }).toList();
    }

    // 2. Search Filter
    if (listState.searchQuery.isNotEmpty) {
      final query = listState.searchQuery.toLowerCase();
      result = result.where((entity) {
        for (final fieldName in searchFields) {
          dynamic value;
          if (fieldName.endsWith('_label')) {
            final baseFieldName = fieldName.replaceFirst(
              RegExp(r'_label$'),
              '',
            );
            value = adapter.getLabelValue(entity, baseFieldName);
          } else {
            value = adapter.getFieldValue(entity, fieldName);
          }

          if (value != null &&
              value.toString().toLowerCase().contains(query)) {
            return true;
          }
        }
        return false;
      }).toList();
    }

    return result;
  }

  // Regular list
  final regularBrandsAsync = ref.watch(
    regularBrandsProvider(listState.selectedRouteId),
  );

  return regularBrandsAsync.when(
    data: (entityList) {
      final filtered = filterAndSort(entityList.cast<ModelBrand>());
      return ProcessedBrandListData(
        filteredBrands: filtered,
        brandCount: filtered.length,
      );
    },
    loading: () =>
        ProcessedBrandListData(filteredBrands: [], isLoading: true),
    error: (err, _) =>
        ProcessedBrandListData(filteredBrands: [], error: err),
  );
});

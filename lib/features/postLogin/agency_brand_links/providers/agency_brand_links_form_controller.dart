import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../../core/config/field_config.dart';
import '../../../../../core/services/entity_service.dart';
import '../model/agency_brand_link_model.dart';
import 'agency_brand_link_controller.dart';

class AgencyBrandLinksFormState {
  final bool isLoading;
  final String? error;
  final bool isSuccess;
  final Map<String, List<Map<String, dynamic>>> dropdownOptions;
  final Map<String, dynamic>? initialData;

  const AgencyBrandLinksFormState({
    this.isLoading = false,
    this.error,
    this.isSuccess = false,
    this.dropdownOptions = const {},
    this.initialData,
  });

  AgencyBrandLinksFormState copyWith({
    bool? isLoading,
    String? error,
    bool? isSuccess,
    Map<String, List<Map<String, dynamic>>>? dropdownOptions,
    Map<String, dynamic>? initialData,
  }) {
    return AgencyBrandLinksFormState(
      isLoading: isLoading ?? this.isLoading,
      error: error, // Nullable update
      isSuccess: isSuccess ?? this.isSuccess,
      dropdownOptions: dropdownOptions ?? this.dropdownOptions,
      initialData: initialData ?? this.initialData,
    );
  }
}

class AgencyBrandLinksFormController
    extends AutoDisposeFamilyNotifier<AgencyBrandLinksFormState, String> {
  @override
  AgencyBrandLinksFormState build(String arg) {
    return const AgencyBrandLinksFormState();
  }

  // Route Brand Links specific field validation
  bool validateAgencyBrandLinkField(String fieldName, dynamic value) {
    return AgencyBrandLinkController.validateAgencyBrandLinkField(
      fieldName,
      value,
    );
  }

  // Enhanced dropdown loading with agency_brand_links specific logic
  Future<void> loadDropdownOptions(List<FieldConfig> fieldConfigs) async {
    final newOptions = Map<String, List<Map<String, dynamic>>>.from(
      state.dropdownOptions,
    );

    for (var field in fieldConfigs) {
      if (field.type != FieldType.dropdown) continue;
      if (field.dropdownSource == null) continue;

      try {
        final source = field.dropdownSource!;
        final data = await Supabase.instance.client
            .from(source.table)
            .select()
            .order(source.labelKey, ascending: true);

        newOptions[field.name] = List<Map<String, dynamic>>.from(data);
      } catch (e) {
        debugPrint('Error loading options for ${field.name}: $e');
      }
    }

    state = state.copyWith(dropdownOptions: newOptions);
  }

  // Enhanced entity loading with agency_brand_links specific field mapping
  Future<void> loadEntity<T>({
    required String entityId,
    required AutoDisposeFutureProviderFamily<T?, String> entityByIdProvider,
    required Provider<EntityAdapter<T>> adapterProvider,
    required List<FieldConfig> fieldConfigs,
    Map<String, dynamic> Function(T entity)? initialValuesMapper,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final entity = await ref.read(entityByIdProvider(entityId).future);

      if (entity != null) {
        Map<String, dynamic> values;

        if (initialValuesMapper != null) {
          values = initialValuesMapper(entity);
        } else {
          final adapter = ref.read(adapterProvider);
          values = {};
          for (var field in fieldConfigs) {
            if (!field.visibleInForm) continue;

            final val = adapter.getFieldValue(entity, field.name);
            if (val != null) {
              if (field.type == FieldType.doubleField ||
                  field.type == FieldType.intField ||
                  field.type == FieldType.integer) {
                values[field.name] = val.toString();
              } else {
                values[field.name] = val;
              }
            }
          }
        }
        state = state.copyWith(isLoading: false, initialData: values);
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Route Brand Link not found',
        );
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // Enhanced save with agency_brand_links specific validation
  Future<void> saveEntity({
    required Future<bool> Function(WidgetRef, Map<String, dynamic>, String?)
    onSave,
    required Map<String, dynamic> fieldValues,
    String? entityId,
    required WidgetRef ref,
  }) async {
    state = state.copyWith(isLoading: true, error: null, isSuccess: false);

    try {
      // Route Brand Links specific validation before save
      if (!_validateAgencyBrandLinkData(fieldValues)) {
        state = state.copyWith(
          isLoading: false,
          error: 'Invalid route brand link data',
        );
        return;
      }

      final success = await onSave(ref, fieldValues, entityId);
      if (success) {
        state = state.copyWith(isLoading: false, isSuccess: true);
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to save route brand link',
        );
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // Route Brand Links specific data validation
  bool _validateAgencyBrandLinkData(Map<String, dynamic> fieldValues) {
    // Check required fields
    final agencyId =
        fieldValues['routeid'] ??
        fieldValues[ModelAgencyBrandLinkFields.agencyId];
    final brandId =
        fieldValues['brandid'] ??
        fieldValues[ModelAgencyBrandLinkFields.brandId];

    if (agencyId == null || agencyId.toString().trim().isEmpty) {
      return false;
    }

    if (brandId == null || brandId.toString().trim().isEmpty) {
      return false;
    }

    // Validate visit order if present
    final visitOrder =
        fieldValues['visitorder'] ??
        fieldValues[ModelAgencyBrandLinkFields.visitOrder];
    if (visitOrder != null &&
        !AgencyBrandLinkController.validateAgencyBrandLinkField(
          ModelAgencyBrandLinkFields.visitOrder,
          visitOrder,
        )) {
      return false;
    }

    return true;
  }

  // Route Brand Links specific helper methods
  String generateAgencyBrandLinkName({
    required String agencyName,
    required String brandName,
  }) {
    return '$agencyName - $brandName';
  }

  bool isAgencyBrandLinkActive(Map<String, dynamic> fieldValues) {
    // Check if there's an active status field
    final isActive = fieldValues['is_active'];
    if (isActive is bool) {
      return isActive;
    }

    // Check other common active field names
    final active = fieldValues['active'];
    final status = fieldValues['status'];

    return (active is bool && active) ||
        (status is String && status.toLowerCase() == 'active');
  }
}

final agencyBrandLinksFormControllerProvider = NotifierProvider.autoDispose
    .family<AgencyBrandLinksFormController, AgencyBrandLinksFormState, String>(
      () => AgencyBrandLinksFormController(),
    );

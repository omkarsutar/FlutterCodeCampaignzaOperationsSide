import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/utils/date_utils.dart';
import '../model/agency_brand_link_model.dart';

/// Shared base controller for Agency Brand Links module
/// Contains common functionality used across list, form, and view controllers
class AgencyBrandLinkController {
  // Common imports and references
  static const String moduleName = 'agency_brand_links';

  // Common field detection methods
  static bool isLocationUrlField(String fieldName, String? value) {
    final lowerName = fieldName.toLowerCase();
    final isLocationField =
        lowerName.contains('location') || lowerName.contains('map');
    final isGoogleMapsUrl = value?.contains('google.com/maps') ?? false;
    return isLocationField || isGoogleMapsUrl;
  }

  static bool isPhoneField(String fieldName) {
    final lowerName = fieldName.toLowerCase();
    return lowerName.contains('phone') || lowerName.contains('mobile');
  }

  static bool isAgencyField(String fieldName) {
    final lowerName = fieldName.toLowerCase();
    return lowerName.contains('agency') || lowerName.contains('route');
  }

  static bool isBrandField(String fieldName) {
    final lowerName = fieldName.toLowerCase();
    return lowerName.contains('brand') || lowerName.contains('store');
  }

  static bool isDateLikeField(String fieldName, dynamic value) {
    final lowerName = fieldName.toLowerCase();
    final isDateField =
        lowerName.contains('date') ||
        lowerName.contains('time') ||
        lowerName.contains('created') ||
        lowerName.contains('updated');

    if (!isDateField) return false;

    // Try to parse as timestamp
    if (value is String) {
      final parsedDate = DateTime.tryParse(value);
      if (parsedDate != null) {
        return formatTimestamp(parsedDate) != value;
      }
    }

    return value is DateTime;
  }

  // Common field type detection
  static String getFieldType(String fieldName, dynamic value) {
    if (isLocationUrlField(fieldName, value)) return 'location';
    if (isPhoneField(fieldName)) return 'phone';
    if (isAgencyField(fieldName)) return 'agency';
    if (isBrandField(fieldName)) return 'brand';
    if (isDateLikeField(fieldName, value)) return 'date';
    return 'text';
  }

  // Common icon and color determination
  static IconData getFieldIcon(String fieldName, dynamic value) {
    final fieldType = getFieldType(fieldName, value);
    switch (fieldType) {
      case 'location':
        return Icons.location_on;
      case 'phone':
        return Icons.phone;
      case 'agency':
        return Icons.alt_route;
      case 'brand':
        return Icons.store;
      case 'date':
        return Icons.calendar_today;
      default:
        return Icons.info;
    }
  }

  static Color getFieldColor(String fieldName, dynamic value) {
    final fieldType = getFieldType(fieldName, value);
    switch (fieldType) {
      case 'location':
        return Colors.red;
      case 'phone':
        return Colors.green;
      case 'agency':
        return Colors.blue;
      case 'brand':
        return Colors.purple;
      case 'date':
        return Colors.grey;
      default:
        return Colors.blue;
    }
  }

  // Common validation methods
  static bool validateAgencyBrandLinkField(String fieldName, dynamic value) {
    switch (fieldName.toLowerCase()) {
      case ModelAgencyBrandLinkFields.agencyId:
        return _validateAgencyId(value);
      case ModelAgencyBrandLinkFields.brandId:
        return _validateBrandId(value);
      case ModelAgencyBrandLinkFields.visitOrder:
        return _validateVisitOrder(value);
      default:
        return true; // Pass validation for other fields
    }
  }

  static bool _validateAgencyId(dynamic value) {
    if (value == null || value.toString().trim().isEmpty) {
      return false;
    }
    return true;
  }

  static bool _validateBrandId(dynamic value) {
    if (value == null || value.toString().trim().isEmpty) {
      return false;
    }
    return true;
  }

  static bool _validateVisitOrder(dynamic value) {
    if (value == null) return true;

    if (value is int) {
      return value > 0;
    }

    if (value is String) {
      final parsed = int.tryParse(value);
      return parsed != null && parsed > 0;
    }

    return false;
  }

  // Common data conversion
  static ModelAgencyBrandLink convertToModelAgencyBrandLink(
    Map<String, dynamic> fieldValues,
  ) {
    return ModelAgencyBrandLink(
      agencyId:
          fieldValues['agency_id']?.toString() ??
          fieldValues[ModelAgencyBrandLinkFields.agencyId]?.toString() ??
          fieldValues['route_id']?.toString(), // Fallback
      brandId:
          fieldValues['brand_id']?.toString() ??
          fieldValues[ModelAgencyBrandLinkFields.brandId]?.toString(),
      visitOrder:
          fieldValues['visit_order'] != null ||
              fieldValues[ModelAgencyBrandLinkFields.visitOrder] != null
          ? int.tryParse(
              fieldValues['visit_order']?.toString() ??
                  fieldValues[ModelAgencyBrandLinkFields.visitOrder]
                      ?.toString() ??
                  '',
            )
          : null,
    );
  }

  // Common utility methods
  static String generateAgencyBrandLinkName({
    required String agencyName,
    required String brandName,
  }) {
    return '$agencyName - $brandName';
  }

  static bool isAgencyBrandLinkActive(Map<String, dynamic> fieldValues) {
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

  // Common error handling
  static void handleError(
    String context,
    dynamic error,
    StackTrace? stackTrace,
  ) {
    debugPrint('Error in $context: $error');
    if (stackTrace != null) {
      debugPrint('Stack trace: $stackTrace');
    }
  }

  // Common navigation helpers
  static void navigateToList(BuildContext context, String listRouteName) {
    GoRouter.of(context).goNamed(listRouteName);
  }

  static void navigateToEdit(
    BuildContext context,
    String editRouteName,
    String entityId,
  ) {
    GoRouter.of(
      context,
    ).goNamed(editRouteName, pathParameters: {'id': entityId});
  }

  static void navigateToView(
    BuildContext context,
    String viewRouteName,
    String entityId,
  ) {
    GoRouter.of(
      context,
    ).goNamed(viewRouteName, pathParameters: {'id': entityId});
  }
}

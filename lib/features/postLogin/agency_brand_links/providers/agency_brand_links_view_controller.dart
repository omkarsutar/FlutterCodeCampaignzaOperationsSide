import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/config/field_config.dart';
import '../../../../../core/utils/core_utils_barrel.dart';
import 'route_brand_link_controller.dart';

class RouteBrandLinksViewState {
  final bool isLoading;
  final String? error;
  final bool isDeleted;

  const RouteBrandLinksViewState({
    this.isLoading = false,
    this.error,
    this.isDeleted = false,
  });

  RouteBrandLinksViewState copyWith({
    bool? isLoading,
    String? error,
    bool? isDeleted,
  }) {
    return RouteBrandLinksViewState(
      isLoading: isLoading ?? this.isLoading,
      error: error, // Nullable update
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }
}

class RouteBrandLinksViewController
    extends AutoDisposeFamilyNotifier<RouteBrandLinksViewState, String> {
  @override
  RouteBrandLinksViewState build(String arg) {
    return const RouteBrandLinksViewState();
  }

  // URL and phone launching methods
  Future<void> launchUrl(String url) async {
    try {
      await launchUrl(url);
    } catch (e) {
      // Error handled silently
    }
  }

  Future<void> launchPhone(String phoneNumber) async {
    try {
      final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
      await launchUrl('tel:$cleanNumber');
    } catch (e) {
      // Error handled silently
    }
  }

  // Date formatting method
  String formatDateLikeField(FieldConfig field, dynamic value) {
    if (value == null) return '';
    DateTime? dt;

    if (value is DateTime) {
      dt = value;
    } else if (value is String) {
      dt = DateTime.tryParse(value);
    }

    if (dt != null) {
      return formatTimestamp(dt);
    }

    final lowerName = field.name.toLowerCase();
    final looksLikeDateField =
        lowerName.endsWith('_at') || lowerName.contains('date');
    if (looksLikeDateField && value is String) {
      final parsed = DateTime.tryParse(value);
      if (parsed != null) {
        return formatTimestamp(parsed);
      }
    }

    return value.toString();
  }

  // Field icon and color determination
  ({IconData icon, Color color}) getFieldIconAndColor(String fieldName) {
    final icon = RouteBrandLinkController.getFieldIcon(fieldName, '');
    final color = RouteBrandLinkController.getFieldColor(fieldName, '');
    return (icon: icon, color: color);
  }

  // Field type checking methods for UI
  bool isPhoneField(String fieldName) =>
      RouteBrandLinkController.isPhoneField(fieldName);
  bool isLocationField(String fieldName, String? value) =>
      RouteBrandLinkController.isLocationUrlField(fieldName, value);
  bool isRouteField(String fieldName) =>
      RouteBrandLinkController.isRouteField(fieldName);
  bool isBrandField(String fieldName) =>
      RouteBrandLinkController.isBrandField(fieldName);

  // Delete confirmation dialog
  Future<bool> showDeleteConfirmation(
    BuildContext context,
    String entityName,
    String entityNameLower,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete $entityName'),
        content: Text('Are you sure you want to delete this $entityNameLower?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }

  // Handle delete entity with confirmation
  Future<void> handleDeleteEntity({
    required BuildContext context,
    required WidgetRef ref,
    required Future<bool> Function(WidgetRef, String) deleteFunction,
    required String entityId,
    required String entityName,
    required String entityNameLower,
  }) async {
    final confirmed = await showDeleteConfirmation(
      context,
      entityName,
      entityNameLower,
    );
    if (confirmed && context.mounted) {
      await deleteEntity(
        deleteFunction: deleteFunction,
        entityId: entityId,
        ref: ref,
      );
    }
  }

  // Handle side effects (snackbar and navigation)
  void handleSideEffects(
    RouteBrandLinksViewState state,
    BuildContext context,
    String entityName,
  ) {
    if (state.isDeleted && !state.isLoading) {
      SnackbarUtils.showSuccess('$entityName deleted successfully!');
      context.pop();
    } else if (state.error != null && !state.isLoading) {
      SnackbarUtils.showError('Failed to delete: ${state.error}');
    }
  }

  Future<void> deleteEntity({
    required Future<bool> Function(WidgetRef, String) deleteFunction,
    required String entityId,
    required WidgetRef ref,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final success = await deleteFunction(ref, entityId);
      if (success) {
        state = state.copyWith(isLoading: false, isDeleted: true);
      } else {
        state = state.copyWith(isLoading: false, error: 'Failed to delete');
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final routeBrandLinksViewControllerProvider = NotifierProvider.autoDispose
    .family<RouteBrandLinksViewController, RouteBrandLinksViewState, String>(
      () => RouteBrandLinksViewController(),
    );

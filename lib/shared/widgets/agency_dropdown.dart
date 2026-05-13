import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_supabase_order_app_mobile/features/postLogin/agencies/agency_barrel.dart';
import '../../core/providers/auth_providers.dart'; // for userProfileProvider

class AgencyDropdown extends ConsumerStatefulWidget {
  final void Function(String?) onAgencySelected;
  final String? initialAgencyId;
  final bool allowAll;

  const AgencyDropdown({
    super.key,
    required this.onAgencySelected,
    this.initialAgencyId,
    this.allowAll = false,
  });

  @override
  ConsumerState<AgencyDropdown> createState() => _AgencyDropdownState();
}

class _AgencyDropdownState extends ConsumerState<AgencyDropdown> {
  String? selectedAgencyId;

  @override
  void initState() {
    super.initState();
    // initialAgencyId is passed in OR fallback to profile provider
    final profile = ref.read(userProfileProvider).value;
    selectedAgencyId = widget.initialAgencyId ?? profile?.preferredAgencyId;
  }

  @override
  Widget build(BuildContext context) {
    final agenciesAsync = ref.watch(agenciesStreamProvider);
    final theme = Theme.of(context);

    return agenciesAsync.when(
      data: (agencies) {
        if (agencies.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: DropdownButtonFormField<String>(
              isExpanded: true,
              initialValue: null,
              decoration: _buildDecoration(theme),
              items: const [],
              onChanged: null,
              hint: const Text('No agencies available'),
            ),
          );
        }

        final items = agencies.map((agency) {
          return DropdownMenuItem<String>(
            value: agency.agencyId,
            child: Text(agency.agencyName),
          );
        }).toList();

        if (widget.allowAll) {
          items.insert(
            0,
            const DropdownMenuItem<String>(
              value: null,
              child: Text('All Agencies'),
            ),
          );
        }

        final validValues = items.map((item) => item.value).toSet();
        final safeInitialValue = validValues.contains(selectedAgencyId)
            ? selectedAgencyId
            : null;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: DropdownButtonFormField<String>(
            isExpanded: true,
            initialValue: safeInitialValue,
            decoration: _buildDecoration(theme),
            icon: Icon(
              Icons.keyboard_arrow_down_rounded,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w500,
            ),
            dropdownColor: theme.colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(12),
            items: items,
            onChanged: (value) {
              setState(() {
                selectedAgencyId = value;
              });
              widget.onAgencySelected(value);
            },
          ),
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.all(12),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (err, stack) => Padding(
        padding: const EdgeInsets.all(12),
        child: Text(
          'Error loading agencies',
          style: TextStyle(color: theme.colorScheme.error),
        ),
      ),
    );
  }

  InputDecoration _buildDecoration(ThemeData theme) {
    return InputDecoration(
      labelText: 'Select Agency',
      labelStyle: theme.textTheme.bodyMedium?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
      prefixIcon: Icon(
        Icons.alt_route_rounded,
        color: theme.colorScheme.primary,
      ),
      filled: true,
      fillColor: theme.colorScheme.surfaceContainerLow,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    );
  }
}

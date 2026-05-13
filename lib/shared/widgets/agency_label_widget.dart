import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/postLogin/agencies/agency_barrel.dart';

class AgencyLabelWidget extends ConsumerWidget {
  const AgencyLabelWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final agencyNameAsync = ref.watch(currentAgencyNameProvider);

    return agencyNameAsync.when(
      data: (agencyName) => Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Text(
            'Agency: $agencyName',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ),
      ),
      loading: () => const Padding(
        padding: EdgeInsets.all(8.0),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      error: (err, stack) => const SizedBox.shrink(),
    );
  }
}

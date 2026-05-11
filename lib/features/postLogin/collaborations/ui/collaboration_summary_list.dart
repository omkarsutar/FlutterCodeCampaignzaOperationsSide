import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/collaboration_providers.dart';
import 'collaboration_summary_tile.dart';
import '../providers/collaboration_summary_controller.dart';

class CollaborationSummaryList extends ConsumerWidget {
  final String poId;
  final String status;

  const CollaborationSummaryList({
    super.key,
    required this.poId,
    required this.status,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final collaborationsAsync = ref.watch(
      processedPoSummaryItemsProvider(poId),
    );
    final isGrouped = ref.watch(collaborationSummaryGroupedProvider);

    return collaborationsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Text('Error loading items: $error'),
      data: (items) {
        if (items.isEmpty) {
          return Text(
            'No items found for this PO yet.',
            style: Theme.of(context).textTheme.bodySmall,
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Item Name',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      if (status.toLowerCase() == 'confirmed')
                        Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: InkWell(
                            onTap: () {
                              ref
                                  .read(
                                    collaborationSummaryGroupedProvider
                                        .notifier,
                                  )
                                  .update((state) => !state);
                            },
                            child: Icon(
                              isGrouped ? Icons.layers : Icons.layers_outlined,
                              size: 16,
                              color: isGrouped
                                  ? Theme.of(context).colorScheme.primary
                                  : Colors.grey,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const Expanded(
                  child: Text(
                    'Qty',
                    textAlign: TextAlign.right,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                const Expanded(
                  child: Text(
                    'Rate',
                    textAlign: TextAlign.right,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                const Expanded(
                  child: Text(
                    'Amt',
                    textAlign: TextAlign.right,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const Divider(),
            ...items.map((item) => CollaborationSummaryTile(item: item)),
          ],
        );
      },
    );
  }
}

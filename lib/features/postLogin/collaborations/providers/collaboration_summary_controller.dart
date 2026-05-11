import 'package:flutter_riverpod/flutter_riverpod.dart';

/// State provider to manage the grouping preference in Collaboration summary list
/// Default: not grouped (flat list)
final collaborationSummaryGroupedProvider = StateProvider.autoDispose<bool>((
  ref,
) {
  return false;
});

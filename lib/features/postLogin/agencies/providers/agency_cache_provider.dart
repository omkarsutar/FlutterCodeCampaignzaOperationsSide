import 'package:flutter_riverpod/flutter_riverpod.dart';

class AgencyCache {
  final String? agencyId;
  final String? agencyName;

  const AgencyCache({this.agencyId, this.agencyName});

  AgencyCache copyWith({String? agencyId, String? agencyName}) {
    return AgencyCache(
      agencyId: agencyId ?? this.agencyId,
      agencyName: agencyName ?? this.agencyName,
    );
  }
}

/// StateProvider for agency cache
final agencyCacheProvider = StateProvider<AgencyCache>((ref) {
  return const AgencyCache();
});

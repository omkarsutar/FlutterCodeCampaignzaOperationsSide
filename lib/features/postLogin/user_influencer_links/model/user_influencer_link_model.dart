import '../../../../core/services/entity_service.dart';

class ModelUserInfluencerLinkFields {
  static const String table = 'user_influencer_link';
  static const String tableViewWithForeignKeyLabels =
      'view_user_influencer_link';

  static const String linkId = 'link_id';
  static const String userId = 'user_id';
  static const String influencerId = 'influencer_id';
  static const String createdAt = 'created_at';
  static const String updatedAt = 'updated_at';
  static const String createdBy = 'created_by';
  static const String updatedBy = 'updated_by';
}

class ModelUserInfluencerLink {
  final String linkId; // PK
  final String userId; // FK
  final String influencerId; // FK
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? createdBy;
  final String? updatedBy;
  final Map<String, dynamic> _resolvedLabels;

  ModelUserInfluencerLink({
    required this.linkId,
    required this.userId,
    required this.influencerId,
    this.createdAt,
    this.updatedAt,
    this.createdBy,
    this.updatedBy,
    Map<String, dynamic>? resolvedLabels,
  }) : _resolvedLabels = resolvedLabels ?? const {};

  Map<String, dynamic> get resolvedLabels => _resolvedLabels;

  factory ModelUserInfluencerLink.fromMap(Map<String, dynamic> map) {
    final labelEntries = <String, dynamic>{};
    for (final entry in map.entries) {
      if (entry.key.endsWith('_label')) {
        labelEntries[entry.key] = entry.value;
      }
    }

    return ModelUserInfluencerLink(
      linkId: map[ModelUserInfluencerLinkFields.linkId].toString(),
      userId: map[ModelUserInfluencerLinkFields.userId].toString(),
      influencerId: map[ModelUserInfluencerLinkFields.influencerId].toString(),
      createdAt: _parseDate(map[ModelUserInfluencerLinkFields.createdAt]),
      updatedAt: _parseDate(map[ModelUserInfluencerLinkFields.updatedAt]),
      createdBy: map[ModelUserInfluencerLinkFields.createdBy]?.toString(),
      updatedBy: map[ModelUserInfluencerLinkFields.updatedBy]?.toString(),
      resolvedLabels: labelEntries,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (linkId.isNotEmpty && linkId != 'null')
        ModelUserInfluencerLinkFields.linkId: linkId,
      ModelUserInfluencerLinkFields.userId: userId,
      ModelUserInfluencerLinkFields.influencerId: influencerId,
    };
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }
}

class ModelUserInfluencerLinkMapper
    implements EntityMapper<ModelUserInfluencerLink> {
  @override
  ModelUserInfluencerLink fromMap(Map<String, dynamic> map) =>
      ModelUserInfluencerLink.fromMap(map);

  @override
  Map<String, dynamic> toMap(ModelUserInfluencerLink entity) => entity.toMap();
}

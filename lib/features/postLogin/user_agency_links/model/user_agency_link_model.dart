import '../../../../core/services/entity_service.dart';

class ModelUserAgencyLinkFields {
  static const String table = 'user_agency_link';
  static const String tableViewWithForeignKeyLabels = 'view_user_agency_link';

  static const String linkId = 'link_id';
  static const String userId = 'user_id';
  static const String agencyId = 'agency_id';
  static const String createdAt = 'created_at';
  static const String updatedAt = 'updated_at';
  static const String createdBy = 'created_by';
  static const String updatedBy = 'updated_by';
}

class ModelUserAgencyLink {
  final String linkId; // PK
  final String userId; // FK
  final String agencyId; // FK
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? createdBy;
  final String? updatedBy;
  final Map<String, dynamic> _resolvedLabels;

  ModelUserAgencyLink({
    required this.linkId,
    required this.userId,
    required this.agencyId,
    this.createdAt,
    this.updatedAt,
    this.createdBy,
    this.updatedBy,
    Map<String, dynamic>? resolvedLabels,
  }) : _resolvedLabels = resolvedLabels ?? const {};

  Map<String, dynamic> get resolvedLabels => _resolvedLabels;

  factory ModelUserAgencyLink.fromMap(Map<String, dynamic> map) {
    final labelEntries = <String, dynamic>{};
    for (final entry in map.entries) {
      if (entry.key.endsWith('_label')) {
        labelEntries[entry.key] = entry.value;
      }
    }

    return ModelUserAgencyLink(
      linkId: map[ModelUserAgencyLinkFields.linkId].toString(),
      userId: map[ModelUserAgencyLinkFields.userId].toString(),
      agencyId: map[ModelUserAgencyLinkFields.agencyId].toString(),
      createdAt: _parseDate(map[ModelUserAgencyLinkFields.createdAt]),
      updatedAt: _parseDate(map[ModelUserAgencyLinkFields.updatedAt]),
      createdBy: map[ModelUserAgencyLinkFields.createdBy]?.toString(),
      updatedBy: map[ModelUserAgencyLinkFields.updatedBy]?.toString(),
      resolvedLabels: labelEntries,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (linkId.isNotEmpty && linkId != 'null')
        ModelUserAgencyLinkFields.linkId: linkId,
      ModelUserAgencyLinkFields.userId: userId,
      ModelUserAgencyLinkFields.agencyId: agencyId,
      if (createdAt != null)
        ModelUserAgencyLinkFields.createdAt: createdAt!.toIso8601String(),
      if (updatedAt != null)
        ModelUserAgencyLinkFields.updatedAt: updatedAt!.toIso8601String(),
      if (createdBy != null) ModelUserAgencyLinkFields.createdBy: createdBy,
      if (updatedBy != null) ModelUserAgencyLinkFields.updatedBy: updatedBy,
    };
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }
}

class ModelUserAgencyLinkMapper implements EntityMapper<ModelUserAgencyLink> {
  @override
  ModelUserAgencyLink fromMap(Map<String, dynamic> map) =>
      ModelUserAgencyLink.fromMap(map);

  @override
  Map<String, dynamic> toMap(ModelUserAgencyLink entity) => entity.toMap();
}

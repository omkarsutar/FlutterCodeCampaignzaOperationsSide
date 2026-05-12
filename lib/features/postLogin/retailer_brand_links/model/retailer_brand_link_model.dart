import '../../../../core/services/entity_service.dart';

class ModelRetailerBrandLinkFields {
  static const String table = 'retailer_brand_link';
  static const String tableViewWithForeignKeyLabels =
      'view_retailer_brand_link';

  static const String linkId = 'link_id';
  static const String userId = 'user_id';
  static const String brandId = 'brand_id';
  static const String createdAt = 'created_at';
  static const String updatedAt = 'updated_at';
  static const String createdBy = 'created_by';
  static const String updatedBy = 'updated_by';
}

class ModelRetailerBrandLink {
  final String linkId; // PK
  final String userId; // FK
  final String brandId; // FK
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? createdBy;
  final String? updatedBy;
  final Map<String, dynamic> _resolvedLabels;

  ModelRetailerBrandLink({
    required this.linkId,
    required this.userId,
    required this.brandId,
    this.createdAt,
    this.updatedAt,
    this.createdBy,
    this.updatedBy,
    Map<String, dynamic>? resolvedLabels,
  }) : _resolvedLabels = resolvedLabels ?? const {};

  Map<String, dynamic> get resolvedLabels => _resolvedLabels;

  factory ModelRetailerBrandLink.fromMap(Map<String, dynamic> map) {
    final labelEntries = <String, dynamic>{};
    for (final entry in map.entries) {
      if (entry.key.endsWith('_label')) {
        labelEntries[entry.key] = entry.value;
      }
    }

    return ModelRetailerBrandLink(
      linkId: map[ModelRetailerBrandLinkFields.linkId].toString(),
      userId: map[ModelRetailerBrandLinkFields.userId].toString(),
      brandId: map[ModelRetailerBrandLinkFields.brandId].toString(),
      createdAt: _parseDate(map[ModelRetailerBrandLinkFields.createdAt]),
      updatedAt: _parseDate(map[ModelRetailerBrandLinkFields.updatedAt]),
      createdBy: map[ModelRetailerBrandLinkFields.createdBy]?.toString(),
      updatedBy: map[ModelRetailerBrandLinkFields.updatedBy]?.toString(),
      resolvedLabels: labelEntries,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (linkId.isNotEmpty && linkId != 'null')
        ModelRetailerBrandLinkFields.linkId: linkId,
      ModelRetailerBrandLinkFields.userId: userId,
      ModelRetailerBrandLinkFields.brandId: brandId,
      if (createdAt != null)
        ModelRetailerBrandLinkFields.createdAt: createdAt!.toIso8601String(),
      if (updatedAt != null)
        ModelRetailerBrandLinkFields.updatedAt: updatedAt!.toIso8601String(),
      if (createdBy != null) ModelRetailerBrandLinkFields.createdBy: createdBy,
      if (updatedBy != null) ModelRetailerBrandLinkFields.updatedBy: updatedBy,
    };
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }
}

class ModelRetailerBrandLinkMapper
    implements EntityMapper<ModelRetailerBrandLink> {
  @override
  ModelRetailerBrandLink fromMap(Map<String, dynamic> map) =>
      ModelRetailerBrandLink.fromMap(map);

  @override
  Map<String, dynamic> toMap(ModelRetailerBrandLink entity) => entity.toMap();
}

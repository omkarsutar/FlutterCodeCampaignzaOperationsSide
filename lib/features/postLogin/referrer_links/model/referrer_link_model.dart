import '../../../../core/models/entity_meta.dart';
import '../../../../core/services/entity_service.dart';

const referrerLinkEntityMeta = EntityMeta(
  entityName: 'Referrer Link',
  entityNamePlural: 'Referrer Links',
  entityNameLower: 'referrer link',
  entityNamePluralLower: 'referrer links',
);

class ModelReferrerLinkFields {
  static const String table = 'referrer_links';

  static const String moduleId = 'module_id';
  static const String moduleName = 'module_name';
  static const String moduleDescription = 'module_description';
  static const String createdAt = 'created_at';
  static const String updatedAt = 'updated_at';
  static const String createdBy = 'created_by';
  static const String updatedBy = 'updated_by';
  static const String isActive = 'is_active';
}

class ModelReferrerLink {
  final String? moduleId;
  final String moduleName;
  final String? moduleDescription;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? createdBy;
  final String? updatedBy;
  final bool isActive;

  ModelReferrerLink({
    this.moduleId,
    required this.moduleName,
    this.moduleDescription,
    this.createdAt,
    this.updatedAt,
    this.createdBy,
    this.updatedBy,
    this.isActive = true,
  });

  factory ModelReferrerLink.fromMap(Map<String, dynamic> map) {
    return ModelReferrerLink(
      moduleId: map[ModelReferrerLinkFields.moduleId],
      moduleName: map[ModelReferrerLinkFields.moduleName],
      moduleDescription: map[ModelReferrerLinkFields.moduleDescription],
      createdAt: map[ModelReferrerLinkFields.createdAt] != null
          ? DateTime.tryParse(map[ModelReferrerLinkFields.createdAt])
          : null,
      updatedAt: map[ModelReferrerLinkFields.updatedAt] != null
          ? DateTime.tryParse(map[ModelReferrerLinkFields.updatedAt])
          : null,
      createdBy: map[ModelReferrerLinkFields.createdBy],
      updatedBy: map[ModelReferrerLinkFields.updatedBy],
      isActive: map[ModelReferrerLinkFields.isActive] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (moduleId != null) ModelReferrerLinkFields.moduleId: moduleId,
      ModelReferrerLinkFields.moduleName: moduleName,
      if (moduleDescription != null)
        ModelReferrerLinkFields.moduleDescription: moduleDescription,
      ModelReferrerLinkFields.isActive: isActive,
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'moduleId': moduleId,
      'moduleName': moduleName,
      'moduleDescription': moduleDescription,
      'isActive': isActive,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'createdBy': createdBy,
      'updatedBy': updatedBy,
    };
  }

  factory ModelReferrerLink.fromJson(Map<String, dynamic> json) {
    return ModelReferrerLink(
      moduleId: json['moduleId'] as String,
      moduleName: json['moduleName'] as String,
      moduleDescription: json['moduleDescription'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] ?? '') ?? DateTime.now(),
      createdBy: json['createdBy'] as String?,
      updatedBy: json['updatedBy'] as String?,
    );
  }
}

class ModelReferrerLinkMapper implements EntityMapper<ModelReferrerLink> {
  @override
  ModelReferrerLink fromMap(Map<String, dynamic> map) =>
      ModelReferrerLink.fromMap(map);

  @override
  Map<String, dynamic> toMap(ModelReferrerLink entity) => entity.toMap();
}

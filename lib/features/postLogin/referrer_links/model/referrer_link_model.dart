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

  static const String referrerLinkId = 'referrer_link_id';
  static const String referrerLinkString = 'referrer_link_string';
  static const String referrerLinkType = 'referrer_link_type';
  static const String campaignId = 'campaign_id';
  static const String campaignType = 'campaign_type';
  static const String collaborationId = 'collaboration_id';
  static const String referrerLinkSource = 'referrer_link_source';
  static const String createdAt = 'created_at';
  static const String updatedAt = 'updated_at';
  static const String createdBy = 'created_by';
  static const String updatedBy = 'updated_by';
}

class ModelReferrerLink {
  final String? referrerLinkId;
  final String referrerLinkString;
  final String referrerLinkType;
  final String? campaignId;
  final String campaignType;
  final String? collaborationId;
  final String referrerLinkSource;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? createdBy;
  final String? updatedBy;

  ModelReferrerLink({
    this.referrerLinkId,
    required this.referrerLinkString,
    required this.referrerLinkType,
    this.campaignId,
    required this.campaignType,
    this.collaborationId,
    required this.referrerLinkSource,
    this.createdAt,
    this.updatedAt,
    this.createdBy,
    this.updatedBy,
  });

  factory ModelReferrerLink.fromMap(Map<String, dynamic> map) {
    return ModelReferrerLink(
      referrerLinkId: map[ModelReferrerLinkFields.referrerLinkId]?.toString(),
      referrerLinkString: map[ModelReferrerLinkFields.referrerLinkString]?.toString() ?? '',
      referrerLinkType: map[ModelReferrerLinkFields.referrerLinkType]?.toString() ?? 'plain',
      campaignId: map[ModelReferrerLinkFields.campaignId]?.toString(),
      campaignType: map[ModelReferrerLinkFields.campaignType]?.toString() ?? '',
      collaborationId: map[ModelReferrerLinkFields.collaborationId]?.toString(),
      referrerLinkSource: map[ModelReferrerLinkFields.referrerLinkSource]?.toString() ?? '',
      createdAt: map[ModelReferrerLinkFields.createdAt] != null
          ? DateTime.tryParse(map[ModelReferrerLinkFields.createdAt].toString())
          : null,
      updatedAt: map[ModelReferrerLinkFields.updatedAt] != null
          ? DateTime.tryParse(map[ModelReferrerLinkFields.updatedAt].toString())
          : null,
      createdBy: map[ModelReferrerLinkFields.createdBy]?.toString(),
      updatedBy: map[ModelReferrerLinkFields.updatedBy]?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (referrerLinkId != null) ModelReferrerLinkFields.referrerLinkId: referrerLinkId,
      ModelReferrerLinkFields.referrerLinkString: referrerLinkString,
      ModelReferrerLinkFields.referrerLinkType: referrerLinkType,
      if (campaignId != null) ModelReferrerLinkFields.campaignId: campaignId,
      ModelReferrerLinkFields.campaignType: campaignType,
      if (collaborationId != null) ModelReferrerLinkFields.collaborationId: collaborationId,
      ModelReferrerLinkFields.referrerLinkSource: referrerLinkSource,
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'referrerLinkId': referrerLinkId,
      'referrerLinkString': referrerLinkString,
      'referrerLinkType': referrerLinkType,
      'campaignId': campaignId,
      'campaignType': campaignType,
      'collaborationId': collaborationId,
      'referrerLinkSource': referrerLinkSource,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'createdBy': createdBy,
      'updatedBy': updatedBy,
    };
  }

  factory ModelReferrerLink.fromJson(Map<String, dynamic> json) {
    return ModelReferrerLink(
      referrerLinkId: json['referrerLinkId'] as String?,
      referrerLinkString: json['referrerLinkString'] as String? ?? '',
      referrerLinkType: json['referrerLinkType'] as String? ?? 'plain',
      campaignId: json['campaignId'] as String?,
      campaignType: json['campaignType'] as String? ?? '',
      collaborationId: json['collaborationId'] as String?,
      referrerLinkSource: json['referrerLinkSource'] as String? ?? '',
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'] as String) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt'] as String) : null,
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

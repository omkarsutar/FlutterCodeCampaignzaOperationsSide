import '../../../../core/services/entity_service.dart';

class ModelCampaignFields {
  static const String table = 'campaign';
  static const String tableViewWithForeignKeyLabels = 'view_campaigns';

  static const String campaignId = 'campaign_id';
  static const String campaignName = 'campaign_name';
  static const String campaignNameString = 'campaign_name_string';
  static const String campaignType = 'campaign_type';
  static const String collaborationCount = 'collaboration_count';
  static const String referrerLinks = 'referrer_links';
  static const String campaignAgencyId = 'campaign_agency_id';
  static const String campaignBrandId = 'campaign_brand_id';
  static const String userComment = 'user_comment';
  static const String adminComment = 'admin_comment';
  static const String status = 'status';
  static const String validFrom = 'valid_from';
  static const String validUntil = 'valid_until';
  static const String createdBy = 'created_by';
  static const String updatedBy = 'updated_by';
  static const String createdAt = 'created_at';
  static const String updatedAt = 'updated_at';
  static const String visitOrder = 'visit_order';

  // Compatibility fields
  static const String poId = campaignId;
  static const String poAgencyId = campaignAgencyId;
  static const String poBrandId = campaignBrandId;
  static const String poTotalAmount = 'po_total_amount';
  static const String poLineItemCount = collaborationCount;
  static const String poLat = 'po_lat';
  static const String poLong = 'po_long';
  static const String profitToBrand = 'profit_to_brand';

  static const Map<String, String> labels = {
    campaignId: 'Campaign',
    campaignName: 'Campaign Name',
    campaignNameString: 'Campaign Name String',
    campaignType: 'Campaign Type',
    collaborationCount: 'Collaborations',
    referrerLinks: 'Referrer Links',
    campaignAgencyId: 'Agency',
    campaignBrandId: 'Brand',
    userComment: 'User Comment',
    adminComment: 'Admin Comment',
    status: 'Status',
    validFrom: 'Valid From',
    validUntil: 'Valid Until',
    createdBy: 'Created By',
    updatedBy: 'Updated By',
    createdAt: 'Created At',
    updatedAt: 'Updated At',
    visitOrder: 'Visit Order',
  };

  static String getLabel(String field) => labels[field] ?? field;
}

enum CampaignType {
  influencerCollaborations,
  directBrandPromotions,
  paidAds;

  static CampaignType fromString(String? value) {
    switch (value) {
      case 'influencer_collaborations':
        return CampaignType.influencerCollaborations;
      case 'direct_brand_promotions':
        return CampaignType.directBrandPromotions;
      case 'paid_ads':
        return CampaignType.paidAds;
      default:
        return CampaignType.paidAds;
    }
  }

  String toDbValue() {
    switch (this) {
      case CampaignType.influencerCollaborations:
        return 'influencer_collaborations';
      case CampaignType.directBrandPromotions:
        return 'direct_brand_promotions';
      case CampaignType.paidAds:
        return 'paid_ads';
    }
  }

  String get displayName {
    switch (this) {
      case CampaignType.influencerCollaborations:
        return 'Influencer Collaborations';
      case CampaignType.directBrandPromotions:
        return 'Direct Brand Promotions';
      case CampaignType.paidAds:
        return 'Paid Ads';
    }
  }

  bool get isInfluencerCollaboration =>
      this == CampaignType.influencerCollaborations;
}

class ModelCampaign {
  final String? campaignId;
  final String? campaignName;
  final String? campaignNameString;
  final CampaignType? campaignType;
  final int? collaborationCount;
  final List<String> referrerLinks;
  final String? campaignAgencyId;
  final String? campaignBrandId;
  final String? userComment;
  final String? adminComment;
  final String? status;
  final DateTime? validFrom;
  final DateTime? validUntil;
  final String? createdBy;
  final String? updatedBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int? visitOrder;
  final Map<String, dynamic> _resolvedLabels;

  // Compatibility properties
  String? get poId => campaignId;
  String? get poAgencyId => campaignAgencyId;
  String? get poBrandId => campaignBrandId;
  int? get poLineItemCount => collaborationCount;
  CampaignType get effectiveCampaignType {
    if (campaignType != null) return campaignType!;
    if ((collaborationCount ?? 0) > 0) {
      return CampaignType.influencerCollaborations;
    }
    if (referrerLinks.isNotEmpty) {
      return CampaignType.directBrandPromotions;
    }
    return CampaignType.paidAds;
  }
  double? get poTotalAmount => 0.0;
  double? get profitToBrand => 0.0;
  double? get poLat => null;
  double? get poLong => null;

  ModelCampaign({
    String? campaignId,
    this.campaignName,
    this.campaignNameString,
    this.campaignType,
    int? collaborationCount,
    List<String>? referrerLinks,
    String? campaignAgencyId,
    String? campaignBrandId,
    this.userComment,
    this.adminComment,
    this.status,
    this.validFrom,
    this.validUntil,
    this.createdBy,
    this.updatedBy,
    this.createdAt,
    this.updatedAt,
    this.visitOrder,
    // Compatibility constructor args
    String? poId,
    String? poAgencyId,
    String? poBrandId,
    int? poLineItemCount,
    double? poTotalAmount,
    double? profitToBrand,
    double? poLat,
    double? poLong,
    Map<String, dynamic>? resolvedLabels,
  }) : campaignId = campaignId ?? poId,
       collaborationCount = collaborationCount ?? poLineItemCount,
       referrerLinks = referrerLinks ?? const [],
       campaignAgencyId = campaignAgencyId ?? poAgencyId,
       campaignBrandId = campaignBrandId ?? poBrandId,
       _resolvedLabels = resolvedLabels ?? const {};

  Map<String, dynamic> get resolvedLabels => _resolvedLabels;

  factory ModelCampaign.fromMap(Map<String, dynamic> map) {
    final labelEntries = <String, dynamic>{};
    for (final entry in map.entries) {
      if (entry.key.endsWith('_label')) {
        labelEntries[entry.key] = entry.value;
      }
    }

    return ModelCampaign(
      campaignId: map[ModelCampaignFields.campaignId] as String?,
      campaignName: map[ModelCampaignFields.campaignName] as String?,
      campaignNameString: map[ModelCampaignFields.campaignNameString] as String?,
      campaignType: map[ModelCampaignFields.campaignType] != null
          ? CampaignType.fromString(
              map[ModelCampaignFields.campaignType]?.toString(),
            )
          : null,
      collaborationCount: map[ModelCampaignFields.collaborationCount] != null
          ? int.tryParse(map[ModelCampaignFields.collaborationCount].toString())
          : null,
      referrerLinks: (map[ModelCampaignFields.referrerLinks] as List?)
          ?.map((e) => e.toString())
          .toList(),
      campaignAgencyId: map[ModelCampaignFields.campaignAgencyId] as String?,
      campaignBrandId: map[ModelCampaignFields.campaignBrandId] as String?,
      userComment: map[ModelCampaignFields.userComment] as String?,
      adminComment: map[ModelCampaignFields.adminComment] as String?,
      status: map[ModelCampaignFields.status] as String?,
      validFrom: map[ModelCampaignFields.validFrom] != null
          ? DateTime.tryParse(map[ModelCampaignFields.validFrom].toString())
          : null,
      validUntil: map[ModelCampaignFields.validUntil] != null
          ? DateTime.tryParse(map[ModelCampaignFields.validUntil].toString())
          : null,
      createdBy: map[ModelCampaignFields.createdBy] as String?,
      updatedBy: map[ModelCampaignFields.updatedBy] as String?,
      createdAt: map[ModelCampaignFields.createdAt] != null
          ? DateTime.tryParse(map[ModelCampaignFields.createdAt].toString())
          : null,
      updatedAt: map[ModelCampaignFields.updatedAt] != null
          ? DateTime.tryParse(map[ModelCampaignFields.updatedAt].toString())
          : null,
      visitOrder: map[ModelCampaignFields.visitOrder] != null
          ? int.tryParse(map[ModelCampaignFields.visitOrder].toString())
          : null,
      resolvedLabels: labelEntries,
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{};

    if (campaignId != null) map[ModelCampaignFields.campaignId] = campaignId;
    if (campaignName != null) map[ModelCampaignFields.campaignName] = campaignName;
    if (campaignNameString != null) {
      map[ModelCampaignFields.campaignNameString] = campaignNameString;
    }
    if (campaignType != null) {
      map[ModelCampaignFields.campaignType] = campaignType!.toDbValue();
    }
    if (collaborationCount != null) {
      map[ModelCampaignFields.collaborationCount] = collaborationCount;
    }
    if (referrerLinks.isNotEmpty) {
      map[ModelCampaignFields.referrerLinks] = referrerLinks;
    }
    if (campaignAgencyId != null) {
      map[ModelCampaignFields.campaignAgencyId] = campaignAgencyId;
    }
    if (campaignBrandId != null) {
      map[ModelCampaignFields.campaignBrandId] = campaignBrandId;
    }
    if (userComment != null) {
      map[ModelCampaignFields.userComment] = userComment;
    }
    if (adminComment != null) {
      map[ModelCampaignFields.adminComment] = adminComment;
    }
    if (status != null) map[ModelCampaignFields.status] = status;
    if (validFrom != null) {
      map[ModelCampaignFields.validFrom] = validFrom!.toIso8601String();
    }
    if (validUntil != null) {
      map[ModelCampaignFields.validUntil] = validUntil!.toIso8601String();
    }
    if (createdBy != null) map[ModelCampaignFields.createdBy] = createdBy;
    if (updatedBy != null) map[ModelCampaignFields.updatedBy] = updatedBy;
    if (createdAt != null) {
      map[ModelCampaignFields.createdAt] = createdAt!.toIso8601String();
    }
    if (updatedAt != null) {
      map[ModelCampaignFields.updatedAt] = updatedAt!.toIso8601String();
    }

    return map;
  }

  Map<String, dynamic> toJson() {
    return {
      'campaignId': campaignId,
      'campaignName': campaignName,
      'campaignNameString': campaignNameString,
      'campaignType': campaignType?.toDbValue(),
      'collaborationCount': collaborationCount,
      'referrerLinks': referrerLinks,
      'campaignAgencyId': campaignAgencyId,
      'campaignBrandId': campaignBrandId,
      'userComment': userComment,
      'adminComment': adminComment,
      'status': status,
      'validFrom': validFrom?.toIso8601String(),
      'validUntil': validUntil?.toIso8601String(),
      'createdBy': createdBy,
      'updatedBy': updatedBy,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'visitOrder': visitOrder,
    };
  }

  factory ModelCampaign.fromJson(Map<String, dynamic> json) {
    return ModelCampaign(
      campaignId: json['campaignId'] as String?,
      campaignName: json['campaignName'] as String?,
      campaignNameString: json['campaignNameString'] as String?,
      campaignType: json['campaignType'] != null
          ? CampaignType.fromString(json['campaignType'] as String?)
          : null,
      collaborationCount: json['collaborationCount'] as int?,
      referrerLinks: (json['referrerLinks'] as List?)
          ?.map((e) => e.toString())
          .toList(),
      campaignAgencyId: json['campaignAgencyId'] as String?,
      campaignBrandId: json['campaignBrandId'] as String?,
      userComment: json['userComment'] as String?,
      adminComment: json['adminComment'] as String?,
      status: json['status'] as String? ?? 'pending',
      validFrom: DateTime.tryParse(json['validFrom'] ?? ''),
      validUntil: DateTime.tryParse(json['validUntil'] ?? ''),
      createdBy: json['createdBy'] as String?,
      updatedBy: json['updatedBy'] as String?,
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] ?? '') ?? DateTime.now(),
      visitOrder: json['visitOrder'] as int?,
    );
  }

  ModelCampaign copyWith({
    String? campaignId,
    String? campaignName,
    String? campaignNameString,
    CampaignType? campaignType,
    int? collaborationCount,
    List<String>? referrerLinks,
    String? campaignAgencyId,
    String? campaignBrandId,
    String? userComment,
    String? adminComment,
    String? status,
    DateTime? validFrom,
    DateTime? validUntil,
    String? createdBy,
    String? updatedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? visitOrder,
    Map<String, dynamic>? resolvedLabels,
  }) {
    return ModelCampaign(
      campaignId: campaignId ?? this.campaignId,
      campaignName: campaignName ?? this.campaignName,
      campaignNameString: campaignNameString ?? this.campaignNameString,
      campaignType: campaignType ?? this.campaignType,
      collaborationCount: collaborationCount ?? this.collaborationCount,
      referrerLinks: referrerLinks ?? this.referrerLinks,
      campaignAgencyId: campaignAgencyId ?? this.campaignAgencyId,
      campaignBrandId: campaignBrandId ?? this.campaignBrandId,
      userComment: userComment ?? this.userComment,
      adminComment: adminComment ?? this.adminComment,
      status: status ?? this.status,
      validFrom: validFrom ?? this.validFrom,
      validUntil: validUntil ?? this.validUntil,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      visitOrder: visitOrder ?? this.visitOrder,
      resolvedLabels: resolvedLabels ?? _resolvedLabels,
    );
  }
}

class ModelCampaignMapper implements EntityMapper<ModelCampaign> {
  @override
  ModelCampaign fromMap(Map<String, dynamic> map) => ModelCampaign.fromMap(map);

  @override
  Map<String, dynamic> toMap(ModelCampaign entity) => entity.toMap();
}

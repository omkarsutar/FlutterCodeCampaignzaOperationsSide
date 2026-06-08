import '../../../../core/services/entity_service.dart';

class ModelCollaborationFields {
  static const String table = 'collaborations';
  static const String tableViewWithForeignKeyLabels = 'view_collaborations';

  static const String collaborationId = 'collaboration_id';
  static const String campaignId = 'campaign_id';
  static const String influencerId = 'influencer_id';
  static const String agreedCommissionAmount = 'agreed_commission_amount';
  static const String commissionType = 'commission_type';
  static const String commissionRate = 'commission_rate';
  static const String fixedAmount = 'fixed_amount';
  static const String barterDescription = 'barter_description';
  static const String isAcceptedByInfluencer = 'is_accepted_by_influencer';
  static const String promoCode = 'promo_code';
  static const String discountPercentage = 'discount_percentage';
  static const String createdBy = 'created_by';
  static const String updatedBy = 'updated_by';
  static const String createdAt = 'created_at';
  static const String updatedAt = 'updated_at';
  static const String isActive = 'is_active';

  // Compatibility fields
  static const String poId = campaignId;
  static const String productId = influencerId;
  static const String itemName = 'item_name';
  static const String itemQty = 'item_qty';
  static const String itemSellRate = 'item_sell_rate';
  static const String itemPrice = 'item_price';
  static const String itemUnitMrp = 'item_unit_mrp';
  static const String profitToBrand = 'profit_to_brand';

  static const Map<String, String> labels = {
    collaborationId: 'Collaboration',
    campaignId: 'Campaign',
    influencerId: 'Influencer',
    agreedCommissionAmount: 'Agreed Commission',
    commissionType: 'Commission Type',
    commissionRate: 'Commission Rate (%)',
    fixedAmount: 'Fixed Amount',
    barterDescription: 'Barter Details',
    isAcceptedByInfluencer: 'Accepted',
    promoCode: 'Promo Code',
    discountPercentage: 'Discount (%)',
    createdBy: 'Created By',
    updatedBy: 'Updated By',
    createdAt: 'Created At',
    updatedAt: 'Updated At',
    isActive: 'Is Active',
  };

  static String getLabel(String field) => labels[field] ?? field;
}

enum CommissionType {
  percentage,
  fixedAmount,
  barter;

  static CommissionType fromString(String? value) {
    switch (value) {
      case 'percentage':
        return CommissionType.percentage;
      case 'fixed_amount':
        return CommissionType.fixedAmount;
      case 'barter':
        return CommissionType.barter;
      default:
        return CommissionType.percentage;
    }
  }

  String toDbValue() {
    switch (this) {
      case CommissionType.percentage:
        return 'percentage';
      case CommissionType.fixedAmount:
        return 'fixed_amount';
      case CommissionType.barter:
        return 'barter';
    }
  }

  String get displayName {
    switch (this) {
      case CommissionType.percentage:
        return 'Percentage';
      case CommissionType.fixedAmount:
        return 'Fixed Amount';
      case CommissionType.barter:
        return 'Barter';
    }
  }
}

class ModelCollaboration {
  final String? collaborationId;
  final String? campaignId;
  final String? influencerId;
  final double? agreedCommissionAmount;
  final CommissionType? commissionType;
  final double? commissionRate;
  final double? fixedAmount;
  final String? barterDescription;
  final bool isAcceptedByInfluencer;
  final String? promoCode;
  final double? discountPercentage;
  final bool isActive;
  final String? createdBy;
  final String? updatedBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int? purchaseCount;
  final int? instagramInstallCount;
  final int? facebookInstallCount;
  final Map<String, dynamic> _resolvedLabels;

  // Compatibility properties
  String? get poId => campaignId;
  String? get productId => influencerId;
  String? get itemName =>
      resolvedLabels['influencer_id_label'] ?? 'Collaboration Item';
  double? get itemQty => 1.0;
  double? get itemSellRate => agreedCommissionAmount ?? 0.0;
  double? get itemPrice => agreedCommissionAmount ?? 0.0;
  double? get itemUnitMrp => agreedCommissionAmount ?? 0.0;
  double? get profitToBrand => 0.0;
  int get totalInstalls =>
      (instagramInstallCount ?? 0) + (facebookInstallCount ?? 0);

  ModelCollaboration({
    this.collaborationId,
    String? campaignId,
    String? influencerId,
    double? agreedCommissionAmount,
    this.commissionType,
    this.commissionRate,
    this.fixedAmount,
    this.barterDescription,
    this.isAcceptedByInfluencer = false,
    this.promoCode,
    this.discountPercentage,
    this.isActive = true,
    this.createdBy,
    this.updatedBy,
    this.createdAt,
    this.updatedAt,
    this.purchaseCount,
    this.instagramInstallCount,
    this.facebookInstallCount,
    // Compatibility constructor args
    String? poId,
    String? productId,
    String? itemName,
    double? itemQty,
    double? itemSellRate,
    double? itemPrice,
    double? itemUnitMrp,
    double? profitToBrand,
    Map<String, dynamic>? resolvedLabels,
  }) : campaignId = campaignId ?? poId,
       influencerId = influencerId ?? productId,
       agreedCommissionAmount =
           agreedCommissionAmount ?? itemPrice ?? itemSellRate,
       _resolvedLabels = resolvedLabels ?? const {};

  Map<String, dynamic> get resolvedLabels => _resolvedLabels;

  ModelCollaboration copyWith({
    String? collaborationId,
    String? campaignId,
    String? influencerId,
    double? agreedCommissionAmount,
    CommissionType? commissionType,
    double? commissionRate,
    double? fixedAmount,
    String? barterDescription,
    bool? isAcceptedByInfluencer,
    String? promoCode,
    double? discountPercentage,
    bool? isActive,
    String? createdBy,
    String? updatedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? purchaseCount,
    int? instagramInstallCount,
    int? facebookInstallCount,
    Map<String, dynamic>? resolvedLabels,
  }) {
    return ModelCollaboration(
      collaborationId: collaborationId ?? this.collaborationId,
      campaignId: campaignId ?? this.campaignId,
      influencerId: influencerId ?? this.influencerId,
      agreedCommissionAmount:
          agreedCommissionAmount ?? this.agreedCommissionAmount,
      commissionType: commissionType ?? this.commissionType,
      commissionRate: commissionRate ?? this.commissionRate,
      fixedAmount: fixedAmount ?? this.fixedAmount,
      barterDescription: barterDescription ?? this.barterDescription,
      isAcceptedByInfluencer:
          isAcceptedByInfluencer ?? this.isAcceptedByInfluencer,
      promoCode: promoCode ?? this.promoCode,
      discountPercentage: discountPercentage ?? this.discountPercentage,
      isActive: isActive ?? this.isActive,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      purchaseCount: purchaseCount ?? this.purchaseCount,
      instagramInstallCount:
          instagramInstallCount ?? this.instagramInstallCount,
      facebookInstallCount: facebookInstallCount ?? this.facebookInstallCount,
      resolvedLabels: resolvedLabels ?? _resolvedLabels,
    );
  }

  factory ModelCollaboration.fromMap(Map<String, dynamic> map) {
    final labelEntries = <String, dynamic>{};
    for (final entry in map.entries) {
      if (entry.key.endsWith('_label')) {
        labelEntries[entry.key] = entry.value;
      }
    }

    return ModelCollaboration(
      collaborationId: map[ModelCollaborationFields.collaborationId]
          ?.toString(),
      campaignId: map[ModelCollaborationFields.campaignId]?.toString(),
      influencerId: map[ModelCollaborationFields.influencerId]?.toString(),
      agreedCommissionAmount:
          map[ModelCollaborationFields.agreedCommissionAmount] != null
          ? double.tryParse(
              map[ModelCollaborationFields.agreedCommissionAmount].toString(),
            )
          : null,
      commissionType: CommissionType.fromString(
        map[ModelCollaborationFields.commissionType]?.toString(),
      ),
      commissionRate: map[ModelCollaborationFields.commissionRate] != null
          ? double.tryParse(
              map[ModelCollaborationFields.commissionRate].toString(),
            )
          : null,
      fixedAmount: map[ModelCollaborationFields.fixedAmount] != null
          ? double.tryParse(
              map[ModelCollaborationFields.fixedAmount].toString(),
            )
          : null,
      barterDescription: map[ModelCollaborationFields.barterDescription]
          ?.toString(),
      isAcceptedByInfluencer:
          map[ModelCollaborationFields.isAcceptedByInfluencer] == true,
      promoCode: map[ModelCollaborationFields.promoCode]?.toString(),
      discountPercentage:
          map[ModelCollaborationFields.discountPercentage] != null
          ? double.tryParse(
              map[ModelCollaborationFields.discountPercentage].toString(),
            )
          : null,
      isActive: map[ModelCollaborationFields.isActive] != false,
      createdBy: map[ModelCollaborationFields.createdBy]?.toString(),
      updatedBy: map[ModelCollaborationFields.updatedBy]?.toString(),
      createdAt: map[ModelCollaborationFields.createdAt] != null
          ? DateTime.tryParse(
              map[ModelCollaborationFields.createdAt].toString(),
            )
          : null,
      updatedAt: map[ModelCollaborationFields.updatedAt] != null
          ? DateTime.tryParse(
              map[ModelCollaborationFields.updatedAt].toString(),
            )
          : null,
      purchaseCount: map['purchase_count'] != null
          ? int.tryParse(map['purchase_count'].toString())
          : null,
      instagramInstallCount: map['instagram_install_count'] != null
          ? int.tryParse(map['instagram_install_count'].toString())
          : null,
      facebookInstallCount: map['facebook_install_count'] != null
          ? int.tryParse(map['facebook_install_count'].toString())
          : null,
      resolvedLabels: labelEntries,
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{};

    // Only include collaborationId if it's a valid UUID (not a local-only ID)
    if (collaborationId != null && _isValidUuid(collaborationId!)) {
      map[ModelCollaborationFields.collaborationId] = collaborationId;
    }
    if (campaignId != null) {
      map[ModelCollaborationFields.campaignId] = campaignId;
    }
    if (influencerId != null) {
      map[ModelCollaborationFields.influencerId] = influencerId;
    }
    if (agreedCommissionAmount != null) {
      map[ModelCollaborationFields.agreedCommissionAmount] =
          agreedCommissionAmount;
    }
    if (commissionType != null) {
      map[ModelCollaborationFields.commissionType] = commissionType!
          .toDbValue();
    }
    if (commissionRate != null) {
      map[ModelCollaborationFields.commissionRate] = commissionRate;
    }
    if (fixedAmount != null) {
      map[ModelCollaborationFields.fixedAmount] = fixedAmount;
    }
    if (barterDescription != null) {
      map[ModelCollaborationFields.barterDescription] = barterDescription;
    }
    map[ModelCollaborationFields.isAcceptedByInfluencer] =
        isAcceptedByInfluencer;
    if (promoCode != null) {
      map[ModelCollaborationFields.promoCode] = promoCode;
    }
    if (discountPercentage != null) {
      map[ModelCollaborationFields.discountPercentage] = discountPercentage;
    }
    map[ModelCollaborationFields.isActive] = isActive;

    return map;
  }

  Map<String, dynamic> toJson() {
    return {
      'collaborationId': collaborationId,
      'campaignId': campaignId,
      'influencerId': influencerId,
      'agreedCommissionAmount': agreedCommissionAmount,
      'commissionType': commissionType?.toDbValue(),
      'commissionRate': commissionRate,
      'fixedAmount': fixedAmount,
      'barterDescription': barterDescription,
      'isAcceptedByInfluencer': isAcceptedByInfluencer,
      'promoCode': promoCode,
      'discountPercentage': discountPercentage,
      'isActive': isActive,
      'createdBy': createdBy,
      'updatedBy': updatedBy,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory ModelCollaboration.fromJson(Map<String, dynamic> json) {
    return ModelCollaboration(
      collaborationId: json['collaborationId'] as String?,
      campaignId: json['campaignId'] as String?,
      influencerId: json['influencerId'] as String?,
      agreedCommissionAmount: (json['agreedCommissionAmount'] as num?)
          ?.toDouble(),
      commissionType: CommissionType.fromString(
        json['commissionType'] as String?,
      ),
      commissionRate: (json['commissionRate'] as num?)?.toDouble(),
      fixedAmount: (json['fixedAmount'] as num?)?.toDouble(),
      barterDescription: json['barterDescription'] as String?,
      isAcceptedByInfluencer: json['isAcceptedByInfluencer'] as bool? ?? false,
      promoCode: json['promoCode'] as String?,
      discountPercentage: (json['discountPercentage'] as num?)?.toDouble(),
      isActive: json['isActive'] as bool? ?? true,
      createdBy: json['createdBy'] as String?,
      updatedBy: json['updatedBy'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String)
          : null,
    );
  }

  /// Validates whether a string is a valid UUID v4 format
  static bool _isValidUuid(String value) {
    final uuidRegex = RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    );
    return uuidRegex.hasMatch(value);
  }
}

class ModelCollaborationMapper implements EntityMapper<ModelCollaboration> {
  @override
  ModelCollaboration fromMap(Map<String, dynamic> map) =>
      ModelCollaboration.fromMap(map);

  @override
  Map<String, dynamic> toMap(ModelCollaboration entity) => entity.toMap();
}

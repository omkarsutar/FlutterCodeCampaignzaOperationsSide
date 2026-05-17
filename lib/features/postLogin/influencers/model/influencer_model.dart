import '../../../../core/models/entity_meta.dart';
import '../../../../core/services/entity_service.dart';

const influencerEntityMeta = EntityMeta(
  entityName: 'Influencer',
  entityNameLower: 'influencer',
  entityNamePlural: 'Influencers',
  entityNamePluralLower: 'influencers',
);

class ModelInfluencerFields {
  static const String table = 'influencer';
  static const String tableViewWithForeignKeyLabels = 'view_products';

  static const String influencerId = 'influencer_id';
  static const String influencerCategory = 'influencer_category';
  static const String influencerName = 'influencer_name';
  static const String influencerNameHindi = 'influencer_name_hindi';
  static const String baseCommissionRate = 'base_commission_rate';
  static const String isActive = 'is_active';
  static const String isAvailable = 'is_available';
  static const String influencerImageUrl = 'influencer_image_url';
  static const String createdBy = 'created_by';
  static const String updatedBy = 'updated_by';
  static const String createdAt = 'created_at';
  static const String updatedAt = 'updated_at';

  static const Map<String, String> labels = {
    influencerId: 'Influencer',
    influencerCategory: 'Category',
    influencerName: 'Name',
    influencerNameHindi: 'Name (Hindi)',
    baseCommissionRate: 'Base Commission Rate (%)',
    isActive: 'Is Active',
    isAvailable: 'Is Available',
    influencerImageUrl: 'Profile Image',
    createdBy: 'Created By',
    updatedBy: 'Updated By',
    createdAt: 'Created At',
    updatedAt: 'Updated At',
  };

  static String getLabel(String field) => labels[field] ?? field;
}

class ModelInfluencer {
  final String? influencerId;
  final String influencerCategory;
  final String influencerName;
  final String? influencerNameHindi;
  final double baseCommissionRate;
  final bool isActive;
  final bool isAvailable;
  final String? influencerImageUrl;
  final String? createdBy;
  final String? updatedBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ModelInfluencer({
    this.influencerId,
    required this.influencerCategory,
    required this.influencerName,
    this.influencerNameHindi,
    required this.baseCommissionRate,
    required this.isActive,
    required this.isAvailable,
    this.influencerImageUrl,
    this.createdBy,
    this.updatedBy,
    this.createdAt,
    this.updatedAt,
  });

  factory ModelInfluencer.fromMap(Map<String, dynamic> map) {
    return ModelInfluencer(
      influencerId: map[ModelInfluencerFields.influencerId]?.toString(),
      influencerCategory:
          map[ModelInfluencerFields.influencerCategory]?.toString() ?? '',
      influencerName:
          map[ModelInfluencerFields.influencerName]?.toString() ?? '',
      influencerNameHindi:
          map[ModelInfluencerFields.influencerNameHindi]?.toString(),
      baseCommissionRate: double.tryParse(
            map[ModelInfluencerFields.baseCommissionRate]?.toString() ?? '',
          ) ??
          0.0,
      isActive: map[ModelInfluencerFields.isActive] != false,
      isAvailable: map[ModelInfluencerFields.isAvailable] != false,
      influencerImageUrl:
          map[ModelInfluencerFields.influencerImageUrl]?.toString(),
      createdBy: map[ModelInfluencerFields.createdBy]?.toString(),
      updatedBy: map[ModelInfluencerFields.updatedBy]?.toString(),
      createdAt: map[ModelInfluencerFields.createdAt] != null
          ? DateTime.tryParse(map[ModelInfluencerFields.createdAt].toString())
          : null,
      updatedAt: map[ModelInfluencerFields.updatedAt] != null
          ? DateTime.tryParse(map[ModelInfluencerFields.updatedAt].toString())
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (influencerId != null) ModelInfluencerFields.influencerId: influencerId,
      ModelInfluencerFields.influencerCategory: influencerCategory,
      ModelInfluencerFields.influencerName: influencerName,
      if (influencerNameHindi != null)
        ModelInfluencerFields.influencerNameHindi: influencerNameHindi,
      ModelInfluencerFields.baseCommissionRate: baseCommissionRate,
      ModelInfluencerFields.isActive: isActive,
      ModelInfluencerFields.isAvailable: isAvailable,
      if (influencerImageUrl != null)
        ModelInfluencerFields.influencerImageUrl: influencerImageUrl,
      if (createdBy != null) ModelInfluencerFields.createdBy: createdBy,
      if (updatedBy != null) ModelInfluencerFields.updatedBy: updatedBy,
      if (createdAt != null)
        ModelInfluencerFields.createdAt: createdAt!.toIso8601String(),
      if (updatedAt != null)
        ModelInfluencerFields.updatedAt: updatedAt!.toIso8601String(),
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'influencerId': influencerId,
      'influencerCategory': influencerCategory,
      'influencerName': influencerName,
      'influencerNameHindi': influencerNameHindi,
      'baseCommissionRate': baseCommissionRate,
      'isActive': isActive,
      'isAvailable': isAvailable,
      'influencerImageUrl': influencerImageUrl,
      'createdBy': createdBy,
      'updatedBy': updatedBy,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory ModelInfluencer.fromJson(Map<String, dynamic> json) {
    return ModelInfluencer(
      influencerId: json['influencerId'] as String?,
      influencerCategory: json['influencerCategory'] as String? ?? '',
      influencerName: json['influencerName'] as String? ?? '',
      influencerNameHindi: json['influencerNameHindi'] as String?,
      baseCommissionRate:
          (json['baseCommissionRate'] as num?)?.toDouble() ?? 0.0,
      isActive: json['isActive'] as bool? ?? true,
      isAvailable: json['isAvailable'] as bool? ?? true,
      influencerImageUrl: json['influencerImageUrl'] as String?,
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

  ModelInfluencer copyWith({
    String? influencerId,
    String? influencerCategory,
    String? influencerName,
    String? influencerNameHindi,
    double? baseCommissionRate,
    bool? isActive,
    bool? isAvailable,
    String? influencerImageUrl,
    String? createdBy,
    String? updatedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ModelInfluencer(
      influencerId: influencerId ?? this.influencerId,
      influencerCategory: influencerCategory ?? this.influencerCategory,
      influencerName: influencerName ?? this.influencerName,
      influencerNameHindi: influencerNameHindi ?? this.influencerNameHindi,
      baseCommissionRate: baseCommissionRate ?? this.baseCommissionRate,
      isActive: isActive ?? this.isActive,
      isAvailable: isAvailable ?? this.isAvailable,
      influencerImageUrl: influencerImageUrl ?? this.influencerImageUrl,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class ModelInfluencerMapper implements EntityMapper<ModelInfluencer> {
  @override
  ModelInfluencer fromMap(Map<String, dynamic> map) =>
      ModelInfluencer.fromMap(map);

  @override
  Map<String, dynamic> toMap(ModelInfluencer entity) => entity.toMap();
}
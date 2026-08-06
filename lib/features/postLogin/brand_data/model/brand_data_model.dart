class ModelBrandDataFields {
  static const String table = 'brand_data';

  static const String id = 'id';
  static const String brandName = 'brand_name';
  static const String brandPhotoUrl = 'brand_photo_url';
  static const String websiteUrl = 'website_url';
  static const String androidAppId = 'android_app_id';
  static const String metaPixelId = 'meta_pixel_id';
  static const String gmbProfileUrl = 'gmb_profile_url';
  static const String gmbReviewTexts = 'gmb_review_texts';
  static const String gmbReviewTextsHi = 'gmb_review_texts_hi';
  static const String gmbReviewTextsMr = 'gmb_review_texts_mr';
  static const String whatsappNo = 'whatsapp_no';
  static const String whatsappMsgText = 'whatsapp_msg_text';
  static const String youtubeUrl = 'youtube_url';
  static const String instagramUrl = 'instagram_url';
  static const String facebookUrl = 'facebook_url';
  static const String isActive = 'is_active';
  static const String createdAt = 'created_at';
  static const String updatedAt = 'updated_at';
  static const String createdBy = 'created_by';
  static const String updatedBy = 'updated_by';

  static const Map<String, String> labels = {
    id: 'ID',
    brandName: 'Brand Name',
    brandPhotoUrl: 'Brand Photo URL',
    websiteUrl: 'Website URL',
    androidAppId: 'Android App ID',
    metaPixelId: 'Meta Pixel ID',
    gmbProfileUrl: 'GMB Profile URL',
    gmbReviewTexts: 'GMB Review Texts',
    gmbReviewTextsHi: 'GMB Review Texts (HI)',
    gmbReviewTextsMr: 'GMB Review Texts (MR)',
    whatsappNo: 'WhatsApp Number',
    whatsappMsgText: 'WhatsApp Message Text',
    youtubeUrl: 'YouTube URL',
    instagramUrl: 'Instagram URL',
    facebookUrl: 'Facebook URL',
    isActive: 'Active',
    createdAt: 'Created At',
    updatedAt: 'Updated At',
    createdBy: 'Created By',
    updatedBy: 'Updated By',
  };

  static String getLabel(String field) => labels[field] ?? field;
}

class ModelBrandData {
  final String? id;
  final String brandName;
  final String? brandPhotoUrl;
  final String? websiteUrl;
  final String? androidAppId;
  final String? metaPixelId;
  final String? gmbProfileUrl;
  final List<String>? gmbReviewTexts;
  final List<String>? gmbReviewTextsHi;
  final List<String>? gmbReviewTextsMr;
  final String? whatsappNo;
  final String? whatsappMsgText;
  final String? youtubeUrl;
  final String? instagramUrl;
  final String? facebookUrl;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? createdBy;
  final String? updatedBy;
  final Map<String, dynamic> _resolvedLabels;

  ModelBrandData({
    this.id,
    required this.brandName,
    this.brandPhotoUrl,
    this.websiteUrl,
    this.androidAppId,
    this.metaPixelId,
    this.gmbProfileUrl,
    this.gmbReviewTexts,
    this.gmbReviewTextsHi,
    this.gmbReviewTextsMr,
    this.whatsappNo,
    this.whatsappMsgText,
    this.youtubeUrl,
    this.instagramUrl,
    this.facebookUrl,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
    this.createdBy,
    this.updatedBy,
    Map<String, dynamic>? resolvedLabels,
  }) : _resolvedLabels = resolvedLabels ?? const {};

  Map<String, dynamic> get resolvedLabels => _resolvedLabels;

  factory ModelBrandData.fromMap(Map<String, dynamic> map) {
    final labelEntries = <String, dynamic>{};
    for (final entry in map.entries) {
      if (entry.key.endsWith('_label')) {
        labelEntries[entry.key] = entry.value;
      }
    }

    return ModelBrandData(
      id: map[ModelBrandDataFields.id] as String?,
      brandName: map[ModelBrandDataFields.brandName] as String? ?? '',
      brandPhotoUrl: map[ModelBrandDataFields.brandPhotoUrl] as String?,
      websiteUrl: map[ModelBrandDataFields.websiteUrl] as String?,
      androidAppId: map[ModelBrandDataFields.androidAppId] as String?,
      metaPixelId: map[ModelBrandDataFields.metaPixelId] as String?,
      gmbProfileUrl: map[ModelBrandDataFields.gmbProfileUrl] as String?,
      gmbReviewTexts: (map[ModelBrandDataFields.gmbReviewTexts] as List?)
          ?.map((e) => e?.toString() ?? '')
          .where((e) => e.isNotEmpty)
          .toList(),
      gmbReviewTextsHi: (map[ModelBrandDataFields.gmbReviewTextsHi] as List?)
          ?.map((e) => e?.toString() ?? '')
          .where((e) => e.isNotEmpty)
          .toList(),
      gmbReviewTextsMr: (map[ModelBrandDataFields.gmbReviewTextsMr] as List?)
          ?.map((e) => e?.toString() ?? '')
          .where((e) => e.isNotEmpty)
          .toList(),
      whatsappNo: map[ModelBrandDataFields.whatsappNo] as String?,
      whatsappMsgText: map[ModelBrandDataFields.whatsappMsgText] as String?,
      youtubeUrl: map[ModelBrandDataFields.youtubeUrl] as String?,
      instagramUrl: map[ModelBrandDataFields.instagramUrl] as String?,
      facebookUrl: map[ModelBrandDataFields.facebookUrl] as String?,
      isActive: map[ModelBrandDataFields.isActive] as bool? ?? true,
      createdAt: map[ModelBrandDataFields.createdAt] != null
          ? DateTime.tryParse(map[ModelBrandDataFields.createdAt].toString())
          : null,
      updatedAt: map[ModelBrandDataFields.updatedAt] != null
          ? DateTime.tryParse(map[ModelBrandDataFields.updatedAt].toString())
          : null,
      createdBy: map[ModelBrandDataFields.createdBy] as String?,
      updatedBy: map[ModelBrandDataFields.updatedBy] as String?,
      resolvedLabels: labelEntries,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) ModelBrandDataFields.id: id,
      ModelBrandDataFields.brandName: brandName,
      if (brandPhotoUrl != null)
        ModelBrandDataFields.brandPhotoUrl: brandPhotoUrl,
      if (websiteUrl != null) ModelBrandDataFields.websiteUrl: websiteUrl,
      if (androidAppId != null) ModelBrandDataFields.androidAppId: androidAppId,
      if (metaPixelId != null) ModelBrandDataFields.metaPixelId: metaPixelId,
      if (gmbProfileUrl != null)
        ModelBrandDataFields.gmbProfileUrl: gmbProfileUrl,
      if (gmbReviewTexts != null)
        ModelBrandDataFields.gmbReviewTexts: gmbReviewTexts,
      if (gmbReviewTextsHi != null)
        ModelBrandDataFields.gmbReviewTextsHi: gmbReviewTextsHi,
      if (gmbReviewTextsMr != null)
        ModelBrandDataFields.gmbReviewTextsMr: gmbReviewTextsMr,
      if (whatsappNo != null) ModelBrandDataFields.whatsappNo: whatsappNo,
      if (whatsappMsgText != null)
        ModelBrandDataFields.whatsappMsgText: whatsappMsgText,
      if (youtubeUrl != null) ModelBrandDataFields.youtubeUrl: youtubeUrl,
      if (instagramUrl != null) ModelBrandDataFields.instagramUrl: instagramUrl,
      if (facebookUrl != null) ModelBrandDataFields.facebookUrl: facebookUrl,
      ModelBrandDataFields.isActive: isActive,
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'brandName': brandName,
      'brandPhotoUrl': brandPhotoUrl,
      'websiteUrl': websiteUrl,
      'androidAppId': androidAppId,
      'metaPixelId': metaPixelId,
      'gmbProfileUrl': gmbProfileUrl,
      'gmbReviewTexts': gmbReviewTexts,
      'gmbReviewTextsHi': gmbReviewTextsHi,
      'gmbReviewTextsMr': gmbReviewTextsMr,
      'whatsappNo': whatsappNo,
      'whatsappMsgText': whatsappMsgText,
      'youtubeUrl': youtubeUrl,
      'instagramUrl': instagramUrl,
      'facebookUrl': facebookUrl,
      'isActive': isActive,
    };
  }

  factory ModelBrandData.fromJson(Map<String, dynamic> json) {
    return ModelBrandData(
      id: json['id'] as String?,
      brandName: json['brandName'] as String? ?? '',
      brandPhotoUrl: json['brandPhotoUrl'] as String?,
      websiteUrl: json['websiteUrl'] as String?,
      androidAppId: json['androidAppId'] as String?,
      metaPixelId: json['metaPixelId'] as String?,
      gmbProfileUrl: json['gmbProfileUrl'] as String?,
      gmbReviewTexts: (json['gmbReviewTexts'] as List?)
          ?.map((e) => e?.toString() ?? '')
          .where((e) => e.isNotEmpty)
          .toList(),
      gmbReviewTextsHi: (json['gmbReviewTextsHi'] as List?)
          ?.map((e) => e?.toString() ?? '')
          .where((e) => e.isNotEmpty)
          .toList(),
      gmbReviewTextsMr: (json['gmbReviewTextsMr'] as List?)
          ?.map((e) => e?.toString() ?? '')
          .where((e) => e.isNotEmpty)
          .toList(),
      whatsappNo: json['whatsappNo'] as String?,
      whatsappMsgText: json['whatsappMsgText'] as String?,
      youtubeUrl: json['youtubeUrl'] as String?,
      instagramUrl: json['instagramUrl'] as String?,
      facebookUrl: json['facebookUrl'] as String?,
      isActive: json['isActive'] as bool? ?? true,
    );
  }
}

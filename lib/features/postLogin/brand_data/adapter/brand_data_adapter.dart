import '../../../../core/services/entity_service.dart';
import '../model/brand_data_model.dart';

class BrandDataAdapter implements EntityAdapter<ModelBrandData> {
  @override
  dynamic getFieldValue(ModelBrandData entity, String fieldName) {
    switch (fieldName) {
      case ModelBrandDataFields.id:
        return entity.id;
      case ModelBrandDataFields.brandName:
        return entity.brandName;
      case ModelBrandDataFields.brandPhotoUrl:
        return entity.brandPhotoUrl;
      case ModelBrandDataFields.websiteUrl:
        return entity.websiteUrl;
      case ModelBrandDataFields.androidAppId:
        return entity.androidAppId;
      case ModelBrandDataFields.metaPixelId:
        return entity.metaPixelId;
      case ModelBrandDataFields.gmbProfileUrl:
        return entity.gmbProfileUrl;
      case ModelBrandDataFields.gmbReviewTexts:
        return entity.gmbReviewTexts;
      case ModelBrandDataFields.gmbReviewTextsHi:
        return entity.gmbReviewTextsHi;
      case ModelBrandDataFields.gmbReviewTextsMr:
        return entity.gmbReviewTextsMr;
      case ModelBrandDataFields.whatsappNo:
        return entity.whatsappNo;
      case ModelBrandDataFields.whatsappMsgText:
        return entity.whatsappMsgText;
      case ModelBrandDataFields.youtubeUrl:
        return entity.youtubeUrl;
      case ModelBrandDataFields.instagramUrl:
        return entity.instagramUrl;
      case ModelBrandDataFields.facebookUrl:
        return entity.facebookUrl;
      case ModelBrandDataFields.isActive:
        return entity.isActive;
      case ModelBrandDataFields.createdAt:
        return entity.createdAt;
      case ModelBrandDataFields.updatedAt:
        return entity.updatedAt;
      default:
        return null;
    }
  }

  @override
  dynamic getLabelValue(ModelBrandData entity, String fieldName) {
    return entity.resolvedLabels['${fieldName}_label'];
  }

  @override
  dynamic getId(ModelBrandData entity, String idField) => entity.id;

  @override
  dynamic getTimestamp(ModelBrandData entity, String timestampField) {
    return entity.createdAt;
  }
}

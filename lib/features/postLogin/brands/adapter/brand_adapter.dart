import '../../../../core/services/entity_service.dart';
import '../model/brand_model.dart';

class BrandAdapter implements EntityAdapter<ModelBrand> {
  @override
  dynamic getFieldValue(ModelBrand entity, String fieldName) {
    switch (fieldName) {
      case ModelBrandFields.brandId:
        return entity.brandId;
      case ModelBrandFields.brandName:
        return entity.brandName;
      case ModelBrandFields.brandsPrimaryRoute:
        return entity.brandsPrimaryRoute;
      case ModelBrandFields.brandNote:
        return entity.brandNote;
      case ModelBrandFields.hiddenNote:
        return entity.hiddenNote;
      case ModelBrandFields.brandMobile1:
        return entity.brandMobile1;
      case ModelBrandFields.brandMobile2:
        return entity.brandMobile2;
      case ModelBrandFields.brandPersonName:
        return entity.brandPersonName;
      case ModelBrandFields.isActive:
        return entity.isActive;
      case ModelBrandFields.brandLocationUrl:
        return entity.brandLocationUrl;
      case ModelBrandFields.brandLandmark:
        return entity.brandLandmark;
      case ModelBrandFields.brandAddress:
        return entity.brandAddress;
      case ModelBrandFields.brandPhotoId:
        return entity.brandPhotoId;
      case ModelBrandFields.brandPhotoUrl:
        return entity.brandPhotoUrl;
      case ModelBrandFields.brandLat:
        return entity.brandLat;
      case ModelBrandFields.brandLong:
        return entity.brandLong;
      case ModelBrandFields.createdAt:
        return entity.createdAt;
      case ModelBrandFields.updatedAt:
        return entity.updatedAt;
      case ModelBrandFields.visitOrder:
        return entity.visitOrder;
      default:
        return null;
    }
  }

  @override
  dynamic getLabelValue(ModelBrand entity, String fieldName) {
    return entity.resolvedLabels['${fieldName}_label'];
  }

  /* @override
  dynamic getLabelValue(ModelBrand entity, String fieldName) {
    return null; // or custom label logic
  } */

  @override
  dynamic getId(ModelBrand entity, String idField) => entity.brandId;

  @override
  dynamic getTimestamp(ModelBrand entity, String timestampField) {
    return entity.createdAt;
  }
}

import '../../../../core/services/entity_service.dart';
import '../model/agency_brand_link_model.dart';

class AgencyBrandLinkAdapter implements EntityAdapter<ModelAgencyBrandLink> {
  @override
  dynamic getFieldValue(ModelAgencyBrandLink entity, String fieldName) {
    switch (fieldName) {
      case ModelAgencyBrandLinkFields.linkId:
        return entity.linkId;
      case ModelAgencyBrandLinkFields.agencyId:
        return entity.agencyId;
      case ModelAgencyBrandLinkFields.brandId:
        return entity.brandId;
      case ModelAgencyBrandLinkFields.visitOrder:
        return entity.visitOrder;
      case ModelAgencyBrandLinkFields.createdAt:
        return entity.createdAt;
      case ModelAgencyBrandLinkFields.updatedAt:
        return entity.updatedAt;
      default:
        return null;
    }
  }

  @override
  dynamic getLabelValue(ModelAgencyBrandLink entity, String fieldName) {
    return entity.resolvedLabels['${fieldName}_label'];
  }

  @override
  dynamic getId(ModelAgencyBrandLink entity, String idField) => entity.linkId;

  @override
  dynamic getTimestamp(ModelAgencyBrandLink entity, String timestampField) {
    return entity.createdAt;
  }
}

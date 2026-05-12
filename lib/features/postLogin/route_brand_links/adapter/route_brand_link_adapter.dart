import '../../../../core/services/entity_service.dart';
import '../model/route_brand_link_model.dart';

class RouteBrandLinkAdapter implements EntityAdapter<ModelRouteBrandLink> {
  @override
  dynamic getFieldValue(ModelRouteBrandLink entity, String fieldName) {
    switch (fieldName) {
      case ModelRouteBrandLinkFields.linkId:
        return entity.linkId;
      case ModelRouteBrandLinkFields.routeId:
        return entity.routeId;
      case ModelRouteBrandLinkFields.brandId:
        return entity.brandId;
      case ModelRouteBrandLinkFields.visitOrder:
        return entity.visitOrder;
      case ModelRouteBrandLinkFields.createdAt:
        return entity.createdAt;
      case ModelRouteBrandLinkFields.updatedAt:
        return entity.updatedAt;
      default:
        return null;
    }
  }

  @override
  dynamic getLabelValue(ModelRouteBrandLink entity, String fieldName) {
    return entity.resolvedLabels['${fieldName}_label'];
  }

  /* @override
  dynamic getLabelValue(ModelRouteBrandLink entity, String fieldName) {
    return null; // or custom label logic
  } */

  @override
  dynamic getId(ModelRouteBrandLink entity, String idField) => entity.linkId;

  @override
  dynamic getTimestamp(ModelRouteBrandLink entity, String timestampField) {
    return entity.createdAt;
  }
}

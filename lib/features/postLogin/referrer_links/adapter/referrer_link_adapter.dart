import '../../../../core/services/entity_service.dart';
import '../model/referrer_link_model.dart';

class ReferrerLinkAdapter implements EntityAdapter<ModelReferrerLink> {
  @override
  dynamic getFieldValue(ModelReferrerLink entity, String fieldName) {
    switch (fieldName) {
      case ModelReferrerLinkFields.moduleId:
        return entity.moduleId;
      case ModelReferrerLinkFields.moduleName:
        return entity.moduleName;
      case ModelReferrerLinkFields.moduleDescription:
        return entity.moduleDescription;
      case ModelReferrerLinkFields.createdAt:
        return entity.createdAt;
      case ModelReferrerLinkFields.updatedAt:
        return entity.updatedAt;
      case ModelReferrerLinkFields.isActive:
        return entity.isActive;
      default:
        return null;
    }
  }

  @override
  dynamic getLabelValue(ModelReferrerLink entity, String fieldName) {
    return null; // or custom label logic
  }

  @override
  dynamic getId(ModelReferrerLink entity, String idField) => entity.moduleId;

  @override
  dynamic getTimestamp(ModelReferrerLink entity, String timestampField) {
    return entity.createdAt;
  }
}

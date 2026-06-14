import '../../../../core/services/entity_service.dart';
import '../model/referrer_link_model.dart';

class ReferrerLinkAdapter implements EntityAdapter<ModelReferrerLink> {
  @override
  dynamic getFieldValue(ModelReferrerLink entity, String fieldName) {
    switch (fieldName) {
      case ModelReferrerLinkFields.referrerLinkId:
        return entity.referrerLinkId;
      case ModelReferrerLinkFields.referrerLinkString:
        return entity.referrerLinkString;
      case ModelReferrerLinkFields.referrerLinkType:
        return entity.referrerLinkType;
      case ModelReferrerLinkFields.campaignId:
        return entity.campaignId;
      case ModelReferrerLinkFields.campaignType:
        return entity.campaignType;
      case ModelReferrerLinkFields.collaborationId:
        return entity.collaborationId;
      case ModelReferrerLinkFields.referrerLinkSource:
        return entity.referrerLinkSource;
      case ModelReferrerLinkFields.createdAt:
        return entity.createdAt;
      case ModelReferrerLinkFields.updatedAt:
        return entity.updatedAt;
      default:
        return null;
    }
  }

  @override
  dynamic getLabelValue(ModelReferrerLink entity, String fieldName) {
    return null;
  }

  @override
  dynamic getId(ModelReferrerLink entity, String idField) => entity.referrerLinkId;

  @override
  dynamic getTimestamp(ModelReferrerLink entity, String timestampField) {
    return entity.createdAt;
  }
}

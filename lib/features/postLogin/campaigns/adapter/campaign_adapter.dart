import '../../../../core/services/entity_service.dart';
import '../model/campaign_model.dart';

class CampaignAdapter implements EntityAdapter<ModelCampaign> {
  @override
  dynamic getFieldValue(ModelCampaign entity, String fieldName) {
    switch (fieldName) {
      case ModelCampaignFields.campaignId:
        return entity.campaignId;
      case ModelCampaignFields.collaborationCount:
        return entity.collaborationCount;
      case ModelCampaignFields.campaignAgencyId:
        return entity.campaignAgencyId;
      case ModelCampaignFields.campaignBrandId:
        return entity.campaignBrandId;
      case ModelCampaignFields.userComment:
        return entity.userComment;
      case ModelCampaignFields.adminComment:
        return entity.adminComment;
      case ModelCampaignFields.status:
        return entity.status;
      case ModelCampaignFields.createdBy:
        return entity.createdBy;
      case ModelCampaignFields.updatedBy:
        return entity.updatedBy;
      case ModelCampaignFields.createdAt:
        return entity.createdAt;
      case ModelCampaignFields.updatedAt:
        return entity.updatedAt;
      default:
        return null;
    }
  }

  @override
  dynamic getLabelValue(ModelCampaign entity, String fieldName) {
    if (entity.resolvedLabels.containsKey('${fieldName}_label')) {
      return entity.resolvedLabels['${fieldName}_label'];
    }
    switch (fieldName) {
      case ModelCampaignFields.campaignAgencyId:
      case ModelCampaignFields.campaignBrandId:
      case ModelCampaignFields.createdBy:
      case ModelCampaignFields.updatedBy:
        return entity.resolvedLabels['${fieldName}_label'];
      case ModelCampaignFields.status:
        return entity.status ?? 'Pending';
      case ModelCampaignFields.collaborationCount:
        return entity.collaborationCount?.toString() ?? '0';
      default:
        return null;
    }
  }

  @override
  dynamic getId(ModelCampaign entity, String idField) => entity.campaignId;

  @override
  dynamic getTimestamp(ModelCampaign entity, String timestampField) {
    return entity.createdAt;
  }
}
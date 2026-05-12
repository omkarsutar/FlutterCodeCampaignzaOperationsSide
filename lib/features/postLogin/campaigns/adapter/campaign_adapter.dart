import '../../../../core/services/entity_service.dart';
import '../model/campaign_model.dart';

class CampaignAdapter implements EntityAdapter<ModelCampaign> {
  @override
  dynamic getFieldValue(ModelCampaign entity, String fieldName) {
    switch (fieldName) {
      case ModelCampaignFields.poId:
        return entity.poId;
      case ModelCampaignFields.poTotalAmount:
        return entity.poTotalAmount;
      case ModelCampaignFields.poLineItemCount:
        return entity.poLineItemCount;
      case ModelCampaignFields.poRouteId:
        return entity.poRouteId;
      case ModelCampaignFields.poBrandId:
        return entity.poBrandId;
      case ModelCampaignFields.userComment:
        return entity.userComment;
      case ModelCampaignFields.profitToBrand:
        return entity.profitToBrand;
      case ModelCampaignFields.poLat:
        return entity.poLat;
      case ModelCampaignFields.poLong:
        return entity.poLong;
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

  /* @override
  dynamic getLabelValue(ModelCampaign entity, String fieldName) {
    return null; // or custom label logic
  } */

  @override
  dynamic getLabelValue(ModelCampaign entity, String fieldName) {
    if (entity.resolvedLabels.containsKey('${fieldName}_label')) {
      return entity.resolvedLabels['${fieldName}_label'];
    }
    switch (fieldName) {
      case ModelCampaignFields.poRouteId:
      case ModelCampaignFields.poBrandId:
      case ModelCampaignFields.createdBy:
      case ModelCampaignFields.updatedBy:
        return entity.resolvedLabels['${fieldName}_label'];
      case ModelCampaignFields.status:
        return entity.status ?? 'Pending';
      default:
        return null;
    }
  }

  @override
  dynamic getId(ModelCampaign entity, String idField) => entity.poId;

  @override
  dynamic getTimestamp(ModelCampaign entity, String timestampField) {
    return entity.createdAt;
  }
}

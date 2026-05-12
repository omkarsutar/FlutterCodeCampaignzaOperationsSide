import '../../../../core/services/entity_service.dart';
import '../model/collaboration_model.dart';

class CollaborationAdapter implements EntityAdapter<ModelCollaboration> {
  @override
  dynamic getFieldValue(ModelCollaboration entity, String fieldName) {
    switch (fieldName) {
      case ModelCollaborationFields.collaborationId:
        return entity.collaborationId;
      case ModelCollaborationFields.poId:
        return entity.poId;
      case ModelCollaborationFields.productId:
        return entity.productId;
      case ModelCollaborationFields.itemName:
        return entity.itemName;
      case ModelCollaborationFields.itemQty:
        return entity.itemQty;
      case ModelCollaborationFields.itemSellRate:
        return entity.itemSellRate;
      case ModelCollaborationFields.itemPrice:
        return entity.itemPrice;
      case ModelCollaborationFields.itemUnitMrp:
        return entity.itemUnitMrp;
      case ModelCollaborationFields.profitToBrand:
        return entity.profitToBrand;
      case ModelCollaborationFields.createdBy:
        return entity.createdBy;
      case ModelCollaborationFields.updatedBy:
        return entity.updatedBy;
      case ModelCollaborationFields.createdAt:
        return entity.createdAt;
      case ModelCollaborationFields.updatedAt:
        return entity.updatedAt;
      default:
        return null;
    }
  }

  @override
  dynamic getLabelValue(ModelCollaboration entity, String fieldName) {
    return entity.resolvedLabels['${fieldName}_label'];
  }

  /* @override
  dynamic getLabelValue(ModelCollaboration entity, String fieldName) {
    return null; // or custom label logic
  } */

  @override
  dynamic getId(ModelCollaboration entity, String idField) =>
      entity.collaborationId;

  @override
  dynamic getTimestamp(ModelCollaboration entity, String timestampField) {
    return entity.createdAt;
  }
}

import '../../../../core/services/entity_service.dart';
import '../model/collaboration_model.dart';

class CollaborationAdapter implements EntityAdapter<ModelCollaboration> {
  @override
  dynamic getFieldValue(ModelCollaboration entity, String fieldName) {
    switch (fieldName) {
      case ModelCollaborationFields.collaborationId:
        return entity.collaborationId;
      case ModelCollaborationFields.campaignId:
        return entity.campaignId;
      case ModelCollaborationFields.influencerId:
        return entity.influencerId;
      case ModelCollaborationFields.agreedCommissionAmount:
        return entity.agreedCommissionAmount;
      case ModelCollaborationFields.commissionType:
        return entity.commissionType?.toDbValue();
      case ModelCollaborationFields.commissionRate:
        return entity.commissionRate;
      case ModelCollaborationFields.fixedAmount:
        return entity.fixedAmount;
      case ModelCollaborationFields.barterDescription:
        return entity.barterDescription;
      case ModelCollaborationFields.isAcceptedByInfluencer:
        return entity.isAcceptedByInfluencer;
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
    // Check for resolved labels from joined queries
    if (entity.resolvedLabels.containsKey('${fieldName}_label')) {
      return entity.resolvedLabels['${fieldName}_label'];
    }

    // Custom label logic for certain fields
    switch (fieldName) {
      case ModelCollaborationFields.commissionType:
        return entity.commissionType?.displayName ?? 'Not Set';
      case ModelCollaborationFields.isAcceptedByInfluencer:
        return entity.isAcceptedByInfluencer ? 'Accepted' : 'Pending';
      case ModelCollaborationFields.agreedCommissionAmount:
        return entity.agreedCommissionAmount != null
            ? '₹${entity.agreedCommissionAmount!.toStringAsFixed(2)}'
            : null;
      case ModelCollaborationFields.commissionRate:
        return entity.commissionRate != null
            ? '${entity.commissionRate}%'
            : null;
      case ModelCollaborationFields.fixedAmount:
        return entity.fixedAmount != null
            ? '₹${entity.fixedAmount!.toStringAsFixed(2)}'
            : null;
      default:
        return null;
    }
  }

  @override
  dynamic getId(ModelCollaboration entity, String idField) =>
      entity.collaborationId;

  @override
  dynamic getTimestamp(ModelCollaboration entity, String timestampField) {
    return entity.createdAt;
  }
}
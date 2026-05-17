import '../../../../core/services/entity_service.dart';
import '../model/influencer_model.dart';

class InfluencerAdapter implements EntityAdapter<ModelInfluencer> {
  @override
  dynamic getFieldValue(ModelInfluencer entity, String fieldName) {
    switch (fieldName) {
      case ModelInfluencerFields.influencerId:
        return entity.influencerId;
      case ModelInfluencerFields.influencerCategory:
        return entity.influencerCategory;
      case ModelInfluencerFields.influencerName:
        return entity.influencerName;
      case ModelInfluencerFields.influencerNameHindi:
        return entity.influencerNameHindi;
      case ModelInfluencerFields.baseCommissionRate:
        return entity.baseCommissionRate;
      case ModelInfluencerFields.isActive:
        return entity.isActive;
      case ModelInfluencerFields.isAvailable:
        return entity.isAvailable;
      case ModelInfluencerFields.influencerImageUrl:
        return entity.influencerImageUrl;
      case ModelInfluencerFields.createdBy:
        return entity.createdBy;
      case ModelInfluencerFields.updatedBy:
        return entity.updatedBy;
      case ModelInfluencerFields.createdAt:
        return entity.createdAt;
      case ModelInfluencerFields.updatedAt:
        return entity.updatedAt;
      default:
        return null;
    }
  }

  @override
  dynamic getLabelValue(ModelInfluencer entity, String fieldName) {
    switch (fieldName) {
      case ModelInfluencerFields.createdAt:
        return _formatDate(entity.createdAt);
      case ModelInfluencerFields.updatedAt:
        return _formatDate(entity.updatedAt);
      case ModelInfluencerFields.isActive:
      case ModelInfluencerFields.isAvailable:
        return (getFieldValue(entity, fieldName) == true) ? 'Yes' : 'No';
      case ModelInfluencerFields.baseCommissionRate:
        return '${entity.baseCommissionRate}%';
      default:
        return null;
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  dynamic getId(ModelInfluencer entity, String idField) => entity.influencerId;

  @override
  dynamic getTimestamp(ModelInfluencer entity, String timestampField) {
    return entity.createdAt;
  }
}
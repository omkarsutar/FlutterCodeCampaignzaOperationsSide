import '../../../../core/services/entity_service.dart';
import '../model/user_influencer_link_model.dart';

class UserInfluencerLinkAdapter extends EntityAdapter<ModelUserInfluencerLink> {
  @override
  String getId(ModelUserInfluencerLink entity, String idField) => entity.linkId;

  @override
  dynamic getFieldValue(ModelUserInfluencerLink entity, String fieldName) {
    switch (fieldName) {
      case ModelUserInfluencerLinkFields.linkId:
        return entity.linkId;
      case ModelUserInfluencerLinkFields.userId:
        return entity.userId;
      case ModelUserInfluencerLinkFields.influencerId:
        return entity.influencerId;
      case ModelUserInfluencerLinkFields.createdAt:
        return entity.createdAt;
      case ModelUserInfluencerLinkFields.updatedAt:
        return entity.updatedAt;
      default:
        return null;
    }
  }

  @override
  dynamic getLabelValue(ModelUserInfluencerLink entity, String fieldName) {
    if (fieldName == 'user_role') {
      return entity.resolvedLabels['user_role_label'];
    }
    if (fieldName == 'influencer_route') {
      return entity.resolvedLabels['influencer_route_label'];
    }

    if (fieldName.endsWith('_id')) {
      final labelKey = '${fieldName}_label';
      return entity.resolvedLabels[labelKey];
    }
    return null;
  }

  @override
  DateTime? getTimestamp(
    ModelUserInfluencerLink entity,
    String timestampField,
  ) {
    if (timestampField == ModelUserInfluencerLinkFields.createdAt) {
      return entity.createdAt;
    }
    if (timestampField == ModelUserInfluencerLinkFields.updatedAt) {
      return entity.updatedAt;
    }
    return null;
  }

  /// Returns the title to display in the UI (e.g., list tile)
  String getTitle(ModelUserInfluencerLink entity) {
    // Show "User Name -> Influencer Name" or fallback
    final userName = entity.resolvedLabels['user_id_label'] ?? entity.userId;
    final influencerName =
        entity.resolvedLabels['influencer_id_label'] ?? entity.influencerId;
    return '$userName -> $influencerName';
  }

  /// Returns the subtitle to display in the UI
  String? getSubtitle(ModelUserInfluencerLink entity) {
    return 'Created: ${entity.createdAt?.toString().split(' ')[0] ?? 'N/A'}';
  }

  /// Returns the leading widget (avatar/icon)
  String? getLeading(ModelUserInfluencerLink entity) {
    return null; // Default icon will be used
  }
}

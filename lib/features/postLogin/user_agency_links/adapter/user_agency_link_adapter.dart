import '../../../../core/services/entity_service.dart';
import '../model/user_agency_link_model.dart';

class UserAgencyLinkAdapter extends EntityAdapter<ModelUserAgencyLink> {
  @override
  String getId(ModelUserAgencyLink entity, String idField) => entity.linkId;

  @override
  dynamic getFieldValue(ModelUserAgencyLink entity, String fieldName) {
    switch (fieldName) {
      case ModelUserAgencyLinkFields.linkId:
        return entity.linkId;
      case ModelUserAgencyLinkFields.userId:
        return entity.userId;
      case ModelUserAgencyLinkFields.agencyId:
        return entity.agencyId;
      case ModelUserAgencyLinkFields.createdAt:
        return entity.createdAt;
      case ModelUserAgencyLinkFields.updatedAt:
        return entity.updatedAt;
      default:
        return null;
    }
  }

  @override
  dynamic getLabelValue(ModelUserAgencyLink entity, String fieldName) {
    if (fieldName == 'user_role') {
      return entity.resolvedLabels['user_role_label'];
    }
    if (fieldName == 'agency_route') {
      return entity.resolvedLabels['agency_route_label'];
    }

    if (fieldName.endsWith('_id')) {
      final labelKey = '${fieldName}_label';
      return entity.resolvedLabels[labelKey];
    }
    return null;
  }

  @override
  DateTime? getTimestamp(ModelUserAgencyLink entity, String timestampField) {
    if (timestampField == ModelUserAgencyLinkFields.createdAt) {
      return entity.createdAt;
    }
    if (timestampField == ModelUserAgencyLinkFields.updatedAt) {
      return entity.updatedAt;
    }
    return null;
  }

  /// Returns the title to display in the UI (e.g., list tile)
  String getTitle(ModelUserAgencyLink entity) {
    // Show "User Name -> Agency Name" or fallback
    final userName = entity.resolvedLabels['user_id_label'] ?? entity.userId;
    final agencyName =
        entity.resolvedLabels['agency_id_label'] ?? entity.agencyId;
    return '$userName -> $agencyName';
  }

  /// Returns the subtitle to display in the UI
  String? getSubtitle(ModelUserAgencyLink entity) {
    return 'Created: ${entity.createdAt?.toString().split(' ')[0] ?? 'N/A'}';
  }

  /// Returns the leading widget (avatar/icon)
  String? getLeading(ModelUserAgencyLink entity) {
    return null; // Default icon will be used
  }
}

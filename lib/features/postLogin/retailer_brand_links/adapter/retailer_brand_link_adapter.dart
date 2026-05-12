import '../../../../core/services/entity_service.dart';
import '../model/retailer_brand_link_model.dart';

class RetailerBrandLinkAdapter extends EntityAdapter<ModelRetailerBrandLink> {
  @override
  String getId(ModelRetailerBrandLink entity, String idField) => entity.linkId;

  @override
  dynamic getFieldValue(ModelRetailerBrandLink entity, String fieldName) {
    switch (fieldName) {
      case ModelRetailerBrandLinkFields.linkId:
        return entity.linkId;
      case ModelRetailerBrandLinkFields.userId:
        return entity.userId;
      case ModelRetailerBrandLinkFields.brandId:
        return entity.brandId;
      case ModelRetailerBrandLinkFields.createdAt:
        return entity.createdAt;
      case ModelRetailerBrandLinkFields.updatedAt:
        return entity.updatedAt;
      default:
        return null;
    }
  }

  @override
  dynamic getLabelValue(ModelRetailerBrandLink entity, String fieldName) {
    if (fieldName == 'user_role') {
      return entity.resolvedLabels['user_role_label'];
    }
    if (fieldName == 'brand_route') {
      return entity.resolvedLabels['brand_route_label'];
    }

    if (fieldName.endsWith('_id')) {
      final labelKey = '${fieldName}_label';
      return entity.resolvedLabels[labelKey];
    }
    return null;
  }

  @override
  DateTime? getTimestamp(ModelRetailerBrandLink entity, String timestampField) {
    if (timestampField == ModelRetailerBrandLinkFields.createdAt) {
      return entity.createdAt;
    }
    if (timestampField == ModelRetailerBrandLinkFields.updatedAt) {
      return entity.updatedAt;
    }
    return null;
  }

  /// Returns the title to display in the UI (e.g., list tile)
  String getTitle(ModelRetailerBrandLink entity) {
    // Show "User Name -> Brand Name" or fallback
    final userName = entity.resolvedLabels['user_id_label'] ?? entity.userId;
    final brandName = entity.resolvedLabels['brand_id_label'] ?? entity.brandId;
    return '$userName -> $brandName';
  }

  /// Returns the subtitle to display in the UI
  String? getSubtitle(ModelRetailerBrandLink entity) {
    return 'Created: ${entity.createdAt?.toString().split(' ')[0] ?? 'N/A'}';
  }

  /// Returns the leading widget (avatar/icon)
  String? getLeading(ModelRetailerBrandLink entity) {
    return null; // Default icon will be used
  }
}

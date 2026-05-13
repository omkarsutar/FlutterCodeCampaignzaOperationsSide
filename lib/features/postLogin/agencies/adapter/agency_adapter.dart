import '../../../../core/services/entity_service.dart';
import '../model/agency_model.dart';

class RouteAdapter implements EntityAdapter<ModelAgency> {
  @override
  dynamic getFieldValue(ModelAgency entity, String fieldName) {
    switch (fieldName) {
      case ModelAgencyFields.agencyId:
        return entity.agencyId;
      case ModelAgencyFields.agencyName:
        return entity.agencyName;
      case ModelAgencyFields.agencyNote:
        return entity.agencyNote;
      case ModelAgencyFields.isActive:
        return entity.isActive;
      case ModelAgencyFields.createdAt:
        return entity.createdAt;
      case ModelAgencyFields.updatedAt:
        return entity.updatedAt;
      default:
        return null;
    }
  }

  @override
  dynamic getLabelValue(ModelAgency entity, String fieldName) {
    switch (fieldName) {
      case ModelAgencyFields.isActive:
        return entity.isActive ? 'Active' : 'Inactive';
      case ModelAgencyFields.createdAt:
        return _formatDate(entity.createdAt);
      case ModelAgencyFields.updatedAt:
        return _formatDate(entity.updatedAt);
      default:
        return null;
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  dynamic getId(ModelAgency entity, String idField) => entity.agencyId;

  @override
  dynamic getTimestamp(ModelAgency entity, String timestampField) {
    return entity.createdAt;
  }
}

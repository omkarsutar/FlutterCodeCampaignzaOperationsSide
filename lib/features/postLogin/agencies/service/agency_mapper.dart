import '../../../../core/services/entity_service.dart';
import '../model/agency_model.dart';

class AgencyMapper implements EntityMapper<ModelAgency> {
  @override
  ModelAgency fromMap(Map<String, dynamic> map) {
    return ModelAgency.fromMap(map);
  }

  @override
  Map<String, dynamic> toMap(ModelAgency entity) {
    return entity.toMap();
  }
}

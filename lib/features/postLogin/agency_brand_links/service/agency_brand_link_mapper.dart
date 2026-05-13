import '../../../../core/services/entity_service.dart';
import '../model/agency_brand_link_model.dart';

class AgencyBrandLinkMapper implements EntityMapper<ModelAgencyBrandLink> {
  @override
  ModelAgencyBrandLink fromMap(Map<String, dynamic> map) {
    return ModelAgencyBrandLink.fromMap(map);
  }

  @override
  Map<String, dynamic> toMap(ModelAgencyBrandLink entity) {
    return entity.toMap();
  }
}

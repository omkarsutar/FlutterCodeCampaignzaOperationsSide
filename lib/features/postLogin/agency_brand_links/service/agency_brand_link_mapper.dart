import '../../../../core/services/entity_service.dart';
import '../model/route_brand_link_model.dart';

class RouteBrandLinkMapper implements EntityMapper<ModelRouteBrandLink> {
  @override
  ModelRouteBrandLink fromMap(Map<String, dynamic> map) {
    return ModelRouteBrandLink.fromMap(map);
  }

  @override
  Map<String, dynamic> toMap(ModelRouteBrandLink entity) {
    return entity.toMap();
  }
}

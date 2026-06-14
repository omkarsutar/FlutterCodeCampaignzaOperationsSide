import '../../../../core/services/entity_service.dart';
import '../model/referrer_link_model.dart';

class ReferrerLinkMapper implements EntityMapper<ModelReferrerLink> {
  @override
  ModelReferrerLink fromMap(Map<String, dynamic> map) {
    return ModelReferrerLink.fromMap(map);
  }

  @override
  Map<String, dynamic> toMap(ModelReferrerLink entity) {
    return entity.toMap();
  }
}

import '../../../../core/services/entity_service.dart';
import '../model/campaign_model.dart';

class CampaignMapper implements EntityMapper<ModelCampaign> {
  @override
  ModelCampaign fromMap(Map<String, dynamic> map) {
    return ModelCampaign.fromMap(map);
  }

  @override
  Map<String, dynamic> toMap(ModelCampaign entity) {
    return entity.toMap();
  }
}

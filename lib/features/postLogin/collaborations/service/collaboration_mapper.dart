import '../../../../core/services/entity_service.dart';
import '../model/collaboration_model.dart';

class CollaborationMapper implements EntityMapper<ModelCollaboration> {
  @override
  ModelCollaboration fromMap(Map<String, dynamic> map) {
    return ModelCollaboration.fromMap(map);
  }

  @override
  Map<String, dynamic> toMap(ModelCollaboration entity) {
    return entity.toMap();
  }
}

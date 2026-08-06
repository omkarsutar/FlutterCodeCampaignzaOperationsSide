import '../../../../core/services/entity_service.dart';
import '../model/brand_data_model.dart';

class BrandDataMapper implements EntityMapper<ModelBrandData> {
  @override
  ModelBrandData fromMap(Map<String, dynamic> map) {
    return ModelBrandData.fromMap(map);
  }

  @override
  Map<String, dynamic> toMap(ModelBrandData entity) {
    return entity.toMap();
  }
}

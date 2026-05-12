import '../../../../core/services/entity_service.dart';
import '../model/brand_model.dart';

class BrandMapper implements EntityMapper<ModelBrand> {
  @override
  ModelBrand fromMap(Map<String, dynamic> map) {
    return ModelBrand.fromMap(map);
  }

  @override
  Map<String, dynamic> toMap(ModelBrand entity) {
    return entity.toMap();
  }
}

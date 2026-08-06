import 'package:flutter_supabase_order_app_mobile/core/services/core_services_barrel.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../model/brand_data_model.dart';

class BrandDataServiceImpl extends SupabaseEntityService<ModelBrandData> {
  final EntityMapper<ModelBrandData> _mapper;

  BrandDataServiceImpl(
    this._mapper,
    SupabaseClient client,
    LoggerService logger,
  ) : super(client, logger);

  @override
  EntityMapper<ModelBrandData> get mapper => _mapper;

  @override
  String get entityTypeName => 'ModelBrandData';

  @override
  String get tableName => ModelBrandDataFields.table;

  @override
  String get idColumn => ModelBrandDataFields.id;

  @override
  String get createdAt => ModelBrandDataFields.createdAt;
}

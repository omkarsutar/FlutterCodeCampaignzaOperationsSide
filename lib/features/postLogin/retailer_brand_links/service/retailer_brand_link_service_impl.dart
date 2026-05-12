import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/config/field_config.dart';
import '../../../../core/services/entity_service.dart';
import '../../../../core/services/logger_service.dart';
import '../../brands/brand_barrel.dart';
import '../../users/user_barrel.dart';
import '../model/retailer_brand_link_model.dart';

class RetailerBrandLinkServiceImpl
    extends ForeignKeyAwareService<ModelRetailerBrandLink> {
  final EntityMapper<ModelRetailerBrandLink> _mapper;

  RetailerBrandLinkServiceImpl(
    this._mapper,
    SupabaseClient client,
    LoggerService logger,
  ) : super(client, logger);

  @override
  EntityMapper<ModelRetailerBrandLink> get mapper => _mapper;

  @override
  String get tableName => ModelRetailerBrandLinkFields.table;

  @override
  String? get viewName =>
      ModelRetailerBrandLinkFields.tableViewWithForeignKeyLabels;

  @override
  String get idColumn => ModelRetailerBrandLinkFields.linkId;

  @override
  String get createdAt => ModelRetailerBrandLinkFields.createdAt;

  @override
  Map<String, ForeignKeyConfig> get foreignKeys => {
    ModelRetailerBrandLinkFields.userId: ForeignKeyConfig(
      table: ModelUserFields.table,
      idColumn: ModelUserFields.userId,
      labelColumn: ModelUserFields.fullName,
    ),
    ModelRetailerBrandLinkFields.brandId: ForeignKeyConfig(
      table: ModelBrandFields.table,
      idColumn: ModelBrandFields.brandId,
      labelColumn: ModelBrandFields.brandName,
    ),
  };
}

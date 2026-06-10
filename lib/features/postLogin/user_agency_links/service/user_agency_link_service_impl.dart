import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/config/field_config.dart';
import '../../../../core/services/entity_service.dart';
import '../../../../core/services/logger_service.dart';
import '../../agencies/agency_barrel.dart';
import '../../users/user_barrel.dart';
import '../model/user_agency_link_model.dart';

class UserAgencyLinkServiceImpl
    extends ForeignKeyAwareService<ModelUserAgencyLink> {
  final EntityMapper<ModelUserAgencyLink> _mapper;

  UserAgencyLinkServiceImpl(
    this._mapper,
    SupabaseClient client,
    LoggerService logger,
  ) : super(client, logger);

  @override
  EntityMapper<ModelUserAgencyLink> get mapper => _mapper;

  @override
  String get tableName => ModelUserAgencyLinkFields.table;

  @override
  String? get viewName =>
      ModelUserAgencyLinkFields.tableViewWithForeignKeyLabels;

  @override
  String get idColumn => ModelUserAgencyLinkFields.linkId;

  @override
  String get createdAt => ModelUserAgencyLinkFields.createdAt;

  @override
  Map<String, ForeignKeyConfig> get foreignKeys => {
    ModelUserAgencyLinkFields.userId: ForeignKeyConfig(
      table: ModelUserFields.table,
      idColumn: ModelUserFields.userId,
      labelColumn: ModelUserFields.fullName,
    ),
    ModelUserAgencyLinkFields.agencyId: ForeignKeyConfig(
      table: ModelAgencyFields.table,
      idColumn: ModelAgencyFields.agencyId,
      labelColumn: ModelAgencyFields.agencyName,
    ),
  };

  @override
  Future<ModelUserAgencyLink> create(ModelUserAgencyLink entity) async {
    try {
      logger.info(
        'Upserting $ModelUserAgencyLink in $tableName for user ${entity.userId}',
      );
      final payload = mapper.toMap(entity);

      // Remove linkId if it's empty to let database handle it
      if (entity.linkId.isEmpty) {
        payload.remove(ModelUserAgencyLinkFields.linkId);
      }

      // Use upsert on user_id to ensure only one agency per user
      final response = await client
          .from(tableName)
          .upsert(payload, onConflict: ModelUserAgencyLinkFields.userId)
          .select()
          .single();

      final resolved = await resolveForeignLabelsForSingle(response);
      return mapper.fromMap(resolved);
    } catch (e, st) {
      logger.error('Failed to upsert $ModelUserAgencyLink', st);
      rethrow;
    }
  }
}

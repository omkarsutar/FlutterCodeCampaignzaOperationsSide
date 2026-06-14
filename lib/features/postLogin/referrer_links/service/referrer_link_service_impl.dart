import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/entity_service.dart';
import '../../../../core/services/logger_service.dart';
import '../../../../core/services/supabase_entity_service.dart';
import '../model/referrer_link_model.dart';

class ReferrerLinkServiceImpl extends SupabaseEntityService<ModelReferrerLink> {
  final EntityMapper<ModelReferrerLink> _mapper;

  ReferrerLinkServiceImpl(
    this._mapper,
    SupabaseClient client,
    LoggerService logger,
  ) : super(client, logger);

  @override
  EntityMapper<ModelReferrerLink> get mapper => _mapper;

  @override
  String get entityTypeName => 'ModelReferrerLink';

  @override
  String get tableName => ModelReferrerLinkFields.table;

  @override
  String get idColumn => ModelReferrerLinkFields.moduleId;
  @override
  String get createdAt => ModelReferrerLinkFields.createdAt;

  Future<List<Map<String, dynamic>>> getAllEntities() async {
    final modules = await fetchAll();
    return modules.map((m) => mapper.toMap(m)).toList();
  }
}

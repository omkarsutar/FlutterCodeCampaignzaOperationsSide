import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/core_services_barrel.dart';
import '../model/agency_model.dart';

class AgencyServiceImpl extends SupabaseEntityService<ModelAgency> {
  final EntityMapper<ModelAgency> _mapper;

  AgencyServiceImpl(this._mapper, SupabaseClient client, LoggerService logger)
    : super(client, logger);

  @override
  EntityMapper<ModelAgency> get mapper => _mapper;

  @override
  String get entityTypeName => 'ModelAgency';

  @override
  String get tableName => ModelAgencyFields.table;

  @override
  String get idColumn => ModelAgencyFields.agencyId;
  @override
  String get createdAt => ModelAgencyFields.createdAt;

  Future<List<Map<String, dynamic>>> fetchAgencies() async {
    final response = await client
        .from(tableName)
        .select('$idColumn, ${ModelAgencyFields.agencyName}')
        .order(sortField ?? createdAt, ascending: sortAscending);

    return List<Map<String, dynamic>>.from(response);
  }

  Future<String?> fetchAgencyName(String agencyId) async {
    try {
      final response = await client
          .from(tableName)
          .select(ModelAgencyFields.agencyName)
          .eq(idColumn, agencyId)
          .single();
      return response[ModelAgencyFields.agencyName] as String?;
    } catch (_) {
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getAllEntities() async {
    final agencies = await fetchAllImpl("AgencyServiceImpl");
    return agencies.map((r) => mapper.toMap(r)).toList();
  }
}

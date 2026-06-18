import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/services/entity_service.dart';
import '../../../../core/services/supabase_entity_service.dart';
import '../../../../core/services/logger_service.dart';
import '../model/influencer_model.dart';

class InfluencerServiceImpl extends SupabaseEntityService<ModelInfluencer> {
  final EntityMapper<ModelInfluencer> _mapper;

  InfluencerServiceImpl(this._mapper, SupabaseClient client, LoggerService logger)
    : super(client, logger);

  @override
  EntityMapper<ModelInfluencer> get mapper => _mapper;

  @override
  String get entityTypeName => 'ModelInfluencer';

  @override
  String get tableName => ModelInfluencerFields.table;

  @override
  String get idColumn => ModelInfluencerFields.influencerId;
  @override
  String get createdAt => ModelInfluencerFields.createdAt;

  // --- Convenience methods ---

  /// Get raw maps instead of typed entities
  Future<List<Map<String, dynamic>>> getAllEntities() async {
    final influencers = await fetchAll(); // uses LoggingEntityService wrapper
    return influencers.map((i) => mapper.toMap(i)).toList();
  }

  /// Override streamEntitiesImpl to use the view for better performance
  @override
  Stream<List<ModelInfluencer>> streamEntitiesImpl() {
    final controller = StreamController<List<ModelInfluencer>>();
    RealtimeChannel? channel;

    Future<void> fetch() async {
      try {
        final List<dynamic> data = await client
            .from(ModelInfluencerFields.tableViewWithForeignKeyLabels)
            .select()
            .order(sortField ?? createdAt, ascending: sortAscending);

        if (!controller.isClosed) {
          controller.add(data.map((e) => mapper.fromMap(e)).toList());
        }
      } catch (e) {
        if (!controller.isClosed) controller.addError(e);
      }
    }

    void startSubscription() {
      fetch();
      channel = client.channel('public:$tableName')
        ..onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: tableName,
          callback: (_) => fetch(),
        )
        ..subscribe();
    }

    controller.onListen = startSubscription;
    controller.onCancel = () => channel?.unsubscribe();

    return controller.stream;
  }

  /// Override fetchAll to use the view for better performance
  @override
  Future<List<ModelInfluencer>> fetchAll() async {
    final response = await client
        .from(ModelInfluencerFields.tableViewWithForeignKeyLabels)
        .select()
        .order(sortField ?? createdAt, ascending: sortAscending);
    return (response as List).map((e) => mapper.fromMap(e)).toList();
  }

  // --- Override only the custom createImpl ---

  @override
  Future<ModelInfluencer> createImpl(ModelInfluencer entity) async {
    final inserted = await client
        .from(tableName)
        .insert(stripSupabaseAuditFields(mapper.toMap(entity)))
        .select()
        .single();
    return mapper.fromMap(inserted);
  }
}

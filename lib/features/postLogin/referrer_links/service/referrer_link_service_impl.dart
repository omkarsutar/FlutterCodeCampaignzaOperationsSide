import 'dart:async';
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
  String get idColumn => ModelReferrerLinkFields.referrerLinkId;

  @override
  String get createdAt => ModelReferrerLinkFields.createdAt;

  Future<List<Map<String, dynamic>>> getAllEntities() async {
    final modules = await fetchAll();
    return modules.map((m) => mapper.toMap(m)).toList();
  }

  /// Streams referrer links for a campaign (where collaboration_id is null)
  Stream<List<ModelReferrerLink>> streamLinksForCampaign(String campaignId) {
    final controller = StreamController<List<ModelReferrerLink>>();
    RealtimeChannel? channel;

    Future<void> fetch() async {
      try {
        final List<dynamic> data = await client
            .from(tableName)
            .select()
            .eq('campaign_id', campaignId)
            .isFilter('collaboration_id', null)
            .order(createdAt, ascending: false);

        if (!controller.isClosed) {
          controller.add(data.map((e) => mapper.fromMap(e)).toList());
        }
      } catch (e) {
        if (!controller.isClosed) controller.addError(e);
      }
    }

    void startSubscription() {
      fetch();
      channel = client.channel('public:$tableName:campaign:$campaignId')
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

  /// Streams referrer links for a specific collaboration
  Stream<List<ModelReferrerLink>> streamLinksForCollaboration(String collaborationId) {
    final controller = StreamController<List<ModelReferrerLink>>();
    RealtimeChannel? channel;

    Future<void> fetch() async {
      try {
        final List<dynamic> data = await client
            .from(tableName)
            .select()
            .eq('collaboration_id', collaborationId)
            .order(createdAt, ascending: false);

        if (!controller.isClosed) {
          controller.add(data.map((e) => mapper.fromMap(e)).toList());
        }
      } catch (e) {
        if (!controller.isClosed) controller.addError(e);
      }
    }

    void startSubscription() {
      fetch();
      channel = client.channel('public:$tableName:collab:$collaborationId')
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
}

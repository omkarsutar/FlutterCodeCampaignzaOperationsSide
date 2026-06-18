import 'dart:async';
import 'package:flutter_supabase_order_app_mobile/features/postLogin/campaigns/campaign_barrel.dart';
import 'package:flutter_supabase_order_app_mobile/features/postLogin/users/user_barrel.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/config/field_config.dart';
import '../../../../core/services/logger_service.dart';
import '../../../../core/services/entity_service.dart';
import '../model/collaboration_model.dart';

abstract class PoFilteredEntityService<T> {
  Stream<List<T>> streamItemsByPo(String poId);
  Future<List<T>> fetchEntitiesByPo(String poId);
}

class CollaborationServiceImpl
    extends ForeignKeyAwareService<ModelCollaboration>
    implements PoFilteredEntityService<ModelCollaboration> {
  final EntityMapper<ModelCollaboration> _mapper;

  CollaborationServiceImpl(
    this._mapper,
    SupabaseClient client,
    LoggerService logger,
  ) : super(client, logger);

  @override
  EntityMapper<ModelCollaboration> get mapper => _mapper;

  @override
  String get tableName => ModelCollaborationFields.table;

  @override
  String get idColumn => ModelCollaborationFields.collaborationId;
  @override
  String get createdAt => ModelCollaborationFields.createdAt;

  @override
  Map<String, ForeignKeyConfig> get foreignKeys => {
    ModelCollaborationFields.campaignId: ForeignKeyConfig(
      table: ModelCampaignFields.table,
      idColumn: ModelCampaignFields.campaignId,
      labelColumn: ModelCampaignFields.campaignId,
    ),
    ModelCollaborationFields.createdBy: ForeignKeyConfig(
      table: ModelUserFields.table,
      idColumn: ModelUserFields.userId,
      labelColumn: ModelUserFields.fullName,
    ),
    ModelCollaborationFields.updatedBy: ForeignKeyConfig(
      table: ModelUserFields.table,
      idColumn: ModelUserFields.userId,
      labelColumn: ModelUserFields.fullName,
    ),
  };

  @override
  Stream<List<ModelCollaboration>> streamEntities() {
    final controller = StreamController<List<ModelCollaboration>>();
    RealtimeChannel? channel;

    Future<void> fetch() async {
      try {
        final List<dynamic> data = await client
            .from(ModelCollaborationFields.tableViewWithForeignKeyLabels)
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
      channel = client.channel('public:collaborations_all')
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

  /// Alias for streamEntities() for consistent naming
  Stream<List<ModelCollaboration>> stream() => streamEntities();

  @override
  Future<List<ModelCollaboration>> fetchAll() async {
    final List<dynamic> data = await client
        .from(ModelCollaborationFields.tableViewWithForeignKeyLabels)
        .select()
        .order(sortField ?? createdAt, ascending: sortAscending);

    return data.map((e) => mapper.fromMap(e)).toList();
  }

  @override
  Future<ModelCollaboration?> fetchById(String id) async {
    try {
      final rawTable = await client
          .from(tableName)
          .select('*')
          .eq(idColumn, id)
          .maybeSingle();

      if (rawTable == null) return null;

      final rawView = await client
          .from(ModelCollaborationFields.tableViewWithForeignKeyLabels)
          .select()
          .eq(idColumn, id)
          .maybeSingle();

      final combined = Map<String, dynamic>.from(rawTable);
      if (rawView != null) {
        for (final entry in rawView.entries) {
          if (entry.key.endsWith('_label')) {
            combined[entry.key] = entry.value;
          }
        }
      }
      return mapper.fromMap(combined);
    } catch (e) {
      rethrow;
    }
  }

  // --- Custom helpers ---

  /// Fetch raw items for a given campaign (without mapping)
  Future<List<Map<String, dynamic>>> fetchItemsForPo(String poId) async {
    if (poId.isEmpty) {
      throw Exception('Campaign ID not provided');
    }

    final items = await client
        .from(tableName)
        .select('*')
        .eq(ModelCollaborationFields.campaignId, poId);

    return List<Map<String, dynamic>>.from(items);
  }

  @override
  Stream<List<ModelCollaboration>> streamItemsByPo(String poId) {
    final controller = StreamController<List<ModelCollaboration>>();
    RealtimeChannel? channel;

    Future<void> fetch() async {
      try {
        final List<dynamic> data = await client
            .from(ModelCollaborationFields.tableViewWithForeignKeyLabels)
            .select()
            .eq(ModelCollaborationFields.campaignId, poId)
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
      channel = client.channel('public:$tableName:$poId')
        ..onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: tableName,
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: ModelCollaborationFields.campaignId,
            value: poId,
          ),
          callback: (_) => fetch(),
        )
        ..subscribe();
    }

    controller.onListen = startSubscription;
    controller.onCancel = () => channel?.unsubscribe();

    return controller.stream;
  }

  @override
  Future<List<ModelCollaboration>> fetchEntitiesByPo(String poId) async {
    final List<dynamic> result = await client
        .from(ModelCollaborationFields.tableViewWithForeignKeyLabels)
        .select()
        .eq(ModelCollaborationFields.campaignId, poId)
        .order(sortField ?? createdAt, ascending: sortAscending);

    return result.map((e) => mapper.fromMap(e)).toList();
  }

  /// Insert a Collaboration linked to a specific Campaign
  Future<ModelCollaboration> insertEntityForPo(
    ModelCollaboration entity,
    String selectedPoId,
  ) async {
    final data = stripSupabaseAuditFields(mapper.toMap(entity));
    data[ModelCollaborationFields.campaignId] = selectedPoId;

    final inserted = await client
        .from(tableName)
        .insert(data)
        .select()
        .single();

    return mapper.fromMap(inserted);
  }

  /// Delete all items for a specific campaign
  Future<void> deleteAllByPo(String poId) async {
    if (poId.isEmpty) throw Exception('Campaign ID not provided');
    await client
        .from(tableName)
        .delete()
        .eq(ModelCollaborationFields.campaignId, poId);
  }

  @override
  Future<ModelCollaboration> create(ModelCollaboration entity) async {
    return super.create(entity);
  }

  @override
  Future<ModelCollaboration> update(
    String id,
    ModelCollaboration entity,
  ) async {
    return super.update(id, entity);
  }

  /// Fetch purchase count for a promo code via Supabase RPC
  Future<int> fetchPurchaseCount(String promoCode) async {
    final result = await client.rpc(
      'get_purchase_count_by_promo',
      params: {'p_promo_code': promoCode},
    );
    return (result as int?) ?? 0;
  }

  /// Fetch install count for a referrer_raw string via Supabase RPC
  Future<int> fetchInstallCount(String referrerRaw) async {
    final result = await client.rpc(
      'get_install_count_by_referrer',
      params: {'p_referrer_raw': referrerRaw},
    );
    return (result as int?) ?? 0;
  }
}

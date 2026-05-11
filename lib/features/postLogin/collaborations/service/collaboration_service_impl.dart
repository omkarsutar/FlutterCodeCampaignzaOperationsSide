import 'dart:async';
import 'package:flutter_supabase_order_app_mobile/features/postLogin/purchase_orders/purchase_order_barrel.dart';
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
    ModelCollaborationFields.poId: ForeignKeyConfig(
      table: ModelPurchaseOrderFields.table,
      idColumn: ModelPurchaseOrderFields.poId,
      labelColumn: ModelPurchaseOrderFields.poId,
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
      final raw = await client
          .from(ModelCollaborationFields.tableViewWithForeignKeyLabels)
          .select()
          .eq(idColumn, id)
          .maybeSingle();

      if (raw == null) return null;
      return mapper.fromMap(raw);
    } catch (e) {
      rethrow;
    }
  }

  // --- Custom helpers ---

  /// Fetch raw items for a given purchase order (without mapping)
  Future<List<Map<String, dynamic>>> fetchItemsForPo(String poId) async {
    if (poId.isEmpty) {
      throw Exception('PO ID not provided');
    }

    final items = await client
        .from(tableName)
        .select('*')
        .eq(ModelCollaborationFields.poId, poId);

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
            .eq(ModelCollaborationFields.poId, poId)
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
            column: ModelCollaborationFields.poId,
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
        .eq(ModelCollaborationFields.poId, poId)
        .order(sortField ?? createdAt, ascending: sortAscending);

    return result.map((e) => mapper.fromMap(e)).toList();
  }

  /// Calculate profit for a Collaboration
  double? calculateProfit(Map<String, dynamic> data) {
    final sellRate = data[ModelCollaborationFields.itemSellRate];
    final price = data[ModelCollaborationFields.itemPrice];
    if (sellRate == null || price == null) return null;
    return (sellRate as num).toDouble() - (price as num).toDouble();
  }

  /// Insert a Collaboration linked to a specific PO
  Future<ModelCollaboration> insertEntityForPo(
    ModelCollaboration entity,
    String selectedPoId,
  ) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) throw Exception('No signed-in user found');

    final data = mapper.toMap(entity);
    data[ModelCollaborationFields.poId] = selectedPoId;
    data[ModelCollaborationFields.createdBy] = user.id;
    data[ModelCollaborationFields.updatedBy] = user.id;
    data[ModelCollaborationFields.profitToShop] = calculateProfit(data);

    final inserted = await client
        .from(tableName)
        .insert(data)
        .select()
        .single();

    return mapper.fromMap(inserted);
  }

  /// Delete all items for a specific purchase order
  Future<void> deleteAllByPo(String poId) async {
    if (poId.isEmpty) throw Exception('PO ID not provided');
    await client
        .from(tableName)
        .delete()
        .eq(ModelCollaborationFields.poId, poId);
  }
}

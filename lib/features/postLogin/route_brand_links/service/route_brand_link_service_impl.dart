import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_supabase_order_app_mobile/features/postLogin/routes/route_barrel.dart';
import 'package:flutter_supabase_order_app_mobile/features/postLogin/brands/brand_barrel.dart';

import '../../../../core/config/field_config.dart';
import '../../../../core/services/core_services_barrel.dart';
import '../../../../core/config/module_config.dart';
import '../model/route_brand_link_model.dart';

abstract class RouteFilteredEntityService<T> {
  Stream<List<T>> streamEntitiesByRoute(String routeId);
}

class RouteBrandLinkServiceImpl
    extends ForeignKeyAwareService<ModelRouteBrandLink>
    implements RouteFilteredEntityService<ModelRouteBrandLink> {
  final EntityMapper<ModelRouteBrandLink> _mapper;

  RouteBrandLinkServiceImpl(
    this._mapper,
    SupabaseClient client,
    LoggerService logger, {
    SortingConfig? initialSorting,
  }) : super(client, logger) {
    if (initialSorting != null) {
      sortField = initialSorting.field;
      sortAscending = initialSorting.sortAscending;
    } else {
      /* sortField = ModelRouteBrandLinkFields.visitOrder;
      sortAscending = true; */
    }
  }

  @override
  EntityMapper<ModelRouteBrandLink> get mapper => _mapper;

  @override
  String get tableName => ModelRouteBrandLinkFields.table;

  @override
  String get idColumn => ModelRouteBrandLinkFields.linkId;

  @override
  String get createdAt => ModelRouteBrandLinkFields.createdAt;

  @override
  Map<String, ForeignKeyConfig> get foreignKeys => {
    ModelRouteBrandLinkFields.routeId: ForeignKeyConfig(
      table: ModelRouteFields.table,
      idColumn: ModelRouteFields.routeId,
      labelColumn: ModelRouteFields.routeName,
    ),
    ModelRouteBrandLinkFields.brandId: ForeignKeyConfig(
      table: ModelBrandFields.table,
      idColumn: ModelBrandFields.brandId,
      labelColumn: ModelBrandFields.brandName,
      // Add this to use the optimized dropdown method
      fetchDropdownItems: (service) =>
          (service as BrandServiceImpl).getBrandsForDropdown(),
    ),
  };

  @override
  Future<List<ModelRouteBrandLink>> fetchAll() async {
    final List<dynamic> data = await client
        .from(ModelRouteBrandLinkFields.tableViewWithForeignKeyLabels)
        .select()
        .order(sortField ?? createdAt, ascending: sortAscending);

    return data.map((e) => mapper.fromMap(e)).toList();
  }

  @override
  Future<ModelRouteBrandLink?> fetchById(String id) async {
    try {
      // Use the view that includes foreign key labels
      final raw = await client
          .from(ModelRouteBrandLinkFields.tableViewWithForeignKeyLabels)
          .select()
          .eq(idColumn, id)
          .maybeSingle();

      if (raw == null) {
        return null;
      }

      // The view already contains the labels, so we don't need resolveForeignLabelsForSingle
      return mapper.fromMap(raw);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Stream<List<ModelRouteBrandLink>> streamEntities() {
    final controller = StreamController<List<ModelRouteBrandLink>>();
    RealtimeChannel? channel;

    Future<void> fetch() async {
      try {
        final List<dynamic> data = await client
            .from(ModelRouteBrandLinkFields.tableViewWithForeignKeyLabels)
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

  // --- Custom helper: stream links filtered by route ---
  @override
  Stream<List<ModelRouteBrandLink>> streamEntitiesByRoute(String routeId) {
    final controller = StreamController<List<ModelRouteBrandLink>>();
    RealtimeChannel? channel;
    Timer? debounceTimer;

    Future<void> fetch() async {
      try {
        final List<dynamic> data = await client
            .from(ModelRouteBrandLinkFields.tableViewWithForeignKeyLabels)
            .select()
            .eq(ModelRouteBrandLinkFields.routeId, routeId)
            .order(sortField ?? createdAt, ascending: sortAscending);

        if (!controller.isClosed) {
          controller.add(data.map((e) => mapper.fromMap(e)).toList());
        }
      } catch (e) {
        if (!controller.isClosed) controller.addError(e);
      }
    }

    void debouncedFetch() {
      debounceTimer?.cancel();
      debounceTimer = Timer(const Duration(milliseconds: 500), () {
        fetch();
      });
    }

    void startSubscription() {
      fetch();
      channel = client.channel('public:$tableName')
        ..onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: tableName,
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: ModelRouteBrandLinkFields.routeId,
            value: routeId,
          ),
          callback: (_) => debouncedFetch(),
        )
        ..subscribe();
    }

    controller.onListen = startSubscription;
    controller.onCancel = () => channel?.unsubscribe();

    return controller.stream;
  }

  /* /// Fetches route brand links using the 'view_route_brand_links' View
  Future<List<ModelRouteBrandLink>> fetchByRouteId(String routeId) async {
    // It is a View, so we query it like a table
    final List<dynamic> data = await client
        .from(ModelRouteBrandLinkFields.tableViewWithForeignKeyLabels)
        .select()
        .eq(ModelRouteBrandLinkFields.routeId, routeId)
        .order(ModelRouteBrandLinkFields.visitOrder, ascending: true);

    return data.map((e) => mapper.fromMap(e)).toList();
  } */

  /// Reorders route brand links using server-side function
  /// Returns the updated list of links for the route
  Future<void> reorderRouteBrandLink(String linkId, int newPosition) async {
    await client.rpc(
      'reorder_route_brand_links',
      params: {'p_link_id': linkId, 'p_new_position': newPosition},
    );
  }
}

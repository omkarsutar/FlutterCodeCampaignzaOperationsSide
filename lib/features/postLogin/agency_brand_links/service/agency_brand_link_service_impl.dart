import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
import 'package:flutter_supabase_order_app_mobile/features/postLogin/agencies/agency_barrel.dart';
import 'package:flutter_supabase_order_app_mobile/features/postLogin/brands/brand_barrel.dart';

import '../../../../core/config/field_config.dart';
import '../../../../core/services/core_services_barrel.dart';
import '../../../../core/config/module_config.dart';
import '../model/agency_brand_link_model.dart';

abstract class AgencyFilteredEntityService<T> {
  Stream<List<T>> streamEntitiesByAgency(String agencyId);
}

class AgencyBrandLinkServiceImpl
    extends ForeignKeyAwareService<ModelAgencyBrandLink>
    implements AgencyFilteredEntityService<ModelAgencyBrandLink> {
  final EntityMapper<ModelAgencyBrandLink> _mapper;

  AgencyBrandLinkServiceImpl(
    this._mapper,
    SupabaseClient client,
    LoggerService logger, {
    SortingConfig? initialSorting,
  }) : super(client, logger) {
    if (initialSorting != null) {
      sortField = initialSorting.field;
      sortAscending = initialSorting.sortAscending;
    }
  }

  @override
  EntityMapper<ModelAgencyBrandLink> get mapper => _mapper;

  @override
  String get tableName => ModelAgencyBrandLinkFields.table;

  @override
  String get idColumn => ModelAgencyBrandLinkFields.linkId;

  @override
  String get createdAt => ModelAgencyBrandLinkFields.createdAt;

  @override
  Map<String, ForeignKeyConfig> get foreignKeys => {
    ModelAgencyBrandLinkFields.agencyId: ForeignKeyConfig(
      table: ModelAgencyFields.table,
      idColumn: ModelAgencyFields.agencyId,
      labelColumn: ModelAgencyFields.agencyName,
    ),
    ModelAgencyBrandLinkFields.brandId: ForeignKeyConfig(
      table: ModelBrandFields.table,
      idColumn: ModelBrandFields.brandId,
      labelColumn: ModelBrandFields.brandName,
      fetchDropdownItems: (service) =>
          (service as BrandServiceImpl).getBrandsForDropdown(),
    ),
  };

  @override
  Future<List<ModelAgencyBrandLink>> fetchAll() async {
    final List<dynamic> data = await client
        .from(ModelAgencyBrandLinkFields.tableViewWithForeignKeyLabels)
        .select()
        .order(sortField ?? createdAt, ascending: sortAscending);

    return data.map((e) => mapper.fromMap(e)).toList();
  }

  @override
  Future<ModelAgencyBrandLink?> fetchById(String id) async {
    try {
      final raw = await client
          .from(ModelAgencyBrandLinkFields.tableViewWithForeignKeyLabels)
          .select()
          .eq(idColumn, id)
          .maybeSingle();

      if (raw == null) {
        return null;
      }

      return mapper.fromMap(raw);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Stream<List<ModelAgencyBrandLink>> streamEntities() {
    final controller = StreamController<List<ModelAgencyBrandLink>>();
    RealtimeChannel? channel;

    Future<void> fetch() async {
      try {
        final List<dynamic> data = await client
            .from(ModelAgencyBrandLinkFields.tableViewWithForeignKeyLabels)
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

  @override
  Stream<List<ModelAgencyBrandLink>> streamEntitiesByAgency(String agencyId) {
    final controller = StreamController<List<ModelAgencyBrandLink>>();
    RealtimeChannel? channel;
    Timer? debounceTimer;

    Future<void> fetch() async {
      try {
        final List<dynamic> data = await client
            .from(ModelAgencyBrandLinkFields.tableViewWithForeignKeyLabels)
            .select()
            .eq(ModelAgencyBrandLinkFields.agencyId, agencyId)
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
            column: ModelAgencyBrandLinkFields.agencyId,
            value: agencyId,
          ),
          callback: (_) => debouncedFetch(),
        )
        ..subscribe();
    }

    controller.onListen = startSubscription;
    controller.onCancel = () => channel?.unsubscribe();

    return controller.stream;
  }

  // Renamed from streamEntitiesByRoute for consistency with AgencyFilteredEntityService
  Stream<List<ModelAgencyBrandLink>> streamEntitiesByRoute(String agencyId) => streamEntitiesByAgency(agencyId);

  Future<void> reorderAgencyBrandLink(String linkId, int newPosition) async {
    await client.rpc(
      'reorder_agency_brand_links',
      params: {'p_link_id': linkId, 'p_new_position': newPosition},
    );
  }
}

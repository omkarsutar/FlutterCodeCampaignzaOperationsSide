import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:flutter_supabase_order_app_mobile/features/postLogin/collaborations/collaboration_barrel.dart';
import 'package:flutter_supabase_order_app_mobile/features/postLogin/campaigns/campaign_barrel.dart';
import 'package:flutter_supabase_order_app_mobile/features/postLogin/route_brand_links/route_brand_link_barrel.dart';
import 'package:flutter_supabase_order_app_mobile/features/postLogin/routes/route_barrel.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/core_services_barrel.dart';
import '../../../../core/config/field_config.dart';
import '../model/brand_model.dart';
import 'package:async/async.dart';

class BrandServiceImpl extends ForeignKeyAwareService<ModelBrand> {
  final EntityMapper<ModelBrand> _mapper;

  BrandServiceImpl(this._mapper, SupabaseClient client, LoggerService logger)
    : super(client, logger);

  @override
  EntityMapper<ModelBrand> get mapper => _mapper;

  @override
  String get tableName => ModelBrandFields.table;

  @override
  String get idColumn => ModelBrandFields.brandId;
  @override
  String get createdAt => ModelBrandFields.createdAt;

  @override
  Map<String, ForeignKeyConfig> get foreignKeys => {
    ModelBrandFields.brandsPrimaryRoute: ForeignKeyConfig(
      table: ModelRouteFields.table,
      idColumn: ModelRouteFields.routeId,
      labelColumn: ModelRouteFields.routeName,
    ),
  };

  // --- Custom helpers ---

  /// Fetch all brands linked to a user's preferred route
  Future<List<ModelBrand>> fetchAllBrandsForPreferredRoute(
    String? preferredRouteId,
  ) async {
    if (preferredRouteId == null || preferredRouteId.isEmpty) {
      throw Exception('Preferred route not set for user');
    }

    final linkData = await client
        .from(ModelRouteBrandLinkFields.table)
        .select(idColumn)
        .eq(ModelRouteBrandLinkFields.routeId, preferredRouteId);

    final brandIds = List<String>.from(linkData.map((e) => e[idColumn]));
    if (brandIds.isEmpty) return [];

    // Use view_brands instead of manual relational query
    final brands = await client
        .from(ModelBrandFields.tableViewWithForeignKeyLabels)
        .select('*')
        .inFilter(idColumn, brandIds);

    return List<Map<String, dynamic>>.from(
      brands,
    ).map((brand) => mapper.fromMap(brand)).toList();
  }

  // In your service:
  Stream<Map<String, List<ModelBrand>>> streamBrandsByCollaborationStatus(
    String preferredRouteId,
  ) async* {
    // Supabase live streams
    final poStream = client
        .from(ModelCampaignFields.table)
        .stream(primaryKey: [ModelCampaignFields.poId])
        .eq(ModelCampaignFields.poRouteId, preferredRouteId);

    final collaborationStream = client
        .from(ModelCollaborationFields.table)
        .stream(primaryKey: [ModelCollaborationFields.collaborationId]);

    // Merge both streams into one
    final merged = StreamGroup.merge([poStream, collaborationStream]);

    await for (final _ in merged) {
      final result = await fetchBrandsByCollaborationStatus(
        preferredRouteId: preferredRouteId,
      );
      yield result;
    }
  }

  /// Classify brands by campaign item status for today
  Future<Map<String, List<ModelBrand>>> fetchBrandsByCollaborationStatus({
    required String? preferredRouteId,
  }) async {
    if (preferredRouteId == null || preferredRouteId.isEmpty) {
      throw Exception('Preferred route not set for user');
    }

    // Step 1: Get brand_ids linked to preferred_route_id in route order
    final linkData = await client
        .from(ModelRouteBrandLinkFields.table)
        .select(ModelRouteBrandLinkFields.brandId)
        .eq(ModelRouteBrandLinkFields.routeId, preferredRouteId)
        .order(ModelRouteBrandLinkFields.visitOrder, ascending: true);

    final brandIdsInRouteOrder = List<String>.from(
      linkData.map((e) => e[ModelRouteBrandLinkFields.brandId]),
    );

    if (brandIdsInRouteOrder.isEmpty) {
      return {'noPOs': [], 'emptyPOs': [], 'filledPOs': []};
    }

    final nowLocal = DateTime.now(); // IST
    final startOfDayLocal = DateTime(
      nowLocal.year,
      nowLocal.month,
      nowLocal.day,
    );
    final endOfDayLocal = startOfDayLocal.add(const Duration(days: 1));

    final startUtc = startOfDayLocal.toUtc();
    final endUtc = endOfDayLocal.toUtc();

    final poData = await client
        .from(ModelCampaignFields.table)
        .select('${ModelCampaignFields.poId}, ${ModelCampaignFields.poBrandId}')
        .inFilter(ModelCampaignFields.poBrandId, brandIdsInRouteOrder)
        .gte(ModelCampaignFields.createdAt, startUtc.toIso8601String())
        .lt(ModelCampaignFields.createdAt, endUtc.toIso8601String());

    final poByBrand = <String, List<String>>{};
    for (final po in poData) {
      final brandId = po[ModelCampaignFields.poBrandId];
      final poId = po[ModelCampaignFields.poId];
      poByBrand.putIfAbsent(brandId, () => []).add(poId);
    }

    // Step 3: Get collaboration counts for today's POs
    final allPoIds = poData.map((e) => e[ModelCampaignFields.poId]).toList();
    final collaborations = await client
        .from(ModelCollaborationFields.table)
        .select(ModelCollaborationFields.poId)
        .inFilter(ModelCollaborationFields.poId, allPoIds);

    final poIdsWithItems = Set<String>.from(
      collaborations.map((e) => e[ModelCollaborationFields.poId]),
    );

    // Step 4: Classify brands
    final brandsWithFilledPOs = <String>{};
    final brandsWithEmptyPOs = <String>{};

    poByBrand.forEach((brandId, poIds) {
      final hasFilled = poIds.any((poId) => poIdsWithItems.contains(poId));
      if (hasFilled) {
        brandsWithFilledPOs.add(brandId);
      } else {
        brandsWithEmptyPOs.add(brandId);
      }
    });

    final brandsWithPOs = brandsWithFilledPOs.union(brandsWithEmptyPOs);
    final brandsWithNoPOs = brandIdsInRouteOrder
        .where((id) => !brandsWithPOs.contains(id))
        .toSet();

    // Step 5: Fetch brand details and sort by route order
    Future<List<ModelBrand>> fetchBrands(Set<String> ids) async {
      if (ids.isEmpty) return [];
      final result = await client
          .from(ModelBrandFields.tableViewWithForeignKeyLabels)
          .select('*')
          .inFilter(ModelBrandFields.brandId, ids.toList());

      final brands = List<Map<String, dynamic>>.from(
        result,
      ).map((map) => ModelBrand.fromMap(map)).toList();

      return sortBrandsByRouteOrder(
        brands: brands,
        brandIdsInRouteOrder: brandIdsInRouteOrder,
      );
    }

    return {
      'noPOs': await fetchBrands(brandsWithNoPOs),
      'emptyPOs': await fetchBrands(brandsWithEmptyPOs),
      'filledPOs': await fetchBrands(brandsWithFilledPOs),
    };
  }

  Future<List<String>> fetchRouteBrandIds(String routeId) async {
    final linkData = await client
        .from(ModelRouteBrandLinkFields.table)
        .select(ModelRouteBrandLinkFields.brandId)
        .eq(ModelRouteBrandLinkFields.routeId, routeId)
        .order(ModelRouteBrandLinkFields.visitOrder, ascending: true);

    return List<String>.from(
      linkData.map((e) => e[ModelRouteBrandLinkFields.brandId]),
    );
  }

  /// Sort brands according to the route order defined in ModelRouteBrandLinkFields
  List<ModelBrand> sortBrandsByRouteOrder({
    required List<ModelBrand> brands,
    required List<String> brandIdsInRouteOrder,
  }) {
    brands.sort((a, b) {
      final aId = a.brandId ?? ''; // fallback if null
      final bId = b.brandId ?? '';
      final aIndex = brandIdsInRouteOrder.indexOf(aId);
      final bIndex = brandIdsInRouteOrder.indexOf(bId);
      return aIndex.compareTo(bIndex);
    });
    return brands;
  }

  Future<List<ModelBrand>> fetchAllBrandsForRoute(String routeId) async {
    // 1) Get route-linked brand IDs in visit order
    final linkData = await client
        .from(ModelRouteBrandLinkFields.table)
        .select(ModelRouteBrandLinkFields.brandId)
        .eq(ModelRouteBrandLinkFields.routeId, routeId)
        .order(ModelRouteBrandLinkFields.visitOrder, ascending: true);

    final brandIdsInRouteOrder = List<String>.from(
      linkData.map((e) => e[ModelRouteBrandLinkFields.brandId]),
    );

    if (brandIdsInRouteOrder.isEmpty) return [];

    // 2) Fetch brands via view
    final result = await client
        .from(ModelBrandFields.tableViewWithForeignKeyLabels)
        .select('*')
        .inFilter(ModelBrandFields.brandId, brandIdsInRouteOrder);

    final brands = List<Map<String, dynamic>>.from(
      result,
    ).map((map) => ModelBrand.fromMap(map)).toList();

    // 3) Sort by route order (stable and consistent)
    return sortBrandsByRouteOrder(
      brands: brands,
      brandIdsInRouteOrder: brandIdsInRouteOrder,
    );
  }

  /// Fetch brands for preferred route filtered by whether they have POs today
  Future<List<Map<String, dynamic>>> fetchBrandsForPreferredRouteByPOStatus({
    required String? preferredRouteId,
    required bool hasPOsToday,
  }) async {
    if (preferredRouteId == null || preferredRouteId.isEmpty) {
      throw Exception('Preferred route not set for user');
    }

    // Step 1: Get brand_ids linked to preferred_route_id
    final linkData = await client
        .from(ModelRouteBrandLinkFields.table)
        .select(idColumn)
        .eq(ModelRouteBrandLinkFields.routeId, preferredRouteId);

    final brandIds = List<String>.from(linkData.map((e) => e[idColumn]));

    if (brandIds.isEmpty) return [];

    // Step 2: Get brand_ids that HAVE campaigns today
    final nowUtc = DateTime.now().toUtc();
    final startOfDayUtc = DateTime.utc(nowUtc.year, nowUtc.month, nowUtc.day);
    final endOfDayUtc = startOfDayUtc.add(Duration(days: 1));

    final campaigns = await client
        .from(ModelCampaignFields.table)
        .select(ModelCampaignFields.poBrandId)
        .inFilter(ModelCampaignFields.poBrandId, brandIds)
        .gte(ModelCampaignFields.createdAt, startOfDayUtc.toIso8601String())
        .lt(ModelCampaignFields.createdAt, endOfDayUtc.toIso8601String());

    final brandsWithPOsToday = Set<String>.from(
      campaigns.map((e) => e[ModelCampaignFields.poBrandId]),
    );

    // Step 3: Filter brandIds based on PO status
    final filteredBrandIds = hasPOsToday
        ? brandIds.where((id) => brandsWithPOsToday.contains(id)).toList()
        : brandIds.where((id) => !brandsWithPOsToday.contains(id)).toList();

    if (filteredBrandIds.isEmpty) return [];

    // Step 4: Fetch brands with those filtered brand_ids
    final brands = await client
        .from(tableName)
        .select('*')
        .inFilter(idColumn, filteredBrandIds);

    return List<Map<String, dynamic>>.from(brands);
  }

  // --- Legacy methods delegate to new ones ---
  Future<List<ModelBrand>> getAllEntities() async => await fetchAll();

  /* Future<ModelBrand> fetchBrandById(String brandId) async {
    final entity = await fetchById(brandId);
    if (entity == null) throw Exception('Brand not found');
    return entity;
  } */

  // --- Override generic methods to use view ---

  @override
  Stream<List<ModelBrand>> streamEntities() {
    final controller = StreamController<List<ModelBrand>>();
    RealtimeChannel? channel;

    Future<void> fetch() async {
      try {
        final List<dynamic> data = await client
            .from(ModelBrandFields.tableViewWithForeignKeyLabels)
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
  Future<List<ModelBrand>> fetchAll() async {
    final response = await client
        .from(ModelBrandFields.tableViewWithForeignKeyLabels)
        .select()
        .order(sortField ?? createdAt, ascending: sortAscending);
    return (response as List).map((e) => mapper.fromMap(e)).toList();
  }

  @override
  Future<ModelBrand> fetchById(String id) async {
    final response = await client
        .from(ModelBrandFields.tableViewWithForeignKeyLabels)
        .select()
        .eq(idColumn, id)
        .single();
    return mapper.fromMap(response);
  }

  /// Fetches a simplified list of brands with only id and name for dropdowns
  Future<List<Map<String, dynamic>>> getBrandsForDropdown() async {
    debugPrint("inside getBrandsForDropdown()");
    try {
      final response = await client
          .from(ModelBrandFields.table)
          .select('${ModelBrandFields.brandId}, ${ModelBrandFields.brandName}')
          .order(ModelBrandFields.brandName, ascending: true);

      // Convert to the format expected by dropdowns
      return (response as List).map((brand) {
        return {
          'brand_id': brand[ModelBrandFields.brandId],
          'brand_name': brand[ModelBrandFields.brandName],
        };
      }).toList();
    } catch (e) {
      // Handle error appropriately
      rethrow;
    }
  }

  @override
  Future<ModelBrand> getEntityById(String id) async => await fetchById(id);

  @override
  Future<void> insertEntity(ModelBrand entity) async => await create(entity);

  @override
  Future<void> updateEntity(String id, ModelBrand entity) async =>
      await update(id, entity);

  @override
  Future<void> deleteEntityById(String id) async => await delete(id);
}

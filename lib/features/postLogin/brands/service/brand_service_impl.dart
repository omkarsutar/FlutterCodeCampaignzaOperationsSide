import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:flutter_supabase_order_app_mobile/features/postLogin/collaborations/collaboration_barrel.dart';
import 'package:flutter_supabase_order_app_mobile/features/postLogin/campaigns/campaign_barrel.dart';
import 'package:flutter_supabase_order_app_mobile/features/postLogin/agency_brand_links/agency_brand_link_barrel.dart';
import 'package:flutter_supabase_order_app_mobile/features/postLogin/agencies/agency_barrel.dart';
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
    ModelBrandFields.brandsPrimaryAgency: ForeignKeyConfig(
      table: ModelAgencyFields.table,
      idColumn: ModelAgencyFields.agencyId,
      labelColumn: ModelAgencyFields.agencyName,
    ),
  };

  // --- Custom helpers ---

  /// Fetch all brands linked to an agency (either as primary or via agency_brand_link)
  Future<List<ModelBrand>> fetchAllBrandsForPreferredAgency(
    String? agencyId,
  ) async {
    if (agencyId == null || agencyId.isEmpty) {
      throw Exception('Preferred agency not set for user');
    }

    // 1. Get brand IDs from agency_brand_links
    final linkData = await client
        .from(ModelAgencyBrandLinkFields.table)
        .select(ModelAgencyBrandLinkFields.brandId)
        .eq(ModelAgencyBrandLinkFields.agencyId, agencyId);

    final linkedBrandIds = List<String>.from(
      linkData.map((e) => e[ModelAgencyBrandLinkFields.brandId]),
    );

    // 2. Get brand IDs where this agency is primary
    final primaryData = await client
        .from(ModelBrandFields.table)
        .select(ModelBrandFields.brandId)
        .eq(ModelBrandFields.brandsPrimaryAgency, agencyId);

    final primaryBrandIds = List<String>.from(
      primaryData.map((e) => e[ModelBrandFields.brandId]),
    );

    // 3. Combine and remove duplicates
    final allBrandIds = {...linkedBrandIds, ...primaryBrandIds}.toList();

    if (allBrandIds.isEmpty) return [];

    // 4. Fetch brand details from view
    final brands = await client
        .from(ModelBrandFields.tableViewWithForeignKeyLabels)
        .select('*')
        .inFilter(ModelBrandFields.brandId, allBrandIds);

    return List<Map<String, dynamic>>.from(
      brands,
    ).map((brand) => mapper.fromMap(brand)).toList();
  }

  // In your service:
  Stream<Map<String, List<ModelBrand>>> streamBrandsByCollaborationStatus(
    String agencyId,
  ) async* {
    // Supabase live streams
    final poStream = client
        .from(ModelCampaignFields.table)
        .stream(primaryKey: [ModelCampaignFields.poId])
        .eq(ModelCampaignFields.poAgencyId, agencyId);

    final collaborationStream = client
        .from(ModelCollaborationFields.table)
        .stream(primaryKey: [ModelCollaborationFields.collaborationId]);

    // Merge both streams into one
    final merged = StreamGroup.merge([poStream, collaborationStream]);

    await for (final _ in merged) {
      final result = await fetchBrandsByCollaborationStatus(
        agencyId: agencyId,
      );
      yield result;
    }
  }

  /// Classify brands by campaign item status for today
  Future<Map<String, List<ModelBrand>>> fetchBrandsByCollaborationStatus({
    required String? agencyId,
  }) async {
    if (agencyId == null || agencyId.isEmpty) {
      throw Exception('Preferred agency not set for user');
    }

    // Step 1: Get all brand_ids for this agency (linked + primary)
    final brandIdsInAgencyOrder = await fetchAgencyBrandIds(agencyId);

    if (brandIdsInAgencyOrder.isEmpty) {
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
        .inFilter(ModelCampaignFields.poBrandId, brandIdsInAgencyOrder)
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
    final brandsWithNoPOs = brandIdsInAgencyOrder
        .where((id) => !brandsWithPOs.contains(id))
        .toSet();

    // Step 5: Fetch brand details and sort by agency order
    Future<List<ModelBrand>> fetchBrands(Set<String> ids) async {
      if (ids.isEmpty) return [];
      final result = await client
          .from(ModelBrandFields.tableViewWithForeignKeyLabels)
          .select('*')
          .inFilter(ModelBrandFields.brandId, ids.toList());

      final brands = List<Map<String, dynamic>>.from(
        result,
      ).map((map) => ModelBrand.fromMap(map)).toList();

      return sortBrandsByAgencyOrder(
        brands: brands,
        brandIdsInAgencyOrder: brandIdsInAgencyOrder,
      );
    }

    return {
      'noPOs': await fetchBrands(brandsWithNoPOs),
      'emptyPOs': await fetchBrands(brandsWithEmptyPOs),
      'filledPOs': await fetchBrands(brandsWithFilledPOs),
    };
  }

  Future<List<String>> fetchAgencyBrandIds(String agencyId) async {
    // 1. Get brand IDs from agency_brand_links in visit order
    final linkData = await client
        .from(ModelAgencyBrandLinkFields.table)
        .select(ModelAgencyBrandLinkFields.brandId)
        .eq(ModelAgencyBrandLinkFields.agencyId, agencyId)
        .order(ModelAgencyBrandLinkFields.visitOrder, ascending: true);

    final linkedBrandIds = List<String>.from(
      linkData.map((e) => e[ModelAgencyBrandLinkFields.brandId]),
    );

    // 2. Get brand IDs where this agency is primary
    final primaryData = await client
        .from(ModelBrandFields.table)
        .select(ModelBrandFields.brandId)
        .eq(ModelBrandFields.brandsPrimaryAgency, agencyId);

    final primaryBrandIds = List<String>.from(
      primaryData.map((e) => e[ModelBrandFields.brandId]),
    );

    // 3. Combine and remove duplicates (linked ones come first due to visit order)
    return {...linkedBrandIds, ...primaryBrandIds}.toList();
  }

  /// Sort brands according to the agency order defined in ModelAgencyBrandLinkFields
  List<ModelBrand> sortBrandsByAgencyOrder({
    required List<ModelBrand> brands,
    required List<String> brandIdsInAgencyOrder,
  }) {
    brands.sort((a, b) {
      final aId = a.brandId ?? ''; // fallback if null
      final bId = b.brandId ?? '';
      final aIndex = brandIdsInAgencyOrder.indexOf(aId);
      final bIndex = brandIdsInAgencyOrder.indexOf(bId);
      return aIndex.compareTo(bIndex);
    });
    return brands;
  }

  Future<List<ModelBrand>> fetchAllBrandsForAgency(String agencyId) async {
    // 1) Get all agency-linked brand IDs (linked + primary)
    final brandIdsInAgencyOrder = await fetchAgencyBrandIds(agencyId);

    if (brandIdsInAgencyOrder.isEmpty) return [];

    // 2) Fetch brands via view
    final result = await client
        .from(ModelBrandFields.tableViewWithForeignKeyLabels)
        .select('*')
        .inFilter(ModelBrandFields.brandId, brandIdsInAgencyOrder);

    final brands = List<Map<String, dynamic>>.from(
      result,
    ).map((map) => ModelBrand.fromMap(map)).toList();

    // 3) Sort by agency order (stable and consistent)
    return sortBrandsByAgencyOrder(
      brands: brands,
      brandIdsInAgencyOrder: brandIdsInAgencyOrder,
    );
  }

  /// Fetch brands for preferred agency filtered by whether they have POs today
  Future<List<Map<String, dynamic>>> fetchBrandsForPreferredAgencyByPOStatus({
    required String? agencyId,
    required bool hasPOsToday,
  }) async {
    if (agencyId == null || agencyId.isEmpty) {
      throw Exception('Preferred agency not set for user');
    }

    // Step 1: Get all brand_ids for this agency (linked + primary)
    final brandIds = await fetchAgencyBrandIds(agencyId);

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

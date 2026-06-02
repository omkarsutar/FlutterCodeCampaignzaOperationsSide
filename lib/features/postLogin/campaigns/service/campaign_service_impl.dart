import 'dart:async';
import 'package:flutter_supabase_order_app_mobile/features/postLogin/agencies/agency_barrel.dart';
import 'package:flutter_supabase_order_app_mobile/features/postLogin/brands/brand_barrel.dart';
import 'package:flutter_supabase_order_app_mobile/features/postLogin/users/user_barrel.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/config/field_config.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/user_profile_state_provider.dart';
import '../../../../core/services/logger_service.dart';
import '../../../../core/services/entity_service.dart';
import '../model/campaign_model.dart';

import '../../../../core/config/module_config.dart';

class CampaignServiceImpl extends ForeignKeyAwareService<ModelCampaign> {
  final EntityMapper<ModelCampaign> _mapper;
  final Ref _ref;

  CampaignServiceImpl(
    this._mapper,
    SupabaseClient client,
    LoggerService logger,
    this._ref, {
    SortingConfig? initialSorting,
  }) : super(client, logger) {
    if (initialSorting != null) {
      sortField = initialSorting.field;
      sortAscending = initialSorting.sortAscending;
    } else {
      /* sortField = ModelCampaignFields.createdAt;
      sortAscending = false; */
    }
  }

  @override
  EntityMapper<ModelCampaign> get mapper => _mapper;

  @override
  String get tableName => ModelCampaignFields.table;

  @override
  String get idColumn => ModelCampaignFields.poId;
  @override
  String get createdAt => ModelCampaignFields.createdAt;

  @override
  Map<String, ForeignKeyConfig> get foreignKeys => {
    ModelCampaignFields.poAgencyId: ForeignKeyConfig(
      table: ModelAgencyFields.table,
      idColumn: ModelAgencyFields.agencyId,
      labelColumn: ModelAgencyFields.agencyName,
    ),
    ModelCampaignFields.poBrandId: ForeignKeyConfig(
      table: ModelBrandFields.table,
      idColumn: ModelBrandFields.brandId,
      labelColumn: ModelBrandFields.brandName,
    ),
    ModelCampaignFields.createdBy: ForeignKeyConfig(
      table: ModelUserFields.table,
      idColumn: ModelUserFields.userId,
      labelColumn: ModelUserFields.fullName,
    ),
    ModelCampaignFields.updatedBy: ForeignKeyConfig(
      table: ModelUserFields.table,
      idColumn: ModelUserFields.userId,
      labelColumn: ModelUserFields.fullName,
    ),
  };

  // --- Custom helpers ---

  /// Create an empty campaign for a given route and brand
  Future<Map<String, dynamic>> createEmptyCampaign({
    required String poAgencyId,
    required String poBrandId,
  }) async {
    final userId = _ref.read(userProfileStateProvider).profile?.userId;
    if (userId == null) throw Exception('No signed-in user found');

    final entity = ModelCampaign(
      poTotalAmount: 0.0,
      poLineItemCount: 0,
      poAgencyId: poAgencyId,
      poBrandId: poBrandId,
      userComment: null,
      profitToBrand: null,
      poLat: null,
      poLong: null,
      status: null,
      createdBy: userId,
      updatedBy: userId,
    );

    final enriched = mapper.toMap(entity);
    // Exclude status field as per Supabase logic
    enriched.remove(ModelCampaignFields.status);
    final response = await client
        .from(tableName)
        .insert(enriched)
        .select()
        .single();
    return response;
  }

  /// Append a referrer link to an existing campaign, keeping newest links first.
  Future<ModelCampaign> addReferrerLink({
    required String campaignId,
    required String referrerLink,
  }) async {
    final campaign = await fetchById(campaignId);
    final existingLinks = List<String>.from(campaign.referrerLinks);
    existingLinks.removeWhere(
      (link) => link.trim().toLowerCase() == referrerLink.trim().toLowerCase(),
    );
    existingLinks.insert(0, referrerLink.trim());

    final updatedCampaign = campaign.copyWith(referrerLinks: existingLinks);
    return update(campaignId, updatedCampaign);
  }

  /// Update an existing referrer link by replacing the old URL with a new one.
  Future<ModelCampaign> updateReferrerLink({
    required String campaignId,
    required String oldReferrerLink,
    required String newReferrerLink,
  }) async {
    final campaign = await fetchById(campaignId);
    final existingLinks = List<String>.from(campaign.referrerLinks);
    final oldIndex = existingLinks.indexWhere(
      (link) => link.trim() == oldReferrerLink.trim(),
    );

    if (oldIndex == -1) {
      throw Exception('Referrer link not found');
    }

    existingLinks[oldIndex] = newReferrerLink.trim();

    final updatedCampaign = campaign.copyWith(referrerLinks: existingLinks);
    return update(campaignId, updatedCampaign);
  }

  /// Remove a referrer link from an existing campaign.
  Future<ModelCampaign> deleteReferrerLink({
    required String campaignId,
    required String referrerLink,
  }) async {
    final campaign = await fetchById(campaignId);
    final existingLinks = List<String>.from(campaign.referrerLinks);
    existingLinks.removeWhere((link) => link.trim() == referrerLink.trim());

    final updatedCampaign = campaign.copyWith(referrerLinks: existingLinks);
    return update(campaignId, updatedCampaign);
  }

  /// Fetch all campaigns for a given brand
  Future<List<Map<String, dynamic>>> fetchCampaignsForBrand(
    String? selectedBrandId,
  ) async {
    if (selectedBrandId == null || selectedBrandId.isEmpty) {
      throw Exception('Brand ID not provided');
    }

    final campaigns = await client
        .from(ModelCampaignFields.tableViewWithForeignKeyLabels)
        .select('*')
        .eq(ModelCampaignFields.poBrandId, selectedBrandId);

    return List<Map<String, dynamic>>.from(campaigns);
  }

  /// Convenience method to get raw maps instead of typed entities
  Future<List<Map<String, dynamic>>> getAllEntities() async {
    final response = await client
        .from(tableName)
        .select()
        .order(sortField ?? createdAt, ascending: sortAscending);
    return List<Map<String, dynamic>>.from(response);
  }

  /// Stream campaigns filtered by route
  Stream<List<ModelCampaign>> streamEntitiesByRoute(String agencyId) {
    final controller = StreamController<List<ModelCampaign>>();
    RealtimeChannel? channel;

    Future<void> fetch() async {
      try {
        final List<dynamic> data = await client
            .from(ModelCampaignFields.tableViewWithForeignKeyLabels)
            .select()
            .eq(ModelCampaignFields.poAgencyId, agencyId)
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
      channel = client.channel('public:$tableName:$agencyId')
        ..onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: tableName,
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: ModelCampaignFields.poAgencyId,
            value: agencyId,
          ),
          callback: (_) => fetch(),
        )
        ..subscribe();
    }

    controller.onListen = startSubscription;
    controller.onCancel = () => channel?.unsubscribe();

    return controller.stream;
  }

  /// Fetch campaigns for a given brand with foreign labels resolved
  Future<List<Map<String, dynamic>>> fetchEntitiesByBrand(
    String brandId,
  ) async {
    final List<dynamic> result = await client
        .from(ModelCampaignFields.tableViewWithForeignKeyLabels)
        .select()
        .eq(ModelCampaignFields.poBrandId, brandId)
        .order(sortField ?? createdAt, ascending: sortAscending);

    return List<Map<String, dynamic>>.from(result);
  }

  // --- Override generic methods to use view ---

  @override
  Stream<List<ModelCampaign>> streamEntities() {
    final controller = StreamController<List<ModelCampaign>>();
    RealtimeChannel? channel;

    Future<void> fetch() async {
      try {
        final List<dynamic> data = await client
            .from(ModelCampaignFields.tableViewWithForeignKeyLabels)
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
  Future<List<ModelCampaign>> fetchAll() async {
    final response = await client
        .from(ModelCampaignFields.tableViewWithForeignKeyLabels)
        .select()
        .order(sortField ?? createdAt, ascending: sortAscending);
    return (response as List).map((e) => mapper.fromMap(e)).toList();
  }

  @override
  Future<ModelCampaign> fetchById(String id) async {
    final response = await client
        .from(ModelCampaignFields.tableViewWithForeignKeyLabels)
        .select()
        .eq(idColumn, id)
        .single();
    return mapper.fromMap(response);
  }

  @override
  Future<ModelCampaign> create(ModelCampaign entity) async {
    try {
      final userId = _ref.read(userProfileStateProvider).profile?.userId;
      if (userId == null) throw Exception('No signed-in user found');

      final enriched = entity.copyWith(createdBy: userId, updatedBy: userId);

      // Get the map and exclude status field as per Supabase logic
      final payload = mapper.toMap(enriched);
      payload.remove(ModelCampaignFields.status);

      logger.info('Creating new $ModelCampaign in $tableName');
      final inserted = await client
          .from(tableName)
          .insert(payload)
          .select()
          .single();
      final resolved = await resolveForeignLabelsForSingle(inserted);
      logger.info('Successfully created $ModelCampaign');
      return mapper.fromMap(resolved);
    } catch (e, st) {
      logger.error('Failed to create $ModelCampaign', st);
      rethrow;
    }
  }

  @override
  Future<ModelCampaign> update(String id, ModelCampaign entity) async {
    try {
      final userId = _ref.read(userProfileStateProvider).profile?.userId;
      if (userId == null) throw Exception('No signed-in user found');

      final enriched = entity.copyWith(updatedBy: userId);

      // Get the map and exclude status field as per Supabase logic
      final payload = mapper.toMap(enriched);
      payload.remove(ModelCampaignFields.status);

      logger.info('Updating $ModelCampaign with id=$id in $tableName');
      final updated = await client
          .from(tableName)
          .update(payload)
          .eq(idColumn, id)
          .select()
          .single();
      final resolved = await resolveForeignLabelsForSingle(updated);
      logger.info('Successfully updated $ModelCampaign with id=$id');
      return mapper.fromMap(resolved);
    } catch (e, st) {
      logger.error('Failed to update $ModelCampaign with id=$id', st);
      rethrow;
    }
  }

  // --- Override insertEntity to enrich with createdBy/updatedBy ---
  @override
  Future<void> insertEntity(ModelCampaign entity) async {
    final userId = _ref.read(userProfileStateProvider).profile?.userId;
    if (userId == null) throw Exception('No signed-in user found');

    final enriched = mapper.toMap(entity);
    enriched[ModelCampaignFields.createdBy] = userId;
    enriched[ModelCampaignFields.updatedBy] = userId;
    // Exclude status field as per Supabase logic
    enriched.remove(ModelCampaignFields.status);

    await client.from(tableName).insert(enriched);
  }
}

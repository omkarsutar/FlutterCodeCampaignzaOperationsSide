import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/config/field_config.dart';
import '../../../../core/services/entity_service.dart';
import '../../../../core/services/logger_service.dart';
import '../../influencers/influencer_barrel.dart';
import '../../users/user_barrel.dart';
import '../model/user_influencer_link_model.dart';

class UserInfluencerLinkServiceImpl
    extends ForeignKeyAwareService<ModelUserInfluencerLink> {
  final EntityMapper<ModelUserInfluencerLink> _mapper;

  UserInfluencerLinkServiceImpl(
    this._mapper,
    SupabaseClient client,
    LoggerService logger,
  ) : super(client, logger);

  @override
  EntityMapper<ModelUserInfluencerLink> get mapper => _mapper;

  @override
  String get tableName => ModelUserInfluencerLinkFields.table;

  @override
  String? get viewName =>
      ModelUserInfluencerLinkFields.tableViewWithForeignKeyLabels;

  @override
  String get idColumn => ModelUserInfluencerLinkFields.linkId;

  @override
  String get createdAt => ModelUserInfluencerLinkFields.createdAt;

  @override
  Map<String, ForeignKeyConfig> get foreignKeys => {
    ModelUserInfluencerLinkFields.userId: ForeignKeyConfig(
      table: ModelUserFields.table,
      idColumn: ModelUserFields.userId,
      labelColumn: ModelUserFields.fullName,
    ),
    ModelUserInfluencerLinkFields.influencerId: ForeignKeyConfig(
      table: ModelInfluencerFields.table,
      idColumn: ModelInfluencerFields.influencerId,
      labelColumn: ModelInfluencerFields.influencerName,
    ),
  };
}

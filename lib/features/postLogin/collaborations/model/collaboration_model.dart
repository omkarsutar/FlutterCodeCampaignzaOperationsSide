import '../../../../core/services/entity_service.dart';

class ModelCollaborationFields {
  static const String table = 'collaborations';
  static const String tableViewWithForeignKeyLabels = 'view_collaborations';

  static const String collaborationId = 'collaboration_id';
  static const String poId = 'po_id';
  static const String productId = 'product_id';
  static const String itemName = 'item_name';
  static const String itemQty = 'item_qty';
  static const String itemSellRate = 'item_sell_rate';
  static const String itemPrice = 'item_price';
  static const String itemUnitMrp = 'item_unit_mrp';
  static const String profitToShop = 'profit_to_shop';
  static const String createdBy = 'created_by';
  static const String updatedBy = 'updated_by';
  static const String createdAt = 'created_at';
  static const String updatedAt = 'updated_at';

  static const Map<String, String> labels = {
    collaborationId: 'Collaboration',
    poId: 'PO',
    productId: 'Product',
    itemName: 'Item Name',
    itemQty: 'Quantity',
    itemSellRate: 'Sell Rate',
    itemPrice: 'Price',
    itemUnitMrp: 'Unit MRP',
    profitToShop: 'Profit to Shop',
    createdBy: 'Created By',
    updatedBy: 'Updated By',
    createdAt: 'Created At',
    updatedAt: 'Updated At',
  };

  static String getLabel(String field) => labels[field] ?? field;
}

class ModelCollaboration {
  final String? collaborationId;
  final String? poId;
  final String? productId;
  final String? itemName;
  final double? itemQty; // changed from int? to double?
  final double? itemSellRate;
  final double? itemPrice;
  final double? itemUnitMrp;
  final double? profitToShop;
  final String? createdBy;
  final String? updatedBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final Map<String, dynamic> _resolvedLabels;

  ModelCollaboration({
    this.collaborationId,
    this.poId,
    this.productId,
    this.itemName,
    required this.itemQty, // enforce non-null
    this.itemSellRate,
    this.itemPrice,
    this.itemUnitMrp,
    this.profitToShop,
    this.createdBy,
    this.updatedBy,
    this.createdAt,
    this.updatedAt,
    Map<String, dynamic>? resolvedLabels,
  }) : _resolvedLabels = resolvedLabels ?? const {};

  Map<String, dynamic> get resolvedLabels => _resolvedLabels;

  ModelCollaboration copyWith({
    String? collaborationId,
    String? poId,
    String? productId,
    String? itemName,
    double? itemQty,
    double? itemSellRate,
    double? itemPrice,
    double? itemUnitMrp,
    double? profitToShop,
    String? createdBy,
    String? updatedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? resolvedLabels,
  }) {
    return ModelCollaboration(
      collaborationId: collaborationId ?? this.collaborationId,
      poId: poId ?? this.poId,
      productId: productId ?? this.productId,
      itemName: itemName ?? this.itemName,
      itemQty: itemQty ?? this.itemQty,
      itemSellRate: itemSellRate ?? this.itemSellRate,
      itemPrice: itemPrice ?? this.itemPrice,
      itemUnitMrp: itemUnitMrp ?? this.itemUnitMrp,
      profitToShop: profitToShop ?? this.profitToShop,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      resolvedLabels: resolvedLabels ?? this.resolvedLabels,
    );
  }

  factory ModelCollaboration.fromMap(Map<String, dynamic> map) {
    final labelEntries = <String, dynamic>{};
    for (final entry in map.entries) {
      if (entry.key.endsWith('_label')) {
        labelEntries[entry.key] = entry.value;
      }
    }

    return ModelCollaboration(
      collaborationId: map[ModelCollaborationFields.collaborationId]
          ?.toString(),
      poId: map[ModelCollaborationFields.poId]?.toString(),
      productId: map[ModelCollaborationFields.productId]?.toString(),
      itemName: map[ModelCollaborationFields.itemName]?.toString(),
      itemQty: map[ModelCollaborationFields.itemQty] != null
          ? double.tryParse(map[ModelCollaborationFields.itemQty].toString())
          : null, // parse as double
      itemSellRate: map[ModelCollaborationFields.itemSellRate] != null
          ? double.tryParse(
              map[ModelCollaborationFields.itemSellRate].toString(),
            )
          : null,
      itemPrice: map[ModelCollaborationFields.itemPrice] != null
          ? double.tryParse(map[ModelCollaborationFields.itemPrice].toString())
          : null,
      itemUnitMrp: map[ModelCollaborationFields.itemUnitMrp] != null
          ? double.tryParse(
              map[ModelCollaborationFields.itemUnitMrp].toString(),
            )
          : null,
      profitToShop: map[ModelCollaborationFields.profitToShop] != null
          ? double.tryParse(
              map[ModelCollaborationFields.profitToShop].toString(),
            )
          : null,
      createdBy: map[ModelCollaborationFields.createdBy]?.toString(),
      updatedBy: map[ModelCollaborationFields.updatedBy]?.toString(),
      createdAt: map[ModelCollaborationFields.createdAt] != null
          ? DateTime.tryParse(
              map[ModelCollaborationFields.createdAt].toString(),
            )
          : null,
      updatedAt: map[ModelCollaborationFields.updatedAt] != null
          ? DateTime.tryParse(
              map[ModelCollaborationFields.updatedAt].toString(),
            )
          : null,
      resolvedLabels: labelEntries,
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{};

    if (collaborationId != null)
      map[ModelCollaborationFields.collaborationId] = collaborationId;
    if (poId != null) map[ModelCollaborationFields.poId] = poId;
    if (productId != null) map[ModelCollaborationFields.productId] = productId;
    // if (itemName != null) map[ModelCollaborationFields.itemName] = itemName;
    if (itemQty != null)
      map[ModelCollaborationFields.itemQty] = itemQty; // double
    if (itemSellRate != null) {
      map[ModelCollaborationFields.itemSellRate] = itemSellRate;
    }
    if (itemPrice != null) map[ModelCollaborationFields.itemPrice] = itemPrice;
    // if (itemUnitMrp != null) map[ModelCollaborationFields.itemUnitMrp] = itemUnitMrp;
    if (profitToShop != null) {
      map[ModelCollaborationFields.profitToShop] = profitToShop;
    }
    if (createdBy != null) map[ModelCollaborationFields.createdBy] = createdBy;
    if (updatedBy != null) map[ModelCollaborationFields.updatedBy] = updatedBy;
    if (createdAt != null) {
      map[ModelCollaborationFields.createdAt] = createdAt!.toIso8601String();
    }
    if (updatedAt != null) {
      map[ModelCollaborationFields.updatedAt] = updatedAt!.toIso8601String();
    }

    return map;
  }

  Map<String, dynamic> toJson() {
    return {
      'collaborationId': collaborationId,
      'poId': poId,
      'itemName': itemName,
      'itemQty': itemQty,
      'itemSellRate': itemSellRate,
      'itemPrice': itemPrice,
      'itemUnitMrp': itemUnitMrp,
      'profitToShop': profitToShop,
      'createdBy': createdBy,
      'updatedBy': updatedBy,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'productId': productId,
    };
  }

  factory ModelCollaboration.fromJson(Map<String, dynamic> json) {
    return ModelCollaboration(
      collaborationId: json['collaborationId'] as String?,
      poId: json['poId'] as String?,
      itemName: json['itemName'] as String?,
      itemQty: (json['itemQty'] as num).toDouble(),
      itemSellRate: (json['itemSellRate'] as num).toDouble(),
      itemPrice: (json['itemPrice'] as num).toDouble(),
      itemUnitMrp: (json['itemUnitMrp'] as num?)?.toDouble(),
      profitToShop: (json['profitToShop'] as num?)?.toDouble(),
      createdBy: json['createdBy'] as String?,
      updatedBy: json['updatedBy'] as String?,
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] ?? '') ?? DateTime.now(),
      productId: json['productId'] as String?,
    );
  }
}

class ModelCollaborationMapper implements EntityMapper<ModelCollaboration> {
  @override
  ModelCollaboration fromMap(Map<String, dynamic> map) =>
      ModelCollaboration.fromMap(map);

  @override
  Map<String, dynamic> toMap(ModelCollaboration entity) => entity.toMap();
}

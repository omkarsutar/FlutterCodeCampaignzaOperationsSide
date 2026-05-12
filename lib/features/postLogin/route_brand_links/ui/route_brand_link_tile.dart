import 'package:flutter/material.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../core/services/entity_service.dart';
import '../model/route_brand_link_model.dart';

class RouteBrandLinkListTile extends StatelessWidget {
  final ModelRouteBrandLink entity;
  final EntityAdapter<ModelRouteBrandLink> adapter;
  final VoidCallback? onTap;

  const RouteBrandLinkListTile({
    super.key,
    required this.entity,
    required this.adapter,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    String formatTs(dynamic v) {
      if (v == null) return '';
      if (v is DateTime) return formatTimestamp(v);
      if (v is String) {
        final parsed = DateTime.tryParse(v);
        if (parsed != null) return formatTimestamp(parsed);
      }
      return v.toString();
    }

    // Extract values using adapter
    final routeLabel =
        adapter
            .getLabelValue(entity, ModelRouteBrandLinkFields.routeId)
            ?.toString() ??
        'Route not set';
    final brandLabel =
        adapter
            .getLabelValue(entity, ModelRouteBrandLinkFields.brandId)
            ?.toString() ??
        'Brand not set';
    final brandsPrimaryRouteLabel =
        entity.resolvedLabels['brands_primary_route_label']?.toString() ?? '';
    final visitOrder =
        adapter
            .getFieldValue(entity, ModelRouteBrandLinkFields.visitOrder)
            ?.toString() ??
        '-';

    final updatedAt = formatTs(
      adapter.getFieldValue(entity, ModelRouteBrandLinkFields.updatedAt),
    );

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Row 1: Route + Brand
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(Icons.store, size: 16, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          brandLabel,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (brandsPrimaryRouteLabel.isNotEmpty)
                          Text(
                            "P Route: $brandsPrimaryRouteLabel",
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  Text(
                    'Visit Order: $visitOrder',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Row 2: Visit Order
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(
                    Icons.route,
                    size: 16,
                    color: theme.colorScheme.secondary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      routeLabel,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // Row 3: Created / Updated timestamps
              Text(
                'Updated: $updatedAt',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

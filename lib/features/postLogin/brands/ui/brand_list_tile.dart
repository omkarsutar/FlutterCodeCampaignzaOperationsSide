import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
// import 'package:url_launcher/url_launcher.dart';

// import '../../../../core/constants/app_constants.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../../core/services/entity_service.dart';
// import '../../../../core/utils/snackbar_utils.dart';
import '../../users/providers/user_providers.dart';
import '../brand_barrel.dart';

class BrandListTile<T> extends ConsumerWidget {
  final T entity;
  final EntityAdapter<T> adapter;
  final String idField;
  final String entityLabel;
  final String entityLabelLower;
  final String viewRouteName;
  final String rbacModule;
  final VoidCallback? onTap;

  const BrandListTile({
    super.key,
    required this.entity,
    required this.adapter,
    required this.idField,
    required this.entityLabel,
    required this.entityLabelLower,
    required this.viewRouteName,
    required this.rbacModule,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final rbacService = ref.watch(rbacServiceProvider);
    final canCopyLink = rbacService.canCreate(rbacModule);
    final brandName =
        adapter.getFieldValue(entity, ModelBrandFields.brandName)?.toString() ??
        'Unnamed Brand';
    final visitOrder = adapter.getFieldValue(
      entity,
      ModelBrandFields.visitOrder,
    );
    final displayName = visitOrder != null
        ? '$visitOrder. $brandName'
        : brandName;
    final agencyLabel =
        adapter
            .getLabelValue(entity, ModelBrandFields.brandsPrimaryAgency)
            ?.toString() ??
        'Unknown Agency';
    final roleName = ref.watch(roleNameProvider)?.toLowerCase();
    final isAdmin = roleName == 'admin';
    final selectedAgencyId = ref.watch(selectedAgencyIdProvider);
    final brandPrimaryAgencyId = adapter
        .getFieldValue(entity, ModelBrandFields.brandsPrimaryAgency)
        ?.toString();
    final showPrimaryAgencyNote =
        !isAdmin &&
        selectedAgencyId != null &&
        selectedAgencyId.isNotEmpty &&
        brandPrimaryAgencyId != null &&
        brandPrimaryAgencyId.isNotEmpty &&
        selectedAgencyId != brandPrimaryAgencyId;
    final brandPrimaryAgencyLabel =
        adapter
            .getLabelValue(entity, ModelBrandFields.brandsPrimaryAgency)
            ?.toString() ??
        brandPrimaryAgencyId ??
        '';
    final isActive =
        adapter.getFieldValue(entity, ModelBrandFields.isActive) as bool? ??
        false;
    final brandNote =
        adapter.getFieldValue(entity, ModelBrandFields.brandNote)?.toString() ??
        '';
    final hiddenNote =
        adapter
            .getFieldValue(entity, ModelBrandFields.hiddenNote)
            ?.toString() ??
        '';
    final androidAppId =
        adapter
            .getFieldValue(entity, ModelBrandFields.androidAppId)
            ?.toString() ??
        '';
    final websiteUrl =
        adapter
            .getFieldValue(entity, ModelBrandFields.websiteUrl)
            ?.toString() ??
        '';
    final brandPhotoUrl = adapter
        .getFieldValue(entity, ModelBrandFields.brandPhotoUrl)
        ?.toString();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.55),
          width: 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _StatusPill(isActive: isActive),
                  const SizedBox(width: 6),
                  IconButton(
                    tooltip: 'View brand',
                    icon: const Icon(Icons.visibility_outlined),
                    iconSize: 20,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 36,
                      minHeight: 36,
                    ),
                    onPressed: () => context.pushNamed(
                      viewRouteName,
                      pathParameters: {
                        'id': adapter.getId(entity, idField).toString(),
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      width: 60,
                      height: 60,
                      child: _buildBrandImage(brandPhotoUrl),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _InfoRow(
                          icon: brandPhotoUrl == null || brandPhotoUrl.isEmpty
                              ? Icons.business_outlined
                              : null,
                          label: 'Brand',
                          value: displayName,
                          valueStyle: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (showPrimaryAgencyNote) ...[
                          const SizedBox(height: 2),
                          Padding(
                            padding: const EdgeInsets.only(left: 0),
                            child: Text(
                              'Primary Agency : ${brandPrimaryAgencyLabel.isNotEmpty ? brandPrimaryAgencyLabel : brandPrimaryAgencyId}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                        if (isAdmin) ...[
                          const SizedBox(height: 8),
                          _InfoRow(
                            icon: Icons.corporate_fare_outlined,
                            label: 'Agency',
                            value: agencyLabel,
                            valueStyle: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Divider(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                thickness: 1,
              ),
              const SizedBox(height: 8),
              if (brandNote.isNotEmpty) ...[
                Text(
                  brandNote,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
              ],
              if (hiddenNote.isNotEmpty) ...[
                Text(
                  hiddenNote,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontStyle: FontStyle.italic,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
              ],
              Builder(
                builder: (_) {
                  final mobile1 = adapter.getFieldValue(
                    entity,
                    ModelBrandFields.brandMobile1,
                  );
                  final mobile2 = adapter.getFieldValue(
                    entity,
                    ModelBrandFields.brandMobile2,
                  );
                  final personName = adapter.getFieldValue(
                    entity,
                    ModelBrandFields.brandPersonName,
                  );

                  final contactLine = [
                    if (mobile1 != null && mobile1.toString().isNotEmpty)
                      mobile1.toString(),
                    if (mobile2 != null && mobile2.toString().isNotEmpty)
                      mobile2.toString(),
                  ].join(', ');

                  final displayLine =
                      personName != null && personName.toString().isNotEmpty
                      ? '$contactLine (${personName.toString()})'
                      : contactLine;

                  if (displayLine.isEmpty) {
                    return const SizedBox.shrink();
                  }

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      displayLine,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                },
              ),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  if (androidAppId.isNotEmpty)
                    Chip(
                      label: Text(
                        'Android: $androidAppId',
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontSize: 11,
                        ),
                      ),
                      visualDensity: const VisualDensity(
                        horizontal: -4,
                        vertical: -4,
                      ),
                      backgroundColor: Colors.blue.withValues(alpha: 0.1),
                      side: BorderSide(
                        color: Colors.blue.withValues(alpha: 0.3),
                        width: 0.5,
                      ),
                    ),
                  if (websiteUrl.isNotEmpty)
                    Chip(
                      label: Text(
                        'Website: ${websiteUrl.replaceFirst('https://', '')}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      visualDensity: const VisualDensity(
                        horizontal: -4,
                        vertical: -4,
                      ),
                      backgroundColor: Colors.purple.withValues(alpha: 0.1),
                      side: BorderSide(
                        color: Colors.purple.withValues(alpha: 0.3),
                        width: 0.5,
                      ),
                    ),
                ],
              ),
              if (canCopyLink &&
                  (_isValidMobile(
                        adapter.getFieldValue(
                          entity,
                          ModelBrandFields.brandMobile1,
                        ),
                      ) ||
                      _isValidMobile(
                        adapter.getFieldValue(
                          entity,
                          ModelBrandFields.brandMobile2,
                        ),
                      ))) ...[
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    InkWell(
                      // onTap: () => _copyUtmLink(context),
                      onTap: () => {},
                      borderRadius: BorderRadius.circular(20),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Icon(
                          Icons.link,
                          size: 20,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /* Future<void> _copyUtmLink(BuildContext context) async {
    final mobile1 = adapter
        .getFieldValue(entity, ModelBrandFields.brandMobile1)
        ?.toString();
    final mobile2 = adapter
        .getFieldValue(entity, ModelBrandFields.brandMobile2)
        ?.toString();

    String? selectedMobile;
    if (_isValidMobile(mobile1)) {
      selectedMobile = mobile1;
    } else if (_isValidMobile(mobile2)) {
      selectedMobile = mobile2;
    }

    if (selectedMobile == null) {
      SnackbarUtils.showError(
        'Valid 10-digit brand mobile number not available',
      );
      return;
    }

    final translationMap = {
      '0': 'a',
      '1': 'b',
      '2': 'c',
      '3': 'd',
      '4': 'e',
      '5': 'f',
      '6': 'g',
      '7': 'h',
      '8': 'i',
      '9': 'j',
    };

    final utmSource = selectedMobile
        .split('')
        .map((digit) => translationMap[digit] ?? digit)
        .join('');

    final utmLink =
        '${AppConstants.webAppUrlRetailerApp}?utm_source=$utmSource';

    if (_isValidMobile(selectedMobile)) {
      var formattedMobile = selectedMobile;

      if (selectedMobile.length == 10) {
        formattedMobile = '91$selectedMobile';
      } else if (selectedMobile.length == 12 &&
          !selectedMobile.startsWith('91')) {
        formattedMobile = '91$selectedMobile';
      }

      final message = Uri.encodeComponent(utmLink);
      final whatsappUrl = 'https://wa.me/$formattedMobile?text=$message';
      final uri = Uri.parse(whatsappUrl);

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not launch WhatsApp'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } else {
      await Clipboard.setData(ClipboardData(text: utmLink));

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('UTM link copied to clipboard'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  } */

  Widget _buildBrandImage(String? imageUrl) {
    if (imageUrl != null && imageUrl.isNotEmpty) {
      final encodedUrl = Uri.encodeFull(Uri.decodeFull(imageUrl));
      return CachedNetworkImage(
        imageUrl: encodedUrl,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          color: Colors.grey.shade200,
          child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
        errorWidget: (context, url, error) => _buildDefaultAvatar(),
      );
    }
    return _buildDefaultAvatar();
  }

  Widget _buildDefaultAvatar() {
    return Container(
      color: Colors.grey.shade200,
      child: const Center(
        child: Icon(Icons.business, color: Colors.grey, size: 32),
      ),
    );
  }

  bool _isValidMobile(dynamic value) {
    if (value == null) return false;
    final str = value.toString().trim();
    if (str.length != 10) return false;
    return double.tryParse(str) != null;
  }
}

class _StatusPill extends StatelessWidget {
  final bool isActive;

  const _StatusPill({required this.isActive});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isActive ? Colors.green : Colors.orange;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.8), width: 0.8),
      ),
      child: Text(
        isActive ? 'Active' : 'Inactive',
        style: theme.textTheme.labelSmall?.copyWith(
          color: isActive ? Colors.green[800] : Colors.orange[800],
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData? icon;
  final String label;
  final String value;
  final TextStyle? valueStyle;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueStyle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, size: 16, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 8),
        ],
        Expanded(
          child: Text(
            '$label: $value',
            style: valueStyle ?? theme.textTheme.bodyMedium,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

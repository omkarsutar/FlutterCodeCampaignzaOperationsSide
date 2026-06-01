import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_constants.dart';

import '../../../../core/providers/core_providers.dart';
import '../../../../core/services/entity_service.dart';
import '../../../../core/utils/snackbar_utils.dart';
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
        adapter.getFieldValue(entity, ModelBrandFields.brandName) ??
        'Unnamed Brand';
    final visitOrder = adapter.getFieldValue(
      entity,
      ModelBrandFields.visitOrder,
    );
    final displayName = visitOrder != null
        ? '$visitOrder. $brandName'
        : brandName.toString();

    final brandNote =
        adapter.getFieldValue(entity, ModelBrandFields.brandNote)?.toString() ??
        '';
    final hiddenNote =
        adapter
            .getFieldValue(entity, ModelBrandFields.hiddenNote)
            ?.toString() ??
        '';
    final photoUrl =
        adapter.getFieldValue(entity, ModelBrandFields.brandPhotoUrl)
            as String?;
    final isActive = adapter.getFieldValue(
      entity,
      ModelBrandFields.isActive,
    ) as bool? ?? false;
    final agencyLabel = adapter.getLabelValue(
      entity,
      ModelBrandFields.brandsPrimaryAgency,
    )?.toString() ?? '';
    final androidAppId = adapter.getFieldValue(
      entity,
      ModelBrandFields.androidAppId,
    )?.toString() ?? '';
    final websiteUrl = adapter.getFieldValue(
      entity,
      ModelBrandFields.websiteUrl,
    )?.toString() ?? '';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap ?? () => onTap,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row: Brand Name + Status Badge + View Button
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Brand Name
                        Text(
                          displayName,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        // Agency Label
                        if (agencyLabel.isNotEmpty)
                          Text(
                            agencyLabel,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isActive
                          ? Colors.green.withValues(alpha: 0.15)
                          : Colors.orange.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isActive ? Colors.green : Colors.orange,
                        width: 0.8,
                      ),
                    ),
                    child: Text(
                      isActive ? 'Active' : 'Inactive',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: isActive
                            ? Colors.green[800]
                            : Colors.orange[800],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  InkWell(
                    onTap: () => context.pushNamed(
                      viewRouteName,
                      pathParameters: {
                        'id': adapter.getId(entity, idField).toString(),
                      },
                    ),
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.all(6.0),
                      child: Icon(
                        Icons.visibility,
                        size: 20,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Divider
              Divider(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                thickness: 1,
              ),

              const SizedBox(height: 8),

              // Brand Note
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

              // Hidden Note
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

              // Mobiles + Person name
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
                  ].join(", ");

                  final displayLine = personName != null &&
                          personName.toString().isNotEmpty
                      ? "$contactLine (${personName.toString()})"
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

              // Android App ID and Website URL
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

              // Copy Link Action Button (if valid mobile)
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
                      onTap: () => _copyUtmLink(context),
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

  Future<void> _copyUtmLink(BuildContext context) async {
    // Get brand mobile numbers
    final mobile1 = adapter
        .getFieldValue(entity, ModelBrandFields.brandMobile1)
        ?.toString();
    final mobile2 = adapter
        .getFieldValue(entity, ModelBrandFields.brandMobile2)
        ?.toString();

    // Select first valid 10-digit mobile number
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

    final mobileNumber = selectedMobile;

    // Translate mobile number digits to characters
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

    final utmSource = mobileNumber
        .split('')
        .map((digit) {
          return translationMap[digit] ?? digit;
        })
        .join('');

    final utmLink =
        '${AppConstants.webAppUrlRetailerApp}?utm_source=$utmSource';

    // Copy to clipboard
    // Share to WhatsApp if mobile number is available
    if (_isValidMobile(mobileNumber)) {
      // Validate and format mobile number
      String formattedMobile = mobileNumber;

      if (mobileNumber.length == 10) {
        // Add '91' prefix for 10-digit numbers
        formattedMobile = '91$mobileNumber';
      } else if (mobileNumber.length == 12) {
        // Check if first 2 digits are '91', if not add '91' prefix
        if (!mobileNumber.startsWith('91')) {
          formattedMobile = '91$mobileNumber';
        }
      }

      final message = Uri.encodeComponent(utmLink);
      final whatsappUrl = 'https://wa.me/$formattedMobile?text=$message';
      final uri = Uri.parse(whatsappUrl);

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not launch WhatsApp'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } else {
      // Fallback to clipboard if no mobile number
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
  }

  bool _isValidMobile(dynamic value) {
    if (value == null) return false;
    final str = value.toString().trim();
    if (str.length != 10) return false;
    return double.tryParse(str) != null;
  }
}

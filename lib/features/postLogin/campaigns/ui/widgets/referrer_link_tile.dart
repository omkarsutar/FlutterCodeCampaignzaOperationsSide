import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../core/utils/snackbar_utils.dart';
import '../../../collaborations/providers/collaboration_providers.dart';

class ReferrerLinkTile extends ConsumerWidget {
  final String link;
  final int index;
  final Future<void> Function(String existingLink)? onEdit;
  final Future<void> Function(String existingLink)? onDelete;

  const ReferrerLinkTile({
    super.key,
    required this.link,
    required this.index,
    this.onEdit,
    this.onDelete,
  });

  Uri? get _uri => Uri.tryParse(link);

  Map<String, String> get _utmValues {
    final uri = _uri;
    final referrer = uri?.queryParameters['referrer'];
    if (referrer == null || referrer.isEmpty) return const {};

    try {
      return Uri.splitQueryString(referrer);
    } catch (_) {
      return const {};
    }
  }

  String _utm(String key) {
    final value = _utmValues[key]?.trim();
    return (value == null || value.isEmpty) ? 'N/A' : value;
  }

  Future<void> _openLink(BuildContext context) async {
    final uri = _uri;
    if (uri == null) {
      SnackbarUtils.showError('Invalid referrer link');
      return;
    }

    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      SnackbarUtils.showError('Unable to open link');
    }
  }

  Future<void> _copyLink(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: link));
    SnackbarUtils.showSuccess('Link copied to clipboard');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final installCountAsync = link.isEmpty
        ? null
        : ref.watch(installCountProvider(link));

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Text(
                    '${index + 1}',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildInfoChip(theme, 'utm_source', _utm('utm_source')),
                      _buildInfoChip(
                        theme,
                        'utm_campaign',
                        _utm('utm_campaign'),
                      ),
                      _buildInfoChip(theme, 'utm_medium', _utm('utm_medium')),
                      if (installCountAsync != null)
                        installCountAsync.when(
                          data: (count) => _buildCountChip(
                            theme,
                            'Installs: $count',
                            theme.colorScheme.tertiary,
                          ),
                          loading: () => const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          error: (_, __) => _buildCountChip(
                            theme,
                            'Installs: Error',
                            theme.colorScheme.error,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  children: [
                    IconButton(
                      tooltip: 'Open link',
                      icon: const Icon(Icons.open_in_new),
                      onPressed: () => _openLink(context),
                    ),
                    IconButton(
                      tooltip: 'Copy link',
                      icon: const Icon(Icons.copy),
                      onPressed: () => _copyLink(context),
                    ),
                    IconButton(
                      tooltip: 'Edit link',
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: onEdit == null
                          ? null
                          : () => onEdit!(link),
                    ),
                    IconButton(
                      tooltip: 'Delete link',
                      icon: const Icon(Icons.delete_outline),
                      color: theme.colorScheme.error,
                      onPressed: onDelete == null
                          ? null
                          : () => onDelete!(link),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            SelectableText(
              link,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontFamily: 'monospace',
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(ThemeData theme, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$label: $value',
        style: theme.textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w700,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _buildCountChip(ThemeData theme, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

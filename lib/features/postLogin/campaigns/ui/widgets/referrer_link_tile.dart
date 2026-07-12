import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../core/utils/snackbar_utils.dart';
import '../../../collaborations/providers/collaboration_providers.dart';

class ReferrerLinkTile extends ConsumerWidget {
  final String link;
  final String title;
  final Future<void> Function(String existingLink)? onEdit;
  final Future<void> Function(String existingLink)? onDelete;
  final EdgeInsetsGeometry margin;
  final Widget? leadingWidget;
  final Widget? belowLinkWidget;

  const ReferrerLinkTile({
    super.key,
    required this.link,
    this.title = 'Referrer Link',
    this.onEdit,
    this.onDelete,
    this.margin = const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    this.leadingWidget,
    this.belowLinkWidget,
  });

  Uri? get _uri => Uri.tryParse(link);

  String get _countLookupLink {
    final uri = _uri;
    if (uri == null) return link;
    final cleaned = uri.replace(fragment: null).toString();
    return cleaned.endsWith('#') ? cleaned.substring(0, cleaned.length - 1) : cleaned;
  }

  bool get _isPlayStoreLink {
    final uri = _uri;
    return uri != null &&
        uri.host.contains('play.google.com') &&
        uri.queryParameters['referrer']?.isNotEmpty == true;
  }

  bool get _isWebsiteLink => !_isPlayStoreLink && _uri != null;

  Map<String, String> get _utmValues {
    final uri = _uri;
    if (uri == null) return const {};

    if (_isPlayStoreLink) {
      final referrer = uri.queryParameters['referrer'];
      if (referrer == null || referrer.isEmpty) return const {};

      try {
        return Uri.splitQueryString(referrer);
      } catch (_) {
        return const {};
      }
    }

    return uri.queryParameters;
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
    await Clipboard.setData(ClipboardData(text: _copyableLinkText()));
    SnackbarUtils.showSuccess('Link copied to clipboard');
  }

  String _copyableLinkText() {
    final uri = _uri;
    if (uri == null) return link;

    if (_isPlayStoreLink) {
      final appId = uri.queryParameters['id']?.trim();
      final referrer = uri.queryParameters['referrer']?.trim();
      if (appId == null || appId.isEmpty || referrer == null || referrer.isEmpty) {
        return link;
      }

      try {
        final params = Uri.splitQueryString(referrer);
        final utmSource = params['utm_source']?.trim() ?? '';
        final utmCampaign = params['utm_campaign']?.trim() ?? '';
        final utmMedium = params['utm_medium']?.trim() ?? '';

        return 'https://play.google.com/store/apps/details?id=$appId'
            '&referrer=utm_source=$utmSource'
            '&utm_campaign=$utmCampaign'
            '&utm_medium=$utmMedium';
      } catch (_) {
        return link;
      }
    }

    final basePath =
        '${uri.scheme}://${uri.authority}${uri.path.isEmpty ? '/' : uri.path}';
    final query = uri.queryParameters.entries
        .map((entry) => '${entry.key}=${entry.value}')
        .join('&');
    if (query.isEmpty) return basePath;
    return '$basePath?$query';
  }

  TextSpan _buildHighlightedLinkSpan(ThemeData theme) {
    final uri = _uri;
    final baseStyle = theme.textTheme.bodySmall?.copyWith(
          fontFamily: 'monospace',
          color: theme.colorScheme.onSurfaceVariant,
        ) ??
        const TextStyle(fontFamily: 'monospace');
    final highlightStyle = baseStyle.copyWith(
      color: theme.colorScheme.primary,
      fontWeight: FontWeight.w700,
      backgroundColor: theme.colorScheme.primaryContainer.withValues(
        alpha: 0.45,
      ),
    );

    if (uri == null) {
      return TextSpan(text: link, style: baseStyle);
    }

    if (_isPlayStoreLink) {
      final appId = uri.queryParameters['id']?.trim();
      final referrer = uri.queryParameters['referrer'];
      if (appId == null || appId.isEmpty || referrer == null || referrer.isEmpty) {
        return TextSpan(text: link, style: baseStyle);
      }

      Map<String, String> parts;
      try {
        parts = Uri.splitQueryString(referrer);
      } catch (_) {
        return TextSpan(text: link, style: baseStyle);
      }

      return TextSpan(
        style: baseStyle,
        children: [
          const TextSpan(
            text: 'https://play.google.com/store/apps/details?id=',
          ),
          TextSpan(text: appId, style: highlightStyle),
          const TextSpan(text: '&referrer='),
          const TextSpan(text: 'utm_source='),
          TextSpan(
            text: parts['utm_source']?.trim().isNotEmpty == true
                ? parts['utm_source']!.trim()
                : '<>',
            style: highlightStyle,
          ),
          const TextSpan(text: '&utm_campaign='),
          TextSpan(
            text: parts['utm_campaign']?.trim().isNotEmpty == true
                ? parts['utm_campaign']!.trim()
                : '<>',
            style: highlightStyle,
          ),
          const TextSpan(text: '&utm_medium='),
          TextSpan(
            text: parts['utm_medium']?.trim().isNotEmpty == true
                ? parts['utm_medium']!.trim()
                : '<>',
            style: highlightStyle,
          ),
        ],
      );
    }

    final basePath =
        '${uri.scheme}://${uri.authority}${uri.path.isEmpty ? '/' : uri.path}';
    final params = uri.queryParameters;

    return TextSpan(
      style: baseStyle,
      children: [
        TextSpan(text: basePath, style: baseStyle),
        if (params.isNotEmpty) const TextSpan(text: '?'),
        if (params.isNotEmpty) const TextSpan(text: 'utm_source='),
        if (params.isNotEmpty)
          TextSpan(
            text: params['utm_source']?.trim().isNotEmpty == true
                ? params['utm_source']!.trim()
                : '<>',
            style: highlightStyle,
          ),
        if (params.isNotEmpty) const TextSpan(text: '&utm_campaign='),
        if (params.isNotEmpty)
          TextSpan(
            text: params['utm_campaign']?.trim().isNotEmpty == true
                ? params['utm_campaign']!.trim()
                : '<>',
            style: highlightStyle,
          ),
        if (params.isNotEmpty) const TextSpan(text: '&utm_medium='),
        if (params.isNotEmpty)
          TextSpan(
            text: params['utm_medium']?.trim().isNotEmpty == true
                ? params['utm_medium']!.trim()
                : '<>',
            style: highlightStyle,
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final countAsync = (_isPlayStoreLink && link.isNotEmpty)
        ? ref.watch(installCountProvider(_countLookupLink))
        : (_isWebsiteLink && link.isNotEmpty)
            ? ref.watch(websiteVisitCountProvider(_countLookupLink))
            : null;
    final countLabel = _isPlayStoreLink ? 'Installs' : 'Visits';
    final countColor = _isPlayStoreLink
        ? theme.colorScheme.tertiary
        : theme.colorScheme.secondary;
    final refreshTooltip =
        _isPlayStoreLink ? 'Refresh installs' : 'Refresh visits';
    final refreshMessage = _isPlayStoreLink
        ? 'Refreshing install count...'
        : 'Refreshing visit count...';
    final refreshProvider = _isPlayStoreLink
        ? installCountProvider(_countLookupLink)
        : websiteVisitCountProvider(_countLookupLink);

    return Card(
      margin: margin,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer.withValues(
                      alpha: 0.8,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: leadingWidget ??
                        Icon(
                          Icons.link_rounded,
                          size: 20,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (countAsync != null) ...[
                        countAsync.when(
                          data: (count) => _buildCountChip(
                            theme,
                            '$countLabel: $count',
                            countColor,
                          ),
                          loading: () => const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          error: (_, __) => _buildCountChip(
                            theme,
                            '$countLabel: Error',
                            theme.colorScheme.error,
                          ),
                        ),
                        IconButton(
                          tooltip: refreshTooltip,
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints.tightFor(
                            width: 32,
                            height: 32,
                          ),
                          icon: Icon(
                            Icons.refresh_rounded,
                            size: 18,
                            color: theme.colorScheme.primary,
                          ),
                          onPressed: () {
                            ref.invalidate(refreshProvider);
                            SnackbarUtils.showSuccess(refreshMessage);
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _buildInfoChip(theme, 'utm_source', _utm('utm_source')),
                _buildInfoChip(theme, 'utm_campaign', _utm('utm_campaign')),
                _buildInfoChip(theme, 'utm_medium', _utm('utm_medium')),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                IconButton(
                  tooltip: 'Open link',
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.open_in_new, size: 20),
                  onPressed: () => _openLink(context),
                ),
                IconButton(
                  tooltip: 'Copy link',
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.copy, size: 20),
                  onPressed: () => _copyLink(context),
                ),
                IconButton(
                  tooltip: 'Edit link',
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  onPressed: onEdit == null ? null : () => onEdit!(link),
                ),
                IconButton(
                  tooltip: 'Delete link',
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.delete_outline, size: 20),
                  color: theme.colorScheme.error,
                  onPressed: onDelete == null ? null : () => onDelete!(link),
                ),
              ],
            ),
            const SizedBox(height: 4),
            SelectableText.rich(
              _buildHighlightedLinkSpan(theme),
              style: theme.textTheme.bodySmall?.copyWith(
                fontFamily: 'monospace',
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (belowLinkWidget != null) ...[
              const SizedBox(height: 12),
              Center(child: belowLinkWidget!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(ThemeData theme, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(999),
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
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

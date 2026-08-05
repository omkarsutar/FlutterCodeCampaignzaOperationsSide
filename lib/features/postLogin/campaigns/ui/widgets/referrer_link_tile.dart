import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../core/utils/snackbar_utils.dart';
import '../../../collaborations/providers/collaboration_providers.dart';

class ReferrerLinkTile extends ConsumerWidget {
  final String link;
  final String title;
  final String? campaignPlatform;
  final Future<void> Function(String existingLink)? onEdit;
  final Future<void> Function(String existingLink)? onDelete;
  final EdgeInsetsGeometry margin;
  final Widget? leadingWidget;
  final Widget? belowLinkWidget;

  const ReferrerLinkTile({
    super.key,
    required this.link,
    this.title = 'Referrer Link',
    this.campaignPlatform,
    this.onEdit,
    this.onDelete,
    this.margin = const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    this.leadingWidget,
    this.belowLinkWidget,
  });

  Uri? get _uri => Uri.tryParse(link);

  String get _countLookupLink => link;

  bool get _isPlayStoreLink {
    final uri = _uri;
    return uri != null &&
        uri.host.contains('play.google.com') &&
        uri.queryParameters['referrer']?.isNotEmpty == true;
  }

  bool get _isWebsiteLink => !_isPlayStoreLink && link.trim().isNotEmpty;

  Map<String, String> get _utmValues {
    if (link.isEmpty) return const {};

    if (_isPlayStoreLink) {
      final uri = _uri;
      final referrer = uri?.queryParameters['referrer'];
      if (referrer == null || referrer.isEmpty) return const {};

      try {
        return Uri.splitQueryString(referrer);
      } catch (_) {
        return const {};
      }
    }

    final qIndex = link.indexOf('?');
    if (qIndex < 0) return const {};
    try {
      return Uri.splitQueryString(link.substring(qIndex + 1));
    } catch (_) {
      return const {};
    }
  }

  String _utm(String key) {
    final value = _utmValues[key]?.trim();
    return (value == null || value.isEmpty) ? 'N/A' : value;
  }

  // Encode referrer value for Play Store so '&' and '|' don't split the outer query
  String _encodeReferrerValue(String value) {
    // Keep '=' signs intact but percent-encode ampersands and pipe characters which would
    // otherwise be interpreted as query separators. Also encode hash and question mark.
    return value
        .replaceAll('&', '%26')
        .replaceAll('|', '%7C')
        .replaceAll('#', '%23')
        .replaceAll('?', '%3F');
  }

  Future<void> _openLink(BuildContext context) async {
    if (link.isEmpty) {
      SnackbarUtils.showError('Invalid referrer link');
      return;
    }

    try {
      if (_isPlayStoreLink) {
        final uri = _uri;
        if (uri == null) {
          SnackbarUtils.showError('Invalid referrer link');
          return;
        }
        // Reconstruct Play Store link with encoded referrer value so it is treated as a single
        // query parameter value by Play Store.
        final appId = uri.queryParameters['id']?.trim();
        final referrer = uri.queryParameters['referrer']?.trim();
        if (appId == null ||
            appId.isEmpty ||
            referrer == null ||
            referrer.isEmpty) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          return;
        }

        final encodedRef = _encodeReferrerValue(referrer);
        final reconstructed =
            'https://play.google.com/store/apps/details?id=$appId&referrer=$encodedRef';
        await launchUrl(
          Uri.parse(reconstructed),
          mode: LaunchMode.externalApplication,
        );
        return;
      }

      await launchUrl(Uri.parse(link), mode: LaunchMode.externalApplication);
    } catch (_) {
      SnackbarUtils.showError('Unable to open link');
    }
  }

  Future<void> _copyLink(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: _copyableLinkText()));
    SnackbarUtils.showSuccess('Link copied to clipboard');
  }

  String _copyableLinkText() {
    if (_isPlayStoreLink) {
      final uri = _uri;
      if (uri == null) return link;
      final appId = uri.queryParameters['id']?.trim();
      final referrer = uri.queryParameters['referrer']?.trim();
      if (appId == null ||
          appId.isEmpty ||
          referrer == null ||
          referrer.isEmpty) {
        return link;
      }

      try {
        final params = Uri.splitQueryString(referrer);
        final utmSource = params['utm_source']?.trim() ?? '';
        final utmCampaign = params['utm_campaign']?.trim() ?? '';
        final utmMedium = params['utm_medium']?.trim() ?? '';

        final rawRef =
            'utm_source=$utmSource&utm_campaign=$utmCampaign&utm_medium=$utmMedium';
        final encodedRef = _encodeReferrerValue(rawRef);

        return 'https://play.google.com/store/apps/details?id=$appId&referrer=$encodedRef';
      } catch (_) {
        return link;
      }
    }

    return link;
  }

  TextSpan _buildHighlightedLinkSpan(ThemeData theme) {
    final baseStyle =
        theme.textTheme.bodySmall?.copyWith(
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

    if (_isPlayStoreLink) {
      final uri = _uri;
      if (uri == null) return TextSpan(text: link, style: baseStyle);
      final appId = uri.queryParameters['id']?.trim();
      final referrer = uri.queryParameters['referrer'];
      if (appId == null ||
          appId.isEmpty ||
          referrer == null ||
          referrer.isEmpty) {
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

    final parsed = ParsedWebsiteUrl.parse(link);
    if (parsed.authority.isEmpty) {
      return TextSpan(text: link, style: baseStyle);
    }

    final bool useFragmentForUtm = parsed.hasHash;
    final bool highlightRoutePath =
        campaignPlatform?.trim().toLowerCase() != 'android_app';
    final targetParams = useFragmentForUtm
        ? parsed.fragmentQueryParameters
        : parsed.queryParameters;

    final nonUtmParams = Map<String, String>.from(targetParams)
      ..remove('utm_source')
      ..remove('utm_campaign')
      ..remove('utm_medium');
    final nonUtmQuery = nonUtmParams.isNotEmpty
        ? Uri(queryParameters: nonUtmParams).query
        : '';

    final String basePath;
    final String? highlightedFragmentPath;
    final String fragmentSuffix;
    if (useFragmentForUtm) {
      final mainQuery = parsed.queryParameters.isNotEmpty
          ? '?${Uri(queryParameters: parsed.queryParameters).query}'
          : '';
      final fragQueryPart = nonUtmQuery.isNotEmpty ? '?$nonUtmQuery' : '';
      basePath =
          '${parsed.scheme}://${parsed.authority}${parsed.path.isEmpty ? '/' : parsed.path}'
          '$mainQuery#';
      highlightedFragmentPath = parsed.fragmentPath.isNotEmpty
          ? parsed.fragmentPath
          : null;
      fragmentSuffix = fragQueryPart;
    } else {
      final queryPart = nonUtmQuery.isNotEmpty ? '?$nonUtmQuery' : '';
      basePath =
          '${parsed.scheme}://${parsed.authority}${parsed.path.isEmpty ? '/' : parsed.path}$queryPart';
      highlightedFragmentPath = null;
      fragmentSuffix = '';
    }

    final prefix = nonUtmQuery.isNotEmpty ? '&' : '?';
    final fragmentStyle = highlightRoutePath ? highlightStyle : baseStyle;

    return TextSpan(
      style: baseStyle,
      children: [
        TextSpan(text: basePath, style: baseStyle),
        if (highlightedFragmentPath != null)
          TextSpan(text: highlightedFragmentPath, style: fragmentStyle),
        if (fragmentSuffix.isNotEmpty)
          TextSpan(text: fragmentSuffix, style: baseStyle),
        TextSpan(text: prefix),
        const TextSpan(text: 'utm_source='),
        TextSpan(
          text: targetParams['utm_source']?.trim().isNotEmpty == true
              ? targetParams['utm_source']!.trim()
              : '<>',
          style: highlightStyle,
        ),
        const TextSpan(text: '&utm_campaign='),
        TextSpan(
          text: targetParams['utm_campaign']?.trim().isNotEmpty == true
              ? targetParams['utm_campaign']!.trim()
              : '<>',
          style: highlightStyle,
        ),
        const TextSpan(text: '&utm_medium='),
        TextSpan(
          text: targetParams['utm_medium']?.trim().isNotEmpty == true
              ? targetParams['utm_medium']!.trim()
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
    final refreshTooltip = _isPlayStoreLink
        ? 'Refresh installs'
        : 'Refresh visits';
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
                    child:
                        leadingWidget ??
                        Icon(
                          Icons.link_rounded,
                          size: 20,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      _buildInfoChip(theme, 'utm_source', _utm('utm_source')),
                      _buildInfoChip(
                        theme,
                        'utm_campaign',
                        _utm('utm_campaign'),
                      ),
                      _buildInfoChip(theme, 'utm_medium', _utm('utm_medium')),
                    ],
                  ),
                ),
                if (countAsync != null) ...[
                  const SizedBox(width: 8),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'Performance',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 6),
                      countAsync.when(
                        data: (count) => _buildCountBadge(
                          theme,
                          countLabel,
                          count,
                          countColor,
                        ),
                        loading: () => const SizedBox(
                          width: 36,
                          height: 36,
                          child: Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                        error: (_, __) => _buildCountBadge(
                          theme,
                          'Error',
                          null,
                          theme.colorScheme.error,
                          isError: true,
                        ),
                      ),
                      const SizedBox(height: 6),
                      SizedBox(
                        width: 32,
                        height: 32,
                        child: IconButton(
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
                      ),
                    ],
                  ),
                ],
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
    final labelStyle = theme.textTheme.labelSmall?.copyWith(
      fontWeight: FontWeight.w700,
      color: theme.colorScheme.onSurfaceVariant,
    );
    final valueStyle = theme.textTheme.labelSmall?.copyWith(
      fontWeight: FontWeight.w700,
      color: theme.colorScheme.primary,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(999),
      ),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(text: '$label: ', style: labelStyle),
            TextSpan(text: value, style: valueStyle),
          ],
        ),
      ),
    );
  }

  Widget _buildCountBadge(
    ThemeData theme,
    String label,
    int? count,
    Color color, {
    bool isError = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isError
            ? theme.colorScheme.error.withValues(alpha: 0.12)
            : color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isError ? theme.colorScheme.error : color,
          width: 1.2,
        ),
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            label,
            textAlign: TextAlign.center,
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: isError
                  ? theme.colorScheme.error
                  : theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            count?.toString() ?? '—',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: isError ? theme.colorScheme.error : color,
            ),
          ),
        ],
      ),
    );
  }
}

class ParsedWebsiteUrl {
  final String scheme;
  final String authority;
  final String path;
  final Map<String, String> queryParameters;
  final bool hasHash;
  final String fragmentPath;
  final Map<String, String> fragmentQueryParameters;

  ParsedWebsiteUrl({
    required this.scheme,
    required this.authority,
    required this.path,
    required this.queryParameters,
    required this.hasHash,
    required this.fragmentPath,
    required this.fragmentQueryParameters,
  });

  static ParsedWebsiteUrl parse(String url) {
    final trimmed = url.trim();
    final hasScheme =
        trimmed.startsWith('http://') || trimmed.startsWith('https://');
    final candidate = hasScheme ? trimmed : 'https://$trimmed';

    final tempUri = Uri.tryParse(candidate);
    if (tempUri == null) {
      return ParsedWebsiteUrl(
        scheme: 'https',
        authority: '',
        path: '',
        queryParameters: const {},
        hasHash: false,
        fragmentPath: '',
        fragmentQueryParameters: const {},
      );
    }

    final scheme = tempUri.scheme;
    final authority = tempUri.authority;
    final path = tempUri.path;
    final queryParameters = tempUri.queryParameters;
    final hasHash = candidate.contains('#');

    String fragmentPath = '';
    Map<String, String> fragmentQueryParameters = const {};

    if (hasHash) {
      final fragment = tempUri.fragment;
      final qIndex = fragment.indexOf('?');
      if (qIndex >= 0) {
        fragmentPath = fragment.substring(0, qIndex);
        try {
          fragmentQueryParameters = Uri.splitQueryString(
            fragment.substring(qIndex + 1),
          );
        } catch (_) {}
      } else {
        fragmentPath = fragment;
      }
    }

    return ParsedWebsiteUrl(
      scheme: scheme,
      authority: authority,
      path: path,
      queryParameters: queryParameters,
      hasHash: hasHash,
      fragmentPath: fragmentPath,
      fragmentQueryParameters: fragmentQueryParameters,
    );
  }

  String build({
    required String utmSource,
    required String utmCampaign,
    required String utmMedium,
  }) {
    if (authority.isEmpty) return '';

    Map<String, String> mergedQuery = Map<String, String>.from(queryParameters);
    Map<String, String> mergedFragmentQuery = Map<String, String>.from(
      fragmentQueryParameters,
    );

    mergedQuery.remove('utm_source');
    mergedQuery.remove('utm_campaign');
    mergedQuery.remove('utm_medium');

    mergedFragmentQuery.remove('utm_source');
    mergedFragmentQuery.remove('utm_campaign');
    mergedFragmentQuery.remove('utm_medium');

    if (hasHash) {
      if (utmSource.isNotEmpty) mergedFragmentQuery['utm_source'] = utmSource;
      if (utmCampaign.isNotEmpty)
        mergedFragmentQuery['utm_campaign'] = utmCampaign;
      if (utmMedium.isNotEmpty) mergedFragmentQuery['utm_medium'] = utmMedium;
    } else {
      if (utmSource.isNotEmpty) mergedQuery['utm_source'] = utmSource;
      if (utmCampaign.isNotEmpty) mergedQuery['utm_campaign'] = utmCampaign;
      if (utmMedium.isNotEmpty) mergedQuery['utm_medium'] = utmMedium;
    }

    final queryStr = mergedQuery.isNotEmpty
        ? Uri(queryParameters: mergedQuery).query
        : '';
    final fragmentQueryStr = mergedFragmentQuery.isNotEmpty
        ? Uri(queryParameters: mergedFragmentQuery).query
        : '';

    final basePart = '$scheme://$authority${path.isEmpty ? '/' : path}';
    final queryPart = queryStr.isNotEmpty ? '?$queryStr' : '';

    if (hasHash) {
      final fragPart = fragmentPath.isNotEmpty || fragmentQueryStr.isNotEmpty
          ? '#$fragmentPath'
          : '';
      final fragQueryPart = fragmentQueryStr.isNotEmpty
          ? '?$fragmentQueryStr'
          : '';
      return '$basePart$queryPart$fragPart$fragQueryPart';
    } else {
      return '$basePart$queryPart';
    }
  }
}

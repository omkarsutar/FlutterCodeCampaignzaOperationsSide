import 'package:flutter/material.dart';

class ReferrerLinkFormResult {
  final String link;
  final String referrerLinkType;
  final String referrerLinkSource;

  const ReferrerLinkFormResult({
    required this.link,
    required this.referrerLinkType,
    required this.referrerLinkSource,
  });
}

class ReferrerLinkFormPage extends StatefulWidget {
  final String appId;
  final String campaignNameString;
  final String? campaignPlatform;
  final String? websiteUrl;
  final String? promoCode;
  final String? existingLink;
  final String? initialReferrerLinkType;
  final String? initialReferrerLinkSource;

  const ReferrerLinkFormPage({
    super.key,
    required this.appId,
    required this.campaignNameString,
    this.campaignPlatform,
    this.websiteUrl,
    this.promoCode,
    this.existingLink,
    this.initialReferrerLinkType,
    this.initialReferrerLinkSource,
  });

  @override
  State<ReferrerLinkFormPage> createState() => _ReferrerLinkFormPageState();
}

class _ReferrerLinkFormPageState extends State<ReferrerLinkFormPage> {
  static const List<String> _referrerLinkTypeOptions = ['plain', 'qrcode'];
  static const List<String> _baseReferrerLinkSourceOptions = [
    'facebook',
    'instagram',
    'youtube',
    'google',
    'tiktok',
    'twitter',
    'linkedin',
    'whatsapp',
    'direct',
  ];

  final _formKey = GlobalKey<FormState>();
  final _baseUrlController = TextEditingController();
  final _utmSourceController = TextEditingController();
  final _mediumController = TextEditingController();

  String _referrerLinkType = 'plain';
  String _referrerLinkSource = 'facebook';
  String _selectedWebsiteRoutePath = 'none';

  static const _websiteRoutePathOptions = [
    'none',
    'pre-whatsapp',
    'pre-youtube',
    'pre-instagram',
    'pre-facebook',
    'gmb-review',
    'pre-website',
    'lnk',
  ];

  bool get _isWebsiteCampaign =>
      widget.campaignPlatform?.trim().toLowerCase() == 'website';

  static const Map<String, String> _routePathSourceMap = {
    'pre-whatsapp': 'whatsapp',
    'pre-youtube': 'youtube',
    'pre-instagram': 'instagram',
    'pre-facebook': 'facebook',
    'gmb-review': 'google',
    'pre-website': 'direct',
    'lnk': 'direct',
  };

  List<String> _referrerLinkSourceOptions([String? extraValue]) {
    final options = [..._baseReferrerLinkSourceOptions];
    final normalizedExtra = extraValue?.trim().toLowerCase();
    if (normalizedExtra != null &&
        normalizedExtra.isNotEmpty &&
        !options.contains(normalizedExtra)) {
      options.add(normalizedExtra);
    }
    return options;
  }

  String _normalizeUtmValue(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return trimmed;
    return trimmed.replaceAll(RegExp(r'\s+'), '_');
  }

  String _normalizePromoCode(String value) {
    return value.trim().replaceAll(RegExp(r'\s+'), '').toUpperCase();
  }

  void _onBaseUrlChanged() {
    final text = _baseUrlController.text.trim();
    final parsed = ParsedWebsiteUrl.parse(text);
    if (parsed.authority.isEmpty) return;

    var path = parsed.fragmentPath.trim();
    while (path.startsWith('/')) {
      path = path.substring(1);
    }
    while (path.endsWith('/')) {
      path = path.substring(0, path.length - 1);
    }

    final matchedOption = _websiteRoutePathOptions.contains(path)
        ? path
        : 'none';
    if (_selectedWebsiteRoutePath != matchedOption) {
      setState(() {
        _selectedWebsiteRoutePath = matchedOption;
      });
    }
  }

  void _updateWebsiteRoutePath(String value) {
    final text = _baseUrlController.text.trim();
    final parsed = ParsedWebsiteUrl.parse(text);

    final String newFragPath;
    if (value == 'none') {
      newFragPath = '/';
    } else {
      newFragPath = '/$value';
    }

    final bool newHasHash = (value != 'none') ? true : parsed.hasHash;

    final updatedParsed = ParsedWebsiteUrl(
      scheme: parsed.scheme,
      authority: parsed.authority,
      path: parsed.path,
      queryParameters: parsed.queryParameters,
      hasHash: newHasHash,
      fragmentPath: newFragPath,
      fragmentQueryParameters: parsed.fragmentQueryParameters,
    );

    final cleanUrl = updatedParsed.build(
      utmSource: '',
      utmCampaign: '',
      utmMedium: '',
    );

    final displayVal = _websiteFieldDisplayValue(cleanUrl);

    _baseUrlController.removeListener(_onBaseUrlChanged);
    _baseUrlController.text = displayVal;
    _baseUrlController.addListener(_onBaseUrlChanged);

    setState(() {
      _selectedWebsiteRoutePath = value;
      final mappedSource = _routePathSourceMap[value];
      if (mappedSource != null) {
        _referrerLinkSource = mappedSource;
      }
    });
  }

  String _normalizeWebsiteBaseUrl(String value) {
    final parsed = ParsedWebsiteUrl.parse(value);
    if (parsed.authority.isEmpty) return value.trim();

    return parsed.build(utmSource: '', utmCampaign: '', utmMedium: '');
  }

  String _websiteFieldDisplayValue(String value) {
    final parsed = ParsedWebsiteUrl.parse(value);
    if (parsed.authority.isEmpty) return value;

    final path = parsed.path.isEmpty ? '/' : parsed.path;
    final fragPart = parsed.fragmentPath.isEmpty
        ? ''
        : '#${parsed.fragmentPath}';

    final fragQuery = parsed.fragmentQueryParameters.isNotEmpty
        ? '?${Uri(queryParameters: parsed.fragmentQueryParameters).query}'
        : '';

    final mainQuery = parsed.queryParameters.isNotEmpty
        ? '?${Uri(queryParameters: parsed.queryParameters).query}'
        : '';

    return '${parsed.authority}$path$mainQuery$fragPart$fragQuery';
  }

  @override
  void initState() {
    super.initState();
    _baseUrlController.addListener(_onBaseUrlChanged);
    _populateFromExistingLink();
  }

  @override
  void dispose() {
    _baseUrlController.removeListener(_onBaseUrlChanged);
    _baseUrlController.dispose();
    _utmSourceController.dispose();
    _mediumController.dispose();
    super.dispose();
  }

  void _populateFromExistingLink() {
    final existingLink = widget.existingLink;
    final promoCode = widget.promoCode?.trim();
    final sourceOptions = _referrerLinkSourceOptions(
      widget.initialReferrerLinkSource,
    );

    if (_isWebsiteCampaign) {
      final savedWebsite = _normalizeWebsiteBaseUrl(widget.websiteUrl ?? '');
      if (savedWebsite.isNotEmpty) {
        _baseUrlController.text = _websiteFieldDisplayValue(savedWebsite);
      }
    }

    if (promoCode != null && promoCode.isNotEmpty) {
      _mediumController.text = _normalizePromoCode(promoCode);
    }

    final initialType = widget.initialReferrerLinkType?.trim().toLowerCase();
    if (initialType != null && _referrerLinkTypeOptions.contains(initialType)) {
      _referrerLinkType = initialType;
    }

    final initialSource = widget.initialReferrerLinkSource
        ?.trim()
        .toLowerCase();
    final hasInitialSource =
        initialSource != null &&
        initialSource.isNotEmpty &&
        sourceOptions.contains(initialSource);
    if (hasInitialSource) {
      _referrerLinkSource = initialSource;
    }

    if (existingLink == null || existingLink.isEmpty) return;

    final existingUri = Uri.tryParse(existingLink);
    if (existingUri == null) return;

    if (_isWebsiteCampaign) {
      final parsed = ParsedWebsiteUrl.parse(existingLink);

      final mainNonUtm = Map<String, String>.from(parsed.queryParameters)
        ..remove('utm_source')
        ..remove('utm_campaign')
        ..remove('utm_medium');
      final fragNonUtm =
          Map<String, String>.from(parsed.fragmentQueryParameters)
            ..remove('utm_source')
            ..remove('utm_campaign')
            ..remove('utm_medium');

      final cleanParsed = ParsedWebsiteUrl(
        scheme: parsed.scheme,
        authority: parsed.authority,
        path: parsed.path,
        queryParameters: mainNonUtm,
        hasHash: parsed.hasHash,
        fragmentPath: parsed.fragmentPath,
        fragmentQueryParameters: fragNonUtm,
      );

      _baseUrlController.text = _websiteFieldDisplayValue(
        cleanParsed.build(utmSource: '', utmCampaign: '', utmMedium: ''),
      );

      final existingUtmSource = parsed.hasHash
          ? parsed.fragmentQueryParameters['utm_source']
          : parsed.queryParameters['utm_source'];
      final existingUtmMedium = parsed.hasHash
          ? parsed.fragmentQueryParameters['utm_medium']
          : parsed.queryParameters['utm_medium'];

      final utmSource = _normalizeUtmValue(existingUtmSource ?? '');
      if (utmSource.isNotEmpty) {
        _utmSourceController.text = utmSource;
      }
      if (promoCode == null || promoCode.isEmpty) {
        _mediumController.text = _normalizeUtmValue(existingUtmMedium ?? '');
      }
      return;
    }

    final existingReferrer = existingUri.queryParameters['referrer'];
    if (existingReferrer == null || existingReferrer.isEmpty) return;

    try {
      final parts = Uri.splitQueryString(existingReferrer);
      final utmSource = _normalizeUtmValue(parts['utm_source'] ?? '');
      if (utmSource.isNotEmpty) {
        _utmSourceController.text = utmSource;
      }
      if (promoCode == null || promoCode.isEmpty) {
        _mediumController.text = _normalizeUtmValue(parts['utm_medium'] ?? '');
      }
    } catch (_) {}
  }

  String _buildPlayStorePreviewUrl() {
    final source = _normalizeUtmValue(_utmSourceController.text).isEmpty
        ? '<>'
        : _normalizeUtmValue(_utmSourceController.text);
    final mediumValue = widget.promoCode?.trim().isNotEmpty == true
        ? _normalizePromoCode(widget.promoCode!)
        : _normalizeUtmValue(_mediumController.text);
    final medium = mediumValue.isEmpty ? '<>' : mediumValue;
    final referrer = Uri.encodeComponent(
      'utm_source=$source&utm_campaign=${widget.campaignNameString}&utm_medium=$medium',
    );
    return 'https://play.google.com/store/apps/details?id=${widget.appId}&referrer=$referrer';
  }

  String _buildWebsitePreviewUrl() {
    final baseUrl = _normalizeWebsiteBaseUrl(_baseUrlController.text);
    if (baseUrl.isEmpty) return '';

    final parsed = ParsedWebsiteUrl.parse(baseUrl);
    if (parsed.authority.isEmpty) return '';

    final source = _normalizeUtmValue(_utmSourceController.text);
    final mediumValue = widget.promoCode?.trim().isNotEmpty == true
        ? _normalizePromoCode(widget.promoCode!)
        : _normalizeUtmValue(_mediumController.text);

    return parsed.build(
      utmSource: source,
      utmCampaign: widget.campaignNameString,
      utmMedium: mediumValue,
    );
  }

  String _buildPreviewUrl() {
    return _isWebsiteCampaign
        ? _buildWebsitePreviewUrl()
        : _buildPlayStorePreviewUrl();
  }

  String _displayOrPlaceholder(String? value) {
    final trimmed = value?.trim() ?? '';
    return trimmed.isEmpty ? '<>' : trimmed;
  }

  TextSpan _buildPlayStoreHighlightedLinkSpan(ThemeData theme) {
    final previewUrl = _buildPreviewUrl();
    final uri = Uri.tryParse(previewUrl);
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

    if (uri == null) {
      return TextSpan(text: previewUrl, style: baseStyle);
    }

    final referrer = uri.queryParameters['referrer'];
    if (referrer == null || referrer.isEmpty) {
      return TextSpan(text: previewUrl, style: baseStyle);
    }

    Map<String, String> parts;
    try {
      parts = Uri.splitQueryString(referrer);
    } catch (_) {
      return TextSpan(text: previewUrl, style: baseStyle);
    }

    return TextSpan(
      style: baseStyle,
      children: [
        const TextSpan(text: 'https://play.google.com/store/apps/details?id='),
        TextSpan(text: widget.appId, style: highlightStyle),
        const TextSpan(text: '&referrer='),
        const TextSpan(text: 'utm_source='),
        TextSpan(
          text: parts['utm_source']?.trim().isNotEmpty == true
              ? parts['utm_source']!.trim()
              : '<>',
          style: highlightStyle,
        ),
        const TextSpan(text: '&utm_campaign='),
        TextSpan(text: widget.campaignNameString, style: highlightStyle),
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

  TextSpan _buildWebsiteHighlightedLinkSpan(ThemeData theme) {
    final previewUrl = _buildWebsitePreviewUrl();
    final parsed = ParsedWebsiteUrl.parse(previewUrl);
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

    if (parsed.authority.isEmpty) {
      return TextSpan(text: previewUrl, style: baseStyle);
    }

    final bool useFragmentForUtm = parsed.hasHash;
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
      highlightedFragmentPath = parsed.fragmentPath;
      fragmentSuffix = fragQueryPart;
    } else {
      final queryPart = nonUtmQuery.isNotEmpty ? '?$nonUtmQuery' : '';
      basePath =
          '${parsed.scheme}://${parsed.authority}${parsed.path.isEmpty ? '/' : parsed.path}$queryPart';
      highlightedFragmentPath = null;
      fragmentSuffix = '';
    }

    final prefix = nonUtmQuery.isNotEmpty ? '&' : '?';

    return TextSpan(
      style: baseStyle,
      children: [
        TextSpan(text: basePath, style: baseStyle),
        if (highlightedFragmentPath != null)
          TextSpan(text: highlightedFragmentPath, style: highlightStyle),
        if (fragmentSuffix.isNotEmpty)
          TextSpan(text: fragmentSuffix, style: baseStyle),
        TextSpan(text: prefix),
        const TextSpan(text: 'utm_source='),
        TextSpan(
          text: _displayOrPlaceholder(targetParams['utm_source']),
          style: highlightStyle,
        ),
        const TextSpan(text: '&utm_campaign='),
        TextSpan(
          text: _displayOrPlaceholder(widget.campaignNameString),
          style: highlightStyle,
        ),
        const TextSpan(text: '&utm_medium='),
        TextSpan(
          text: _displayOrPlaceholder(
            targetParams['utm_medium']?.trim().isNotEmpty == true
                ? targetParams['utm_medium']
                : (widget.promoCode?.trim().isNotEmpty == true
                      ? _normalizePromoCode(widget.promoCode!)
                      : _normalizeUtmValue(_mediumController.text)),
          ),
          style: highlightStyle,
        ),
      ],
    );
  }

  TextSpan _buildHighlightedLinkSpan(ThemeData theme) {
    return _isWebsiteCampaign
        ? _buildWebsiteHighlightedLinkSpan(theme)
        : _buildPlayStoreHighlightedLinkSpan(theme);
  }

  Widget _buildWebsiteUrlField() {
    return TextFormField(
      controller: _baseUrlController,
      autofocus: true,
      decoration: InputDecoration(
        labelText: 'Website URL',
        hintText: 'numeroshastra.com/ or numeroshastra.com/lnk',
        border: const OutlineInputBorder(),
        helperText: 'Editable base URL for website campaigns',
        prefixIcon: const Icon(Icons.language_outlined),
      ),
      validator: (value) {
        final normalized = _normalizeWebsiteBaseUrl(value ?? '');
        if (normalized.isEmpty) {
          return 'Enter website URL';
        }
        final uri = Uri.tryParse(normalized);
        if (uri == null || uri.host.isEmpty || !uri.hasScheme) {
          return 'Enter a valid website URL';
        }
        return null;
      },
      onFieldSubmitted: (_) {
        final normalized = _normalizeWebsiteBaseUrl(_baseUrlController.text);
        if (normalized.isEmpty) return;
        setState(() {
          _baseUrlController.text = _websiteFieldDisplayValue(normalized);
        });
      },
      onChanged: (_) => setState(() {}),
    );
  }

  Widget _buildWebsiteRoutePathField(ThemeData theme) {
    return DropdownButtonFormField<String>(
      value: _selectedWebsiteRoutePath,
      decoration: const InputDecoration(
        labelText: 'Route Path (Fragment)',
        border: OutlineInputBorder(),
        helperText: 'Select fragment routing path to insert/replace in URL',
        prefixIcon: Icon(Icons.alt_route_outlined),
      ),
      items: _websiteRoutePathOptions
          .map(
            (value) =>
                DropdownMenuItem<String>(value: value, child: Text(value)),
          )
          .toList(),
      onChanged: (value) {
        if (value == null) return;
        _updateWebsiteRoutePath(value);
      },
    );
  }

  Widget _buildPlayStoreAppField() {
    return TextFormField(
      initialValue: widget.appId,
      readOnly: true,
      decoration: const InputDecoration(
        labelText: 'Android App ID',
        border: OutlineInputBorder(),
        helperText: 'Campaign app package ID',
        prefixIcon: Icon(Icons.android),
      ),
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final previewUrl = _buildPreviewUrl();
    if (previewUrl.isEmpty) return;

    Navigator.pop(
      context,
      ReferrerLinkFormResult(
        link: previewUrl,
        referrerLinkType: _referrerLinkType,
        referrerLinkSource: _referrerLinkSource,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEditing = widget.existingLink != null;
    final isMediumLocked =
        widget.promoCode != null && widget.promoCode!.trim().isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Referrer Link' : 'Add Referrer Link'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Generated Link',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withValues(
                      alpha: 0.35,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: theme.colorScheme.outlineVariant.withValues(
                        alpha: 0.7,
                      ),
                    ),
                  ),
                  child: SelectableText.rich(_buildHighlightedLinkSpan(theme)),
                ),
                const SizedBox(height: 16),
                Text(
                  'Campaign: ${widget.campaignNameString}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 20),
                if (_isWebsiteCampaign) ...[
                  _buildWebsiteRoutePathField(theme),
                  const SizedBox(height: 12),
                ] else ...[
                  _buildPlayStoreAppField(),
                  const SizedBox(height: 12),
                ],
                DropdownButtonFormField<String>(
                  value: _referrerLinkTypeOptions.contains(_referrerLinkType)
                      ? _referrerLinkType
                      : _referrerLinkTypeOptions.first,
                  decoration: const InputDecoration(
                    labelText: 'referrer_link_type',
                    border: OutlineInputBorder(),
                  ),
                  items: _referrerLinkTypeOptions
                      .map(
                        (value) => DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _referrerLinkType = value);
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value:
                      _referrerLinkSourceOptions(
                        _referrerLinkSource,
                      ).contains(_referrerLinkSource)
                      ? _referrerLinkSource
                      : _referrerLinkSourceOptions(_referrerLinkSource).first,
                  decoration: const InputDecoration(
                    labelText: 'referrer_link_source',
                    border: OutlineInputBorder(),
                  ),
                  items: _referrerLinkSourceOptions(_referrerLinkSource)
                      .map(
                        (value) => DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _referrerLinkSource = value);
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _utmSourceController,
                  autofocus: !_isWebsiteCampaign,
                  decoration: const InputDecoration(
                    labelText: 'utm_source',
                    hintText: 'instagram',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || _normalizeUtmValue(value).isEmpty) {
                      return 'Enter utm_source';
                    }
                    return null;
                  },
                  onChanged: (value) {
                    setState(() {});
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _mediumController,
                  readOnly: isMediumLocked,
                  decoration: InputDecoration(
                    labelText: 'utm_medium',
                    hintText: 'bio',
                    border: const OutlineInputBorder(),
                    helperText: isMediumLocked
                        ? 'Locked to collaboration promo code'
                        : null,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Enter utm_medium';
                    }
                    return null;
                  },
                  onChanged: isMediumLocked ? null : (_) => setState(() {}),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _submit,
                        icon: Icon(
                          isEditing ? Icons.save_outlined : Icons.link,
                        ),
                        label: Text(isEditing ? 'Update Link' : 'Save Link'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
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
      if (utmCampaign.isNotEmpty) {
        mergedFragmentQuery['utm_campaign'] = utmCampaign;
      }
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

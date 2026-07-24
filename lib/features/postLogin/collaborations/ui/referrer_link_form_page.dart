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

  bool get _isWebsiteCampaign =>
      widget.campaignPlatform?.trim().toLowerCase() == 'website';

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

  String _normalizeWebsiteFragment(String fragment) {
    var normalized = fragment;
    while (normalized.startsWith('#')) {
      normalized = normalized.substring(1);
    }
    return normalized;
  }

  String _normalizeWebsiteBaseUrl(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return '';

    final hasScheme =
        trimmed.startsWith('http://') || trimmed.startsWith('https://');
    final candidate = hasScheme ? trimmed : 'https://$trimmed';
    final hashIndex = candidate.indexOf('#');
    final candidateWithoutFragment = hashIndex < 0
        ? candidate
        : candidate.substring(0, hashIndex);
    final uri = Uri.tryParse(candidateWithoutFragment);
    if (uri == null || uri.host.isEmpty) return trimmed;

    // Do not auto-insert "www." — preserve the host exactly as provided by the user.

    // Keep non-empty fragments because Flutter web apps commonly use hash
    // routing (for example, `/#/review`). Build this portion directly so a
    // hash from the route is never encoded as `%23` or duplicated.
    final hasHash = hashIndex >= 0;
    final fragment = hasHash
        ? _normalizeWebsiteFragment(candidate.substring(hashIndex + 1))
        : '';
    final baseUrl = uri.replace(query: '').toString();
    return hasHash ? '$baseUrl#$fragment' : baseUrl;
  }

  String _websiteFieldDisplayValue(String value) {
    final normalized = _normalizeWebsiteBaseUrl(value);
    if (normalized.isEmpty) return '';

    final uri = Uri.tryParse(normalized);
    if (uri == null || uri.host.isEmpty) return normalized;

    final path = uri.path.isEmpty ? '/' : uri.path;
    final normalizedFragment = _normalizeWebsiteFragment(uri.fragment);
    final fragment = normalizedFragment.isEmpty ? '' : '#$normalizedFragment';
    return '${uri.host}$path$fragment';
  }

  @override
  void initState() {
    super.initState();
    _populateFromExistingLink();
  }

  @override
  void dispose() {
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
      var websiteFragment = _normalizeWebsiteFragment(existingUri.fragment);
      var params = existingUri.queryParameters;
      final fragmentQueryStart = websiteFragment.indexOf('?');
      if (fragmentQueryStart >= 0) {
        final encodedFragmentQuery = websiteFragment.substring(
          fragmentQueryStart + 1,
        );
        websiteFragment = websiteFragment.substring(0, fragmentQueryStart);
        try {
          params = Uri.splitQueryString(encodedFragmentQuery);
        } catch (_) {
          params = const <String, String>{};
        }
      }

      _baseUrlController.text = _websiteFieldDisplayValue(
        existingUri
            .replace(
              query: '',
              fragment: websiteFragment.isEmpty
                  ? null
                  : websiteFragment,
            )
            .toString(),
      );
      final utmSource = _normalizeUtmValue(params['utm_source'] ?? '');
      if (utmSource.isNotEmpty) {
        _utmSourceController.text = utmSource;
      }
      if (promoCode == null || promoCode.isEmpty) {
        _mediumController.text = _normalizeUtmValue(params['utm_medium'] ?? '');
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

    final baseUri = Uri.tryParse(baseUrl);
    if (baseUri == null || baseUri.host.isEmpty) return '';

    final source = _normalizeUtmValue(_utmSourceController.text);
    final mediumValue = widget.promoCode?.trim().isNotEmpty == true
        ? _normalizePromoCode(widget.promoCode!)
        : _normalizeUtmValue(_mediumController.text);

    final queryParameters = <String, String>{
      ...baseUri.queryParameters,
      'utm_source': source,
      'utm_campaign': widget.campaignNameString,
      'utm_medium': mediumValue,
    };

    final query = Uri(queryParameters: queryParameters).query;
    final baseWithoutQuery =
        '${baseUri.scheme}://${baseUri.authority}${baseUri.path}';
    final hasHash = baseUrl.contains('#');
    final hashIndex = baseUrl.indexOf('#');
    final fragment = hashIndex < 0
        ? ''
        : _normalizeWebsiteFragment(baseUrl.substring(hashIndex + 1));
    final result = hasHash
        ? '$baseWithoutQuery#$fragment?$query'
        : '$baseWithoutQuery?$query';
    return result.endsWith('#') ? result.substring(0, result.length - 1) : result;
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

    var fragmentPath = _normalizeWebsiteFragment(uri.fragment);
    var params = uri.queryParameters;
    final fragmentQueryStart = fragmentPath.indexOf('?');
    if (fragmentQueryStart >= 0) {
      final encodedFragmentQuery = fragmentPath.substring(
        fragmentQueryStart + 1,
      );
      fragmentPath = fragmentPath.substring(0, fragmentQueryStart);
      try {
        params = Uri.splitQueryString(encodedFragmentQuery);
      } catch (_) {
        params = const <String, String>{};
      }
    }

    final basePath =
        '${uri.scheme}://${uri.authority}${uri.path.isEmpty ? '/' : uri.path}'
        '${fragmentPath.isEmpty ? '' : '#$fragmentPath'}';

    return TextSpan(
      style: baseStyle,
      children: [
        TextSpan(text: basePath, style: baseStyle),
        const TextSpan(text: '?'),
        const TextSpan(text: 'utm_source='),
        TextSpan(
          text: _displayOrPlaceholder(params['utm_source']),
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
            params['utm_medium']?.trim().isNotEmpty == true
                ? params['utm_medium']
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
                  _buildWebsiteUrlField(),
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

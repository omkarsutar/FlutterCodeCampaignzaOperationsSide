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

    // Keep fragments (including '#' or '/#/' or '/#/review') directly without mangling.
    final fragment = hashIndex < 0
        ? null
        : candidate.substring(hashIndex + 1);
    final baseUrl = uri.replace(query: '').toString();
    return fragment == null ? baseUrl : '$baseUrl#$fragment';
  }

  String _websiteFieldDisplayValue(String value) {
    final normalized = _normalizeWebsiteBaseUrl(value);
    if (normalized.isEmpty) return '';

    final hashIndex = normalized.indexOf('#');
    final mainPart = hashIndex < 0 ? normalized : normalized.substring(0, hashIndex);
    final fragmentPart = hashIndex < 0 ? '' : normalized.substring(hashIndex);

    final uri = Uri.tryParse(mainPart);
    if (uri == null || uri.host.isEmpty) return normalized;

    final path = uri.path.isEmpty ? '/' : uri.path;
    return '${uri.host}$path$fragmentPart';
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
      final qIndex = existingLink.indexOf('?');
      final baseWithFragment = qIndex < 0
          ? existingLink
          : existingLink.substring(0, qIndex);
      final queryString = qIndex < 0 ? '' : existingLink.substring(qIndex + 1);

      Map<String, String> params = {};
      if (queryString.isNotEmpty) {
        try {
          params = Uri.splitQueryString(queryString);
        } catch (_) {}
      }

      _baseUrlController.text = _websiteFieldDisplayValue(baseWithFragment);

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

    final source = _normalizeUtmValue(_utmSourceController.text);
    final mediumValue = widget.promoCode?.trim().isNotEmpty == true
        ? _normalizePromoCode(widget.promoCode!)
        : _normalizeUtmValue(_mediumController.text);

    final hashIndex = baseUrl.indexOf('#');
    final mainPart = hashIndex < 0 ? baseUrl : baseUrl.substring(0, hashIndex);
    final fragmentPart = hashIndex < 0 ? '' : baseUrl.substring(hashIndex);

    final mainUri = Uri.tryParse(mainPart);
    if (mainUri == null || mainUri.host.isEmpty) return '';

    final existingParams = <String, String>{};
    existingParams.addAll(mainUri.queryParameters);

    final cleanMain = mainUri.replace(query: '').toString();

    var cleanFragment = fragmentPart;
    final fragQueryIndex = cleanFragment.indexOf('?');
    if (fragQueryIndex >= 0) {
      final fragQueryStr = cleanFragment.substring(fragQueryIndex + 1);
      cleanFragment = cleanFragment.substring(0, fragQueryIndex);
      try {
        existingParams.addAll(Uri.splitQueryString(fragQueryStr));
      } catch (_) {}
    }

    final queryParameters = <String, String>{
      ...existingParams,
      'utm_source': source,
      'utm_campaign': widget.campaignNameString,
      'utm_medium': mediumValue,
    };

    final queryStr = Uri(queryParameters: queryParameters).query;

    return '$cleanMain$cleanFragment?$queryStr';
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

    if (previewUrl.isEmpty) {
      return TextSpan(text: previewUrl, style: baseStyle);
    }

    final qIndex = previewUrl.indexOf('?');
    final basePath = qIndex < 0 ? previewUrl : previewUrl.substring(0, qIndex);
    final queryString = qIndex < 0 ? '' : previewUrl.substring(qIndex + 1);

    Map<String, String> params = {};
    if (queryString.isNotEmpty) {
      try {
        params = Uri.splitQueryString(queryString);
      } catch (_) {}
    }

    final source = params['utm_source'];
    final campaign = params['utm_campaign'] ?? widget.campaignNameString;
    final medium = params['utm_medium'] ??
        (widget.promoCode?.trim().isNotEmpty == true
            ? _normalizePromoCode(widget.promoCode!)
            : _normalizeUtmValue(_mediumController.text));

    return TextSpan(
      style: baseStyle,
      children: [
        TextSpan(text: basePath, style: baseStyle),
        const TextSpan(text: '?'),
        const TextSpan(text: 'utm_source='),
        TextSpan(
          text: _displayOrPlaceholder(source),
          style: highlightStyle,
        ),
        const TextSpan(text: '&utm_campaign='),
        TextSpan(
          text: _displayOrPlaceholder(campaign),
          style: highlightStyle,
        ),
        const TextSpan(text: '&utm_medium='),
        TextSpan(
          text: _displayOrPlaceholder(medium),
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
      decoration: const InputDecoration(
        labelText: 'Website URL',
        hintText: 'numeroshastra.com/ or numeroshastra.com/lnk',
        border: OutlineInputBorder(),
        helperText: 'Editable base URL for website campaigns',
        prefixIcon: Icon(Icons.language_outlined),
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

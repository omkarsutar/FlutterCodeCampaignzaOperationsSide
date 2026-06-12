import 'package:flutter/material.dart';

class ReferrerLinkFormPage extends StatefulWidget {
  final String appId;
  final String campaignNameString;
  final String? existingLink;

  const ReferrerLinkFormPage({
    super.key,
    required this.appId,
    required this.campaignNameString,
    this.existingLink,
  });

  @override
  State<ReferrerLinkFormPage> createState() => _ReferrerLinkFormPageState();
}

class _ReferrerLinkFormPageState extends State<ReferrerLinkFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _sourceController = TextEditingController();
  final _mediumController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _populateFromExistingLink();
  }

  @override
  void dispose() {
    _sourceController.dispose();
    _mediumController.dispose();
    super.dispose();
  }

  void _populateFromExistingLink() {
    final existingLink = widget.existingLink;
    if (existingLink == null || existingLink.isEmpty) return;

    final existingUri = Uri.tryParse(existingLink);
    final existingReferrer = existingUri?.queryParameters['referrer'];
    if (existingReferrer == null || existingReferrer.isEmpty) return;

    try {
      final parts = Uri.splitQueryString(existingReferrer);
      _sourceController.text = parts['utm_source'] ?? '';
      _mediumController.text = parts['utm_medium'] ?? '';
    } catch (_) {}
  }

  String _buildPreviewUrl() {
    final source = _sourceController.text.trim().isEmpty
        ? '<>'
        : _sourceController.text.trim();
    final medium = _mediumController.text.trim().isEmpty
        ? '<>'
        : _mediumController.text.trim();
    final referrer = Uri.encodeComponent(
      'utm_source=$source&utm_campaign=${widget.campaignNameString}&utm_medium=$medium',
    );
    return 'https://play.google.com/store/apps/details?id=${widget.appId}&referrer=$referrer';
  }

  TextSpan _buildHighlightedLinkSpan(ThemeData theme) {
    final previewUrl = _buildPreviewUrl();
    final uri = Uri.tryParse(previewUrl);
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
        const TextSpan(
          text: 'https://play.google.com/store/apps/details?id=',
        ),
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

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final previewUrl = _buildPreviewUrl();
    Navigator.pop(context, previewUrl);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEditing = widget.existingLink != null;

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
                    color: theme.colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: theme.colorScheme.outlineVariant.withValues(
                        alpha: 0.7,
                      ),
                    ),
                  ),
                  child: SelectableText.rich(
                    _buildHighlightedLinkSpan(theme),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _sourceController,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'utm_source',
                    hintText: 'instagram',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Enter utm_source';
                    }
                    return null;
                  },
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _mediumController,
                  decoration: const InputDecoration(
                    labelText: 'utm_medium',
                    hintText: 'bio',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Enter utm_medium';
                    }
                    return null;
                  },
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 12),
                Text(
                  'Campaign: ${widget.campaignNameString}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
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

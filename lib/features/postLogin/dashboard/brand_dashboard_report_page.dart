import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:flutter_supabase_order_app_mobile/features/postLogin/brands/providers/brand_providers.dart';
import 'package:flutter_supabase_order_app_mobile/shared/widgets/custom_drawer.dart';
import 'brand_dashboard_report_model.dart';

class _DateRange {
  final DateTime start;
  final DateTime end;

  const _DateRange({required this.start, required this.end});
}

class BrandDashboardReportPage extends ConsumerStatefulWidget {
  final String brandId;

  const BrandDashboardReportPage({super.key, required this.brandId});

  @override
  ConsumerState<BrandDashboardReportPage> createState() =>
      _BrandDashboardReportPageState();
}

class _BrandDashboardReportPageState
    extends ConsumerState<BrandDashboardReportPage> {
  late Future<BrandDashboardReport?> _reportFuture;
  late DateTime _startDate;
  late DateTime _endDate;
  String _selectedPreset = 'Last 30 days';
  String _selectedCampaignGroup = 'Direct';

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
    _startDate = _endDate.subtract(const Duration(days: 29));
    _reportFuture = _fetchBrandDashboardReport(
      startDate: _startDate,
      endDate: _endDate,
    );
  }

  Future<BrandDashboardReport?> _fetchBrandDashboardReport({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final response = await Supabase.instance.client.rpc(
        'get_brand_dashboard_report',
        params: {
          'p_brand_id': widget.brandId,
          'p_start_date': startDate.toIso8601String(),
          'p_end_date': endDate.toIso8601String(),
        },
      );

      return BrandDashboardReport.fromSupabaseResponse(response);
    } catch (error) {
      debugPrint('Error fetching brand dashboard report: $error');
      rethrow;
    }
  }

  _DateRange _dateRangeForPreset(String preset) {
    final now = DateTime.now();
    final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);
    late DateTime start;
    late DateTime end;

    switch (preset) {
      case 'Today':
        start = DateTime(now.year, now.month, now.day, 0, 0, 0);
        end = todayEnd;
        break;
      case 'Yesterday':
        final yesterday = now.subtract(const Duration(days: 1));
        start = DateTime(
          yesterday.year,
          yesterday.month,
          yesterday.day,
          0,
          0,
          0,
        );
        end = DateTime(
          yesterday.year,
          yesterday.month,
          yesterday.day,
          23,
          59,
          59,
        );
        break;
      case 'Last 7 days':
        end = todayEnd;
        start = end.subtract(const Duration(days: 6));
        start = DateTime(start.year, start.month, start.day, 0, 0, 0);
        break;
      default:
        end = todayEnd;
        start = end.subtract(const Duration(days: 29));
        start = DateTime(start.year, start.month, start.day, 0, 0, 0);
    }

    return _DateRange(start: start, end: end);
  }

  Future<void> _showDateRangeDialog(ThemeData theme) async {
    var draftStartDate = _startDate;
    var draftEndDate = _endDate;
    var draftPreset = _selectedPreset;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> pickStartDate() async {
              final picked = await showDatePicker(
                context: context,
                initialDate: draftStartDate,
                firstDate: DateTime(2020, 1, 1),
                lastDate: draftEndDate,
              );
              if (picked != null) {
                setDialogState(() {
                  draftStartDate = DateTime(
                    picked.year,
                    picked.month,
                    picked.day,
                  );
                  draftPreset = 'Custom';
                });
              }
            }

            Future<void> pickEndDate() async {
              final picked = await showDatePicker(
                context: context,
                initialDate: draftEndDate,
                firstDate: draftStartDate,
                lastDate: DateTime.now(),
              );
              if (picked != null) {
                setDialogState(() {
                  draftEndDate = DateTime(
                    picked.year,
                    picked.month,
                    picked.day,
                    23,
                    59,
                    59,
                  );
                  draftPreset = 'Custom';
                });
              }
            }

            void applyDialogPreset(String preset) {
              final range = _dateRangeForPreset(preset);
              setDialogState(() {
                draftPreset = preset;
                draftStartDate = range.start;
                draftEndDate = range.end;
              });
            }

            return AlertDialog(
              title: const Text('Select report dates'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildDateField(
                          theme,
                          'Start Date',
                          draftStartDate,
                          pickStartDate,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildDateField(
                          theme,
                          'End Date',
                          draftEndDate,
                          pickEndDate,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        'Today',
                        'Yesterday',
                        'Last 7 days',
                        'Last 30 days',
                      ].map((preset) {
                        final isSelected = preset == draftPreset;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(preset),
                            selected: isSelected,
                            onSelected: (_) => applyDialogPreset(preset),
                            selectedColor: theme.colorScheme.primary,
                            labelStyle: TextStyle(
                              color: isSelected
                                  ? theme.colorScheme.onPrimary
                                  : theme.colorScheme.onSurface,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Selected: $draftPreset',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _startDate = draftStartDate;
                      _endDate = draftEndDate;
                      _selectedPreset = draftPreset;
                      _reportFuture = _fetchBrandDashboardReport(
                        startDate: draftStartDate,
                        endDate: draftEndDate,
                      );
                    });
                    Navigator.of(dialogContext).pop();
                  },
                  child: const Text('Fetch Data'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _formatShortDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final day = date.day.toString().padLeft(2, '0');
    final month = months[date.month - 1];
    final year = date.year.toString();
    return '$day $month $year';
  }

  Map<String, List<CampaignMetrics>> _groupCampaignsByType(
    List<CampaignMetrics> campaigns,
  ) {
    final grouped = <String, List<CampaignMetrics>>{};
    for (final campaign in campaigns) {
      final type = campaign.campaignType.isNotEmpty
          ? campaign.campaignType
          : 'Unknown';
      grouped.putIfAbsent(type, () => []).add(campaign);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brandAsync = ref.watch(brandByIdProvider(widget.brandId));

    return Scaffold(
      drawer: const CustomDrawer(),
      appBar: AppBar(
        foregroundColor: Colors.white,
        title: brandAsync.maybeWhen(
          data: (brand) {
            final brandName = brand?.brandName ?? 'Brand';
            final brandPhotoUrl = brand?.brandPhotoUrl;

            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _BrandAvatar(
                  imageUrl: brandPhotoUrl,
                  size: 34,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        brandName,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
          orElse: () => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Brand',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        leading: const BackButton(),
      ),
      body: FutureBuilder<BrandDashboardReport?>(
        future: _reportFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return _ErrorView(
              message: snapshot.error.toString(),
              onRetry: () {
                setState(() {
                  _reportFuture = _fetchBrandDashboardReport(
                    startDate: _startDate,
                    endDate: _endDate,
                  );
                });
              },
            );
          }

          final report = snapshot.data;
          if (report == null) {
            return _ErrorView(
              message: 'No report data available.',
              onRetry: () {
                setState(() {
                  _reportFuture = _fetchBrandDashboardReport(
                    startDate: _startDate,
                    endDate: _endDate,
                  );
                });
              },
            );
          }

          return _buildReportView(context, theme, report);
        },
      ),
    );
  }

  Widget _buildDateField(
    ThemeData theme,
    String label,
    DateTime date,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.colorScheme.outline),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _formatShortDate(date),
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildCampaignGroups(
    ThemeData theme,
    BrandDashboardReport report,
  ) {
    final grouped = _groupCampaignsByType(_visibleCampaigns(report.campaigns));
    return grouped.entries.map((entry) {
      final campaigns = entry.value;
      final totalClicks = campaigns.fold<int>(
        0,
        (sum, c) => sum + c.totalClicks,
      );
      final totalInstalls = campaigns.fold<int>(
        0,
        (sum, c) => sum + c.totalInstalls,
      );
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    _campaignGroupDisplayName(entry.key),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  '${campaigns.length} campaigns',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _SummaryChip(
                  label: 'Clicks',
                  value: totalClicks.toString(),
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                _SummaryChip(
                  label: 'Installs',
                  value: totalInstalls.toString(),
                  color: theme.colorScheme.secondary,
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...campaigns.map(
              (campaign) => _CampaignCard(campaign: campaign, theme: theme),
            ),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildReportView(
    BuildContext context,
    ThemeData theme,
    BrandDashboardReport report,
  ) {
    final visibleCampaigns = _visibleCampaigns(report.campaigns);
    final totalClicks = report.campaigns.fold<int>(
      0,
      (sum, campaign) => sum + campaign.totalClicks,
    );
    final totalInstalls = report.campaigns.fold<int>(
      0,
      (sum, campaign) => sum + campaign.totalInstalls,
    );

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: _buildReportHeader(
            context,
            theme,
            report.campaigns.length,
            report.startDate,
            report.endDate,
            totalClicks,
            totalInstalls,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _buildCampaignGroupPills(theme, report),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              setState(() {
                _reportFuture = _fetchBrandDashboardReport(
                  startDate: _startDate,
                  endDate: _endDate,
                );
              });
              await _reportFuture;
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              children: [
                if (visibleCampaigns.isEmpty) ...[
                  SizedBox(
                    height: 220,
                    child: Center(
                      child: Text(
                        'No campaigns found for this period.',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  ),
                ] else ...[
                  ..._buildCampaignGroups(theme, report),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReportHeader(
    BuildContext context,
    ThemeData theme,
    int campaignCount,
    DateTime startDate,
    DateTime endDate,
    int totalClicks,
    int totalInstalls,
  ) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final reportTitleSize = screenWidth < 360
        ? 13.0
        : screenWidth < 600
            ? 15.0
            : 17.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Report for ${_formatShortDate(startDate)} - ${_formatShortDate(endDate)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontSize: reportTitleSize,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              tooltip: 'Select report dates',
              onPressed: () => _showDateRangeDialog(theme),
              icon: const Icon(Icons.calendar_month),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _SummaryCard(
              label: 'Campaigns',
              value: campaignCount.toString(),
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 12),
            _SummaryCard(
              label: 'Clicks',
              value: totalClicks.toString(),
              color: theme.colorScheme.secondary,
            ),
            const SizedBox(width: 12),
            _SummaryCard(
              label: 'Installs',
              value: totalInstalls.toString(),
              color: theme.colorScheme.tertiary,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCampaignGroupPills(ThemeData theme, BrandDashboardReport report) {
    final counts = _campaignGroupCounts(report.campaigns);
    const groups = ['Direct', 'Paid Ads', 'Collabs'];

    // If the currently selected group has no campaigns, fall back to the first
    // visible group. Prefer 'Direct' for selection; otherwise pick 'Paid Ads'.
    final visibleGroups = groups.where((g) => (counts[g] ?? 0) > 0).toList();
    if (!visibleGroups.contains(_selectedCampaignGroup)) {
      final fallback = visibleGroups.isNotEmpty
          ? visibleGroups.first
          : groups.first;
      if (fallback != _selectedCampaignGroup) {
        Future.microtask(() {
          if (!mounted) return;
          setState(() {
            _selectedCampaignGroup = fallback;
          });
        });
      }
    }

    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: groups.length,
        itemBuilder: (context, index) {
          final group = groups[index];
          final isSelected = group == _selectedCampaignGroup;
          final count = counts[group] ?? 0;

          Color pillColor;
          switch (group.toLowerCase()) {
            case 'paid ads':
              pillColor = Colors.blue;
              break;
            case 'direct':
              pillColor = Colors.green;
              break;
            case 'collabs':
              pillColor = Colors.orange;
              break;
            default:
              pillColor = theme.colorScheme.primary;
          }

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(
                '$group ($count)',
                style: TextStyle(
                  color: isSelected ? Colors.white : pillColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              selected: isSelected,
              onSelected: (_) {
                setState(() {
                  _selectedCampaignGroup = group;
                });
              },
              selectedColor: pillColor,
              backgroundColor: pillColor.withValues(alpha: 0.1),
              checkmarkColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: pillColor, width: isSelected ? 0 : 1),
              ),
              showCheckmark: false,
            ),
          );
        },
      ),
    );
  }

  List<CampaignMetrics> _filteredCampaigns(List<CampaignMetrics> campaigns) {
    return campaigns
        .where(
          (campaign) =>
              _campaignGroupKey(campaign).toLowerCase() ==
              _selectedCampaignGroup.toLowerCase(),
        )
        .toList();
  }

  Map<String, int> _campaignGroupCounts(List<CampaignMetrics> campaigns) {
    final counts = <String, int>{
      'Paid Ads': 0,
      'Direct': 0,
      'Collabs': 0,
    };

    for (final campaign in campaigns) {
      final group = _campaignGroupKey(campaign);
      if (counts.containsKey(group)) {
        counts[group] = counts[group]! + 1;
      }
    }

    return counts;
  }

  List<CampaignMetrics> _visibleCampaigns(List<CampaignMetrics> campaigns) {
    return _filteredCampaigns(campaigns);
  }

  String _campaignGroupKey(CampaignMetrics campaign) {
    final type = campaign.campaignType.trim().toLowerCase();

    if (type.contains('paid')) return 'Paid Ads';
    if (type.contains('direct')) return 'Direct';
    if (type.contains('collab') || type.contains('influencer')) return 'Collabs';

    return 'Collabs';
  }

  String _campaignGroupDisplayName(String groupKey) {
    switch (groupKey) {
      case 'Paid Ads':
        return 'Paid Ads';
      case 'Direct':
        return 'Direct Brand Promotion';
      case 'Collabs':
        return 'Influencer Collaborations';
      default:
        return groupKey;
    }
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                softWrap: false,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _BrandAvatar extends StatelessWidget {
  final String? imageUrl;
  final double size;

  const _BrandAvatar({required this.imageUrl, required this.size});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (imageUrl != null && imageUrl!.isNotEmpty) {
      final encodedUrl = Uri.encodeFull(Uri.decodeFull(imageUrl!));
      return ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.25),
        child: SizedBox(
          width: size,
          height: size,
          child: CachedNetworkImage(
            imageUrl: encodedUrl,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              color: Colors.white.withValues(alpha: 0.18),
              child: const Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
            errorWidget: (context, url, error) => _fallback(theme),
          ),
        ),
      );
    }

    return _fallback(theme);
  }

  Widget _fallback(ThemeData theme) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(size * 0.25),
      ),
      child: const Icon(Icons.storefront_rounded, color: Colors.white),
    );
  }
}

class _CampaignCard extends StatelessWidget {
  final CampaignMetrics campaign;
  final ThemeData theme;

  const _CampaignCard({required this.campaign, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        collapsedShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        childrenPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        title: Text(
          campaign.campaignName.isNotEmpty
              ? campaign.campaignName
              : 'Unnamed campaign',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Text(
          '${campaign.campaignType} · ${campaign.campaignPlatform}',
          style: theme.textTheme.bodySmall,
        ),
        children: [
          Row(
            children: [
              _MetricChip(
                label: 'Clicks',
                value: campaign.totalClicks.toString(),
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              _MetricChip(
                label: 'Installs',
                value: campaign.totalInstalls.toString(),
                color: theme.colorScheme.secondary,
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...campaign.referrerLinks.map(
            (link) => _ReferrerLinkRow(link: link, theme: theme),
          ),
        ],
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _SummaryChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text('$label: $value'),
      backgroundColor: color.withValues(alpha: 0.14),
      labelStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: color,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MetricChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text('$label: $value'),
      backgroundColor: color.withValues(alpha: 0.14),
      labelStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: color,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _ReferrerLinkRow extends StatelessWidget {
  final LinkMetrics link;
  final ThemeData theme;

  const _ReferrerLinkRow({required this.link, required this.theme});

  String _decodeForDisplay(String value) {
    var decoded = value;
    // A Play Store referrer is nested inside a query parameter and can be
    // encoded more than once. Decode only for display; the stored link stays
    // untouched for tracking and copy/open actions.
    for (var i = 0; i < 3; i++) {
      try {
        final next = Uri.decodeComponent(decoded);
        if (next == decoded) break;
        decoded = next;
      } catch (_) {
        break;
      }
    }
    return decoded;
  }

  TextSpan _buildKeyValueSpan(
    String value,
    TextStyle baseStyle,
    TextStyle highlightStyle,
  ) {
    final matches = RegExp(
      r'(utm_source|utm_campaign|utm_medium)=',
    ).allMatches(value).toList();

    if (matches.isEmpty) {
      return TextSpan(text: value, style: baseStyle);
    }

    final spans = <InlineSpan>[];
    var cursor = 0;
    for (final match in matches) {
      if (match.start > cursor) {
        spans.add(TextSpan(text: value.substring(cursor, match.start)));
      }

      final valueStart = match.end;
      var valueEnd = value.length;
      for (final delimiter in ['&', '|']) {
        final delimiterIndex = value.indexOf(delimiter, valueStart);
        if (delimiterIndex >= 0 && delimiterIndex < valueEnd) {
          valueEnd = delimiterIndex;
        }
      }

      spans.add(TextSpan(text: value.substring(match.start, valueStart)));
      spans.add(
        TextSpan(
          text: value.substring(valueStart, valueEnd),
          style: highlightStyle,
        ),
      );
      cursor = valueEnd;
    }

    if (cursor < value.length) {
      spans.add(TextSpan(text: value.substring(cursor)));
    }

    return TextSpan(style: baseStyle, children: spans);
  }

  TextSpan _buildHighlightedLinkSpan() {
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
    final uri = Uri.tryParse(link.linkString);
    final referrer = uri?.queryParameters['referrer'];
    final isPlayStoreLink =
        uri != null &&
        uri.host.contains('play.google.com') &&
        referrer?.isNotEmpty == true;

    if (isPlayStoreLink) {
      try {
        final parts = Uri.splitQueryString(referrer!);
        final appId = _decodeForDisplay(uri.queryParameters['id'] ?? '');
        final spans = <InlineSpan>[
          TextSpan(
            text:
                '${uri.scheme}://${uri.authority}${uri.path.isEmpty ? '/store/apps/details' : uri.path}?id=',
          ),
          TextSpan(text: appId, style: highlightStyle),
          const TextSpan(text: '&referrer='),
        ];

        var isFirst = true;
        for (final entry in parts.entries) {
          if (!isFirst) spans.add(const TextSpan(text: '&'));
          isFirst = false;
          spans.add(TextSpan(text: '${entry.key}='));
          spans.add(
            TextSpan(
              text: _decodeForDisplay(entry.value),
              style: highlightStyle,
            ),
          );
        }
        return TextSpan(style: baseStyle, children: spans);
      } catch (_) {
        // Fall through to the decoded generic renderer for malformed links.
      }
    }

    return _buildKeyValueSpan(
      _decodeForDisplay(link.linkString),
      baseStyle,
      highlightStyle,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${link.linkSource} · ${link.linkType}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          SelectableText.rich(
            _buildHighlightedLinkSpan(),
            style: theme.textTheme.bodySmall?.copyWith(
              fontFamily: 'monospace',
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Clicks: ${link.clicks} · Installs: ${link.installs}',
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

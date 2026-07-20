import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:flutter_supabase_order_app_mobile/features/postLogin/brands/model/brand_model.dart';
import 'package:flutter_supabase_order_app_mobile/features/postLogin/brands/providers/brand_providers.dart';
import 'package:flutter_supabase_order_app_mobile/shared/widgets/custom_drawer.dart';
import 'brand_dashboard_report_model.dart';

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

  void _applyPreset(String preset) {
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

    setState(() {
      _selectedPreset = preset;
      _startDate = start;
      _endDate = end;
    });
  }

  Future<void> _pickStartDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020, 1, 1),
      lastDate: _endDate,
    );
    if (picked != null) {
      setState(() {
        _startDate = DateTime(picked.year, picked.month, picked.day, 0, 0, 0);
        _selectedPreset = 'Custom';
      });
    }
  }

  Future<void> _pickEndDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: _startDate,
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _endDate = DateTime(picked.year, picked.month, picked.day, 23, 59, 59);
        _selectedPreset = 'Custom';
      });
    }
  }

  String _formatDate(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
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
        title: const Text('Brand Dashboard'),
        leading: const BackButton(),
      ),
      body: Column(
        children: [
          _buildDateControls(theme),
          Expanded(
            child: FutureBuilder<BrandDashboardReport?>(
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

                return _buildReportView(context, theme, report, brandAsync);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateControls(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: _buildDateField(
                  theme,
                  'Start Date',
                  _startDate,
                  () => _pickStartDate(context),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDateField(
                  theme,
                  'End Date',
                  _endDate,
                  () => _pickEndDate(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(children: [..._buildPresetButtons(theme)]),
          ),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Selected: $_selectedPreset',
                  style: theme.textTheme.bodySmall,
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _reportFuture = _fetchBrandDashboardReport(
                      startDate: _startDate,
                      endDate: _endDate,
                    );
                  });
                },
                child: const Text('Fetch Data'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
        ],
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
              _formatDate(date),
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildPresetButtons(ThemeData theme) {
    const presets = ['Today', 'Yesterday', 'Last 7 days', 'Last 30 days'];
    return presets.map((preset) {
      final isSelected = preset == _selectedPreset;
      return ChoiceChip(
        label: Text(preset),
        selected: isSelected,
        onSelected: (_) {
          _applyPreset(preset);
        },
        selectedColor: theme.colorScheme.primary,
        backgroundColor: theme.colorScheme.surfaceContainerHighest,
        labelStyle: TextStyle(
          color: isSelected
              ? theme.colorScheme.onPrimary
              : theme.colorScheme.onSurface,
        ),
      );
    }).toList();
  }

  List<Widget> _buildCampaignGroups(
    ThemeData theme,
    BrandDashboardReport report,
  ) {
    final grouped = _groupCampaignsByType(report.campaigns);
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
                    entry.key,
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
    AsyncValue<ModelBrand?> brandAsync,
  ) {
    final totalClicks = report.campaigns.fold<int>(
      0,
      (sum, campaign) => sum + campaign.totalClicks,
    );
    final totalInstalls = report.campaigns.fold<int>(
      0,
      (sum, campaign) => sum + campaign.totalInstalls,
    );

    final brandName = brandAsync.maybeWhen(
      data: (brand) => brand?.brandName ?? 'Brand',
      orElse: () => 'Brand',
    );

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            brandName,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Report for ${report.startDate.toLocal().toString().split(' ').first} - ${report.endDate.toLocal().toString().split(' ').first}',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          Expanded(
            child: report.campaigns.isEmpty
                ? Center(
                    child: Text(
                      'No campaigns found for this period.',
                      style: theme.textTheme.bodyMedium,
                    ),
                  )
                : ListView(
                    children: [
                      Row(
                        children: [
                          _SummaryCard(
                            label: 'Campaigns',
                            value: report.campaigns.length.toString(),
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
                      const SizedBox(height: 16),
                      ..._buildCampaignGroups(theme, report),
                    ],
                  ),
          ),
        ],
      ),
    );
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
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
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
          Text(
            link.linkString,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../shared/widgets/custom_drawer.dart';

String _dashboardRoleTitle(String role) {
  switch (role) {
    case 'admin':
      return 'Admin Overview';
    case 'agency_manager':
    case 'agency':
      return 'Agency Manager';
    case 'influencer':
      return 'Influencer Overview';
    case 'brand':
      return 'Brand Overview';
    default:
      return 'Platform Overview';
  }
}

String _dashboardRoleSubtitle(String role) {
  switch (role) {
    case 'admin':
      return 'High-level operational counts across the platform.';
    case 'agency_manager':
    case 'agency':
      return 'Campaign and collaboration activity for your agency.';
    case 'influencer':
      return 'Your collaboration pipeline at a glance.';
    case 'brand':
      return 'Brand-side campaign and link generation metrics.';
    default:
      return 'A quick snapshot of your current workspace.';
  }
}

IconData _dashboardHeroIcon(String role) {
  switch (role) {
    case 'admin':
      return Icons.admin_panel_settings_rounded;
    case 'agency_manager':
    case 'agency':
      return Icons.apartment_rounded;
    case 'influencer':
      return Icons.person_rounded;
    case 'brand':
      return Icons.storefront_rounded;
    default:
      return Icons.dashboard_rounded;
  }
}

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  late Future<Map<String, dynamic>> _dashboardFuture;

  @override
  void initState() {
    super.initState();
    _dashboardFuture = _fetchDashboardData();
  }

  Future<Map<String, dynamic>> _fetchDashboardData() async {
    final response =
        await Supabase.instance.client.rpc('get_dashboard_highlights');
    return Map<String, dynamic>.from(response as Map);
  }

  Future<void> _refresh() async {
    final future = _fetchDashboardData();
    setState(() {
      _dashboardFuture = future;
    });
    await future;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      drawer: const CustomDrawer(),
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _refresh,
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _dashboardFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return _DashboardErrorState(
              message: snapshot.error.toString(),
              onRetry: _refresh,
            );
          }

          final data = snapshot.data;
          if (data == null) {
            return _DashboardErrorState(
              message: 'No dashboard data returned.',
              onRetry: _refresh,
            );
          }

          if (data['error'] != null) {
            return _DashboardErrorState(
              message: data['error'].toString(),
              onRetry: _refresh,
            );
          }

          final role = (data['role']?.toString() ?? 'unknown').toLowerCase();
          final metrics = _roleMetrics(role, data);

          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.surface,
                  theme.colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.65,
                  ),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _DashboardHeroCard(role: role, data: data),
                  const SizedBox(height: 16),
                  _SectionHeader(
                    title: _dashboardRoleTitle(role),
                    subtitle: _dashboardRoleSubtitle(role),
                  ),
                  const SizedBox(height: 12),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: metrics.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 1.15,
                    ),
                    itemBuilder: (context, index) {
                      final metric = metrics[index];
                      return _MetricCard(
                        title: metric.title,
                        value: metric.value,
                        icon: metric.icon,
                        tint: metric.tint,
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  _ContextCard(
                    title: 'Session Context',
                    items: [
                      _ContextRow(
                        'Role',
                        _dashboardRoleTitle(role).replaceAll(' Overview', ''),
                      ),
                      if (data['total_campaigns'] != null)
                        _ContextRow(
                          'Total Campaigns',
                          data['total_campaigns'].toString(),
                        ),
                      if (data['active_campaigns'] != null)
                        _ContextRow(
                          'Active Campaigns',
                          data['active_campaigns'].toString(),
                        ),
                      if (data['total_collaborations'] != null)
                        _ContextRow(
                          'Collaborations',
                          data['total_collaborations'].toString(),
                        ),
                      if (data['total_brands'] != null)
                        _ContextRow(
                          'Brands',
                          data['total_brands'].toString(),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  List<_DashboardMetric> _roleMetrics(String role, Map<String, dynamic> data) {
    switch (role) {
      case 'admin':
        return [
          _DashboardMetric(
            title: 'Agencies',
            value: data['total_agencies']?.toString() ?? '0',
            icon: Icons.apartment_rounded,
            tint: Colors.indigo,
          ),
          _DashboardMetric(
            title: 'Brands',
            value: data['total_brands']?.toString() ?? '0',
            icon: Icons.storefront_rounded,
            tint: Colors.teal,
          ),
          _DashboardMetric(
            title: 'Influencers',
            value: data['total_influencers']?.toString() ?? '0',
            icon: Icons.groups_rounded,
            tint: Colors.deepOrange,
          ),
          _DashboardMetric(
            title: 'Campaigns',
            value: data['total_campaigns']?.toString() ?? '0',
            icon: Icons.campaign_rounded,
            tint: Colors.green,
          ),
        ];
      case 'agency_manager':
      case 'agency':
        return [
          _DashboardMetric(
            title: 'Active Campaigns',
            value: data['active_campaigns']?.toString() ?? '0',
            icon: Icons.local_fire_department_rounded,
            tint: Colors.orange,
          ),
          _DashboardMetric(
            title: 'Collaborations',
            value: data['total_collaborations']?.toString() ?? '0',
            icon: Icons.handshake_rounded,
            tint: Colors.blue,
          ),
          _DashboardMetric(
            title: 'Brands',
            value: data['total_brands']?.toString() ?? '0',
            icon: Icons.link_rounded,
            tint: Colors.purple,
          ),
          _DashboardMetric(
            title: 'Role',
            value: 'Agency Manager',
            icon: Icons.badge_rounded,
            tint: Colors.teal,
          ),
        ];
      case 'influencer':
        return [
          _DashboardMetric(
            title: 'Collaborations',
            value: data['total_collaborations']?.toString() ?? '0',
            icon: Icons.handshake_rounded,
            tint: Colors.blue,
          ),
          _DashboardMetric(
            title: 'Pending',
            value: data['pending_proposals']?.toString() ?? '0',
            icon: Icons.hourglass_bottom_rounded,
            tint: Colors.amber,
          ),
          _DashboardMetric(
            title: 'Role',
            value: 'Influencer',
            icon: Icons.person_rounded,
            tint: Colors.deepPurple,
          ),
          _DashboardMetric(
            title: 'Status',
            value: 'Live',
            icon: Icons.bolt_rounded,
            tint: Colors.green,
          ),
        ];
      case 'brand':
        return [
          _DashboardMetric(
            title: 'Campaigns',
            value: data['total_campaigns']?.toString() ?? '0',
            icon: Icons.campaign_rounded,
            tint: Colors.green,
          ),
          _DashboardMetric(
            title: 'Links',
            value: data['total_links_generated']?.toString() ?? '0',
            icon: Icons.link_rounded,
            tint: Colors.indigo,
          ),
          _DashboardMetric(
            title: 'Role',
            value: 'Brand',
            icon: Icons.store_rounded,
            tint: Colors.orange,
          ),
          _DashboardMetric(
            title: 'Status',
            value: 'Ready',
            icon: Icons.check_circle_rounded,
            tint: Colors.teal,
          ),
        ];
      default:
        return [
          _DashboardMetric(
            title: 'Role',
            value: role.isEmpty ? 'unknown' : role,
            icon: Icons.person_search_rounded,
            tint: Colors.blueGrey,
          ),
        ];
    }
  }
}

class _DashboardHeroCard extends StatelessWidget {
  final String role;
  final Map<String, dynamic> data;

  const _DashboardHeroCard({required this.role, required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.tertiary,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.22),
            blurRadius: 22,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(
              _dashboardHeroIcon(role),
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _dashboardRoleTitle(role),
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  _heroSubtitle(role, data),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.88),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _heroSubtitle(String role, Map<String, dynamic> data) {
    switch (role) {
      case 'admin':
        return 'Platform-wide visibility across agencies, brands, influencers, and campaigns.';
      case 'agency_manager':
      case 'agency':
        return 'You have ${data['active_campaigns']?.toString() ?? '0'} active campaigns and ${data['total_collaborations']?.toString() ?? '0'} collaborations in motion.';
      case 'influencer':
        return 'You have ${data['total_collaborations']?.toString() ?? '0'} collaborations and ${data['pending_proposals']?.toString() ?? '0'} pending proposals.';
      case 'brand':
        return 'Your brand has ${data['total_campaigns']?.toString() ?? '0'} campaigns and ${data['total_links_generated']?.toString() ?? '0'} links generated.';
      default:
        return 'Your metrics will appear here once the dashboard context is resolved.';
    }
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _DashboardMetric {
  final String title;
  final String value;
  final IconData icon;
  final Color tint;

  const _DashboardMetric({
    required this.title,
    required this.value,
    required this.icon,
    required this.tint,
  });
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color tint;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.tint,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.55),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: tint.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: tint, size: 18),
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              maxLines: 1,
              softWrap: false,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
          const SizedBox(height: 1),
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}

class _ContextCard extends StatelessWidget {
  final String title;
  final List<Widget> items;

  const _ContextCard({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.55),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          ...items,
        ],
      ),
    );
  }
}

class _ContextRow extends StatelessWidget {
  final String label;
  final String value;

  const _ContextRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardErrorState extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _DashboardErrorState({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 56,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 12),
            Text(
              'Dashboard unavailable',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => onRetry(),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class BrandDashboardReport {
  final String brandId;
  final DateTime startDate;
  final DateTime endDate;
  final List<CampaignMetrics> campaigns;

  BrandDashboardReport({
    required this.brandId,
    required this.startDate,
    required this.endDate,
    required this.campaigns,
  });

  factory BrandDashboardReport.fromJson(Map<String, dynamic> json) {
    return BrandDashboardReport(
      brandId: json['brand_id']?.toString() ?? '',
      startDate: DateTime.parse(json['start_date']?.toString() ?? ''),
      endDate: DateTime.parse(json['end_date']?.toString() ?? ''),
      campaigns: (json['campaigns'] as List? ?? [])
          .map(
            (e) =>
                CampaignMetrics.fromJson(Map<String, dynamic>.from(e as Map)),
          )
          .toList(),
    );
  }

  static BrandDashboardReport? fromSupabaseResponse(dynamic response) {
    if (response == null) return null;

    if (response is List && response.isNotEmpty) {
      final first = response.first;
      if (first is Map && first.containsKey('get_brand_dashboard_report')) {
        final payload = first['get_brand_dashboard_report'];
        if (payload is Map) {
          return BrandDashboardReport.fromJson(
            Map<String, dynamic>.from(payload),
          );
        }
      }
    }

    if (response is Map) {
      if (response.containsKey('get_brand_dashboard_report')) {
        final payload = response['get_brand_dashboard_report'];
        if (payload is Map) {
          return BrandDashboardReport.fromJson(
            Map<String, dynamic>.from(payload),
          );
        }
      }

      return BrandDashboardReport.fromJson(Map<String, dynamic>.from(response));
    }

    return null;
  }
}

class CampaignMetrics {
  final String campaignId;
  final String campaignName;
  final String campaignType;
  final String campaignPlatform;
  final int totalClicks;
  final int totalInstalls;
  final List<LinkMetrics> referrerLinks;

  CampaignMetrics({
    required this.campaignId,
    required this.campaignName,
    required this.campaignType,
    required this.campaignPlatform,
    required this.totalClicks,
    required this.totalInstalls,
    required this.referrerLinks,
  });

  factory CampaignMetrics.fromJson(Map<String, dynamic> json) {
    return CampaignMetrics(
      campaignId: json['campaign_id']?.toString() ?? '',
      campaignName: json['campaign_name']?.toString() ?? '',
      campaignType: json['campaign_type']?.toString() ?? '',
      campaignPlatform: json['campaign_platform']?.toString() ?? '',
      totalClicks: json['total_clicks'] is int
          ? json['total_clicks'] as int
          : int.tryParse(json['total_clicks']?.toString() ?? '') ?? 0,
      totalInstalls: json['total_installs'] is int
          ? json['total_installs'] as int
          : int.tryParse(json['total_installs']?.toString() ?? '') ?? 0,
      referrerLinks: (json['referrer_links'] as List? ?? [])
          .map((e) => LinkMetrics.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
    );
  }
}

class LinkMetrics {
  final String linkId;
  final String linkString;
  final String linkType;
  final String linkSource;
  final int clicks;
  final int installs;

  LinkMetrics({
    required this.linkId,
    required this.linkString,
    required this.linkType,
    required this.linkSource,
    required this.clicks,
    required this.installs,
  });

  factory LinkMetrics.fromJson(Map<String, dynamic> json) {
    return LinkMetrics(
      linkId: json['link_id']?.toString() ?? '',
      linkString: json['link_string']?.toString() ?? '',
      linkType: json['link_type']?.toString() ?? '',
      linkSource: json['link_source']?.toString() ?? '',
      clicks: json['clicks'] is int
          ? json['clicks'] as int
          : int.tryParse(json['clicks']?.toString() ?? '') ?? 0,
      installs: json['installs'] is int
          ? json['installs'] as int
          : int.tryParse(json['installs']?.toString() ?? '') ?? 0,
    );
  }
}

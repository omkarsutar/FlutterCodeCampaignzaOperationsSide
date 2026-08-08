import 'dart:ui' as ui;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/rendering.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_supabase_order_app_mobile/core/utils/file_save_helper.dart';
import 'package:flutter_supabase_order_app_mobile/features/postLogin/brands/providers/brand_providers.dart';
import '../../../../core/config/module_config.dart';
import 'package:flutter_supabase_order_app_mobile/features/postLogin/campaigns/campaign_barrel.dart';
import 'package:flutter_supabase_order_app_mobile/shared/widgets/shared_widget_barrel.dart';
import 'package:flutter_supabase_order_app_mobile/core/utils/snackbar_utils.dart';
import 'package:flutter_supabase_order_app_mobile/core/utils/dialogs.dart';
import '../providers/collaboration_providers.dart';
import '../providers/collaboration_list_controller.dart';
import 'collaboration_add_card.dart';
import '../../cart/ui/cart_item_card.dart';
import '../../campaigns/ui/widgets/referrer_link_tile.dart';
import 'referrer_link_form_page.dart';
import '../../referrer_links/providers/referrer_link_providers.dart';
import '../../referrer_links/model/referrer_link_model.dart';

class CollaborationListPageRiverpod extends ConsumerStatefulWidget {
  final String poId;
  final String entityLabel;
  final String viewRouteName;
  final String newRouteName;
  final SortingConfig? initialSorting;

  const CollaborationListPageRiverpod({
    super.key,
    required this.poId,
    required this.entityLabel,
    required this.viewRouteName,
    required this.newRouteName,
    this.initialSorting,
  });

  @override
  ConsumerState<CollaborationListPageRiverpod> createState() =>
      _CollaborationListPageRiverpodState();
}

class _CollaborationListPageRiverpodState
    extends ConsumerState<CollaborationListPageRiverpod> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    // Set sorting configuration once when widget is created
    if (widget.initialSorting != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final service = ref.read(collaborationServiceProvider);
        service.setSortingConfig(
          widget.initialSorting!.field,
          widget.initialSorting!.sortAscending,
        );
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _showReferrerLinkPage(
    BuildContext context,
    WidgetRef ref,
    ModelCampaign campaign, {
    String? existingLink,
    ModelReferrerLink? existingLinkItem,
  }) async {
    dynamic parentBrand;
    try {
      final brandId = campaign.campaignBrandId ?? campaign.poBrandId;
      if (brandId != null && brandId.isNotEmpty) {
        parentBrand = await ref.read(brandByIdProvider(brandId).future);
      }
    } catch (_) {
      parentBrand = null;
    }
    final appId = parentBrand?.androidAppId?.toString().trim();
    final resolvedAppId = (appId != null && appId.isNotEmpty)
        ? appId
        : 'com.numeroshastra.client';
    final campaignNameString =
        (campaign.campaignNameString ??
                campaign.campaignName ??
                campaign.poId ??
                '')
            .trim();

    final result = await Navigator.of(context).push<ReferrerLinkFormResult>(
      MaterialPageRoute(
        builder: (_) => ReferrerLinkFormPage(
          appId: resolvedAppId,
          campaignNameString: campaignNameString,
          campaignPlatform: campaign.campaignPlatform,
          websiteUrl: parentBrand?.websiteUrl?.toString().trim(),
          existingLink: existingLink,
          initialReferrerLinkType: existingLinkItem?.referrerLinkType,
          initialReferrerLinkSource: existingLinkItem?.referrerLinkSource,
        ),
      ),
    );
    if (!context.mounted) return;

    if (result == null || result.link.isEmpty) return;

    final uri = Uri.tryParse(result.link);
    if (uri == null || !(uri.hasScheme && uri.host.isNotEmpty)) {
      SnackbarUtils.showError('Please enter a valid URL');
      return;
    }

    try {
      final service = ref.read(campaignServiceProvider);
      if (existingLink == null) {
        await service.addReferrerLink(
          campaignId: campaign.poId!,
          referrerLink: result.link,
          referrerLinkType: result.referrerLinkType,
          referrerLinkSource: result.referrerLinkSource,
        );
      } else {
        await service.updateReferrerLink(
          campaignId: campaign.poId!,
          oldReferrerLink: existingLink,
          newReferrerLink: result.link,
          referrerLinkType: result.referrerLinkType,
          referrerLinkSource: result.referrerLinkSource,
        );
      }
      ref.invalidate(campaignByIdProvider(campaign.poId!));
      ref.invalidate(campaignStreamByIdProvider(campaign.poId!));
      ref.invalidate(referrerLinksForCampaignProvider(campaign.poId!));
      SnackbarUtils.showSuccess(
        existingLink == null
            ? 'Referrer link added successfully!'
            : 'Referrer link updated successfully!',
      );
    } catch (e) {
      SnackbarUtils.showError('Failed to save referrer link: $e');
    }
  }

  Future<void> _deleteReferrerLink(
    BuildContext context,
    WidgetRef ref,
    ModelCampaign campaign,
    String existingLink,
  ) async {
    final confirmed = await showConfirmDeleteWithTextDialog(
      context: context,
      title: 'Delete Referrer Link',
      content: 'Are you sure you want to delete this referrer link?',
      entityNameLower: 'referrer link',
    );

    if (!confirmed) return;

    try {
      await ref
          .read(campaignServiceProvider)
          .deleteReferrerLink(
            campaignId: campaign.poId!,
            referrerLink: existingLink,
          );
      ref.invalidate(campaignByIdProvider(campaign.poId!));
      ref.invalidate(campaignStreamByIdProvider(campaign.poId!));
      ref.invalidate(referrerLinksForCampaignProvider(campaign.poId!));
      SnackbarUtils.showSuccess('Referrer link deleted successfully!');
    } catch (e) {
      SnackbarUtils.showError('Failed to delete referrer link: $e');
    }
  }

  Widget _buildCampaignHeader(BuildContext context, ModelCampaign campaign) {
    return CampaignListTile(
      entity: campaign,
      adapter: ref.read(campaignAdapterProvider),
      onTap: null,
      collaborationTile: true,
    );
  }

  Widget? _buildReferrerLinkQrWidget(
    ModelReferrerLink linkItem, {
    String? brandPhotoUrl,
  }) {
    final typeLower = linkItem.referrerLinkType.trim().toLowerCase();
    final isQrType =
        typeLower == 'qrcode' ||
        typeLower == 'branded qrcode' ||
        typeLower == 'branded_qrcode' ||
        typeLower == 'branded-qrcode';
    if (!isQrType) return null;

    final rawLink = linkItem.referrerLinkString.trim();
    if (rawLink.isEmpty) return null;

    var qrData = rawLink;
    try {
      final uri = Uri.tryParse(rawLink);
      if (uri != null) {
        qrData = uri.replace(fragment: null).toString();
        if (qrData.endsWith('#')) {
          qrData = qrData.substring(0, qrData.length - 1);
        }
      }
    } catch (_) {}

    final isBranded = typeLower.contains('branded');
    final String? logoAssetUrl = brandPhotoUrl?.trim();
    String assetFallback = 'assets/images/google_logo.webp';
    if (logoAssetUrl == null || logoAssetUrl.isEmpty) {
      final source = linkItem.referrerLinkSource.trim().toLowerCase();
      switch (source) {
        case 'facebook':
          assetFallback = 'assets/images/facebook_logo.webp';
          break;
        case 'instagram':
          assetFallback = 'assets/images/instagram_logo.webp';
          break;
        case 'whatsapp':
          assetFallback = 'assets/images/whatsapp_logo.webp';
          break;
        case 'youtube':
          assetFallback = 'assets/images/youtube_logo.webp';
          break;
        case 'google':
        case 'direct':
        case 'tiktok':
        case 'twitter':
        case 'linkedin':
        default:
          assetFallback = 'assets/images/google_logo.webp';
      }
    }

    return _QrShareBlock(
      data: qrData,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black12),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            QrImageView(
              data: qrData,
              version: QrVersions.auto,
              size: 180,
              backgroundColor: Colors.white,
              gapless: false,
              errorCorrectionLevel: QrErrorCorrectLevel.M,
            ),
            if (isBranded)
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.all(6),
                child: (logoAssetUrl != null && logoAssetUrl.isNotEmpty)
                    ? Image.network(logoAssetUrl, fit: BoxFit.contain)
                    : Image.asset(assetFallback, fit: BoxFit.contain),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCollaborationBody(
    AsyncValue<CollaborationListState> asyncState,
    ModelCampaign campaign,
  ) {
    return Column(
      children: [
        Expanded(
          child: CustomScrollView(
            controller: _scrollController,
            slivers: [
              SliverToBoxAdapter(
                child: _buildCampaignHeader(context, campaign),
              ),
              const SliverToBoxAdapter(child: Divider()),
              asyncState.when(
                loading: () => const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (error, stackTrace) => SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Error: $error'),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            ref.invalidate(
                              collaborationListControllerProvider(widget.poId),
                            );
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ),
                data: (state) {
                  if (state.items.isEmpty) {
                    return SliverFillRemaining(
                      child: Center(
                        child: Text('No items found. Add one below.'),
                      ),
                    );
                  }
                  return SliverPadding(
                    padding: const EdgeInsets.only(bottom: 20),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final item = state.items[index];
                        return CartItemCard(
                          key: ValueKey(item.collaborationId),
                          entity: item,
                          influencers: state.influencers,
                          isReadOnly: false,
                          lastModifiedId: state.lastModifiedItemId,
                          poId: widget.poId,
                        );
                      }, childCount: state.items.length),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        if (asyncState.value?.isNewItemAdded != true)
          CollaborationAddCard(
            influencers: asyncState.value?.influencers ?? [],
            poId: widget.poId,
          ),
      ],
    );
  }

  Widget _buildReferrerLinksBody(ModelCampaign campaign) {
    final linksAsync = ref.watch(
      referrerLinksForCampaignProvider(campaign.poId!),
    );
    final AsyncValue<dynamic> brandAsync =
        (campaign.campaignBrandId != null &&
            campaign.campaignBrandId!.isNotEmpty)
        ? ref.watch(brandByIdProvider(campaign.campaignBrandId!))
        : const AsyncValue.data(null);

    return Column(
      children: [
        Expanded(
          child: CustomScrollView(
            controller: _scrollController,
            slivers: [
              SliverToBoxAdapter(
                child: _buildCampaignHeader(context, campaign),
              ),
              const SliverToBoxAdapter(child: Divider()),
              linksAsync.when(
                loading: () => const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (err, stack) => SliverFillRemaining(
                  child: Center(child: Text('Error loading links: $err')),
                ),
                data: (links) {
                  if (links.isEmpty) {
                    return const SliverFillRemaining(
                      child: Center(
                        child: Text('No referrer links yet. Add one below.'),
                      ),
                    );
                  }
                  return SliverPadding(
                    padding: const EdgeInsets.only(bottom: 20),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final linkItem = links[index];
                        final link = linkItem.referrerLinkString;
                        final brand = brandAsync.value;
                        return ReferrerLinkTile(
                          link: link,
                          campaignPlatform: campaign.campaignPlatform,
                          referrerLinkSource: linkItem.referrerLinkSource,
                          belowLinkWidget: _buildReferrerLinkQrWidget(
                            linkItem,
                            brandPhotoUrl: brand?.brandPhotoUrl?.toString(),
                          ),
                          onEdit: (existingLink) => _showReferrerLinkPage(
                            context,
                            ref,
                            campaign,
                            existingLink: existingLink,
                            existingLinkItem: linkItem,
                          ),
                          onDelete: (existingLink) => _deleteReferrerLink(
                            context,
                            ref,
                            campaign,
                            existingLink,
                          ),
                        );
                      }, childCount: links.length),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                textStyle: const TextStyle(fontWeight: FontWeight.w700),
              ),
              onPressed: () => _showReferrerLinkPage(context, ref, campaign),
              icon: const Icon(Icons.link),
              label: const Text('Add Referrer Link'),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGlobalCollaborationsBody(
    AsyncValue<CollaborationListState> asyncState,
  ) {
    return asyncState.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Error loading collaborations: $error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () =>
                  ref.invalidate(collaborationListControllerProvider('')),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
      data: (state) {
        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(collaborationListControllerProvider(''));
            await ref.read(collaborationListControllerProvider('').future);
          },
          child: state.items.isEmpty
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: const [
                    SizedBox(height: 120),
                    Center(child: Text('No collaborations found.')),
                  ],
                )
              : ListView.builder(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: state.items.length,
                  itemBuilder: (context, index) {
                    final item = state.items[index];
                    return CartItemCard(
                      key: ValueKey(item.collaborationId),
                      entity: item,
                      influencers: state.influencers,
                      isReadOnly: true,
                      lastModifiedId: state.lastModifiedItemId,
                      poId: item.campaignId,
                    );
                  },
                ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isGlobalView = widget.poId.isEmpty;
    final campaignAsync = widget.poId.isNotEmpty
        ? ref.watch(campaignStreamByIdProvider(widget.poId))
        : null;
    final pageTitle =
        campaignAsync?.maybeWhen(
          loading: () => 'Loading Campaign...',
          error: (_, __) => 'Campaign Details',
          data: (campaign) {
            if (campaign == null) return 'Campaign Details';
            return campaign.effectiveCampaignType.isInfluencerCollaboration
                ? '${widget.entityLabel}s for PO'
                : 'Referrer Links';
          },
          orElse: () => 'Campaign Details',
        ) ??
        'All Collaborations';
    final globalAsync = isGlobalView
        ? ref.watch(collaborationListControllerProvider(''))
        : null;

    return Scaffold(
      appBar: CustomAppBar(title: pageTitle, showBack: widget.poId.isNotEmpty),
      drawer: const CustomDrawer(),
      body: isGlobalView
          ? _buildGlobalCollaborationsBody(globalAsync!)
          : campaignAsync!.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Error loading campaign: $error'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => ref.invalidate(
                        campaignStreamByIdProvider(widget.poId),
                      ),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
              data: (campaign) {
                if (campaign == null) {
                  return const Center(child: Text('Campaign not found'));
                }

                final isCollaborationCampaign =
                    campaign.effectiveCampaignType.isInfluencerCollaboration;

                if (isCollaborationCampaign) {
                  final asyncState = ref.watch(
                    collaborationListControllerProvider(widget.poId),
                  );
                  return _buildCollaborationBody(asyncState, campaign);
                }

                return _buildReferrerLinksBody(campaign);
              },
            ),
    );
  }
}

class _QrShareBlock extends StatefulWidget {
  final String data;
  final Widget child;

  const _QrShareBlock({required this.data, required this.child});

  @override
  State<_QrShareBlock> createState() => _QrShareBlockState();
}

class _QrShareBlockState extends State<_QrShareBlock> {
  final GlobalKey _boundaryKey = GlobalKey();

  String _getFileName() {
    try {
      final uri = Uri.tryParse(widget.data);
      if (uri != null) {
        final utmSource = uri.queryParameters['utm_source']?.trim();
        if (utmSource != null && utmSource.isNotEmpty) {
          final sanitized = utmSource.replaceAll(RegExp(r'[^\w\-_]'), '_');
          return '$sanitized.png';
        }
      }
    } catch (_) {}
    return 'referrer_qr.png';
  }

  Future<void> _handleQrAction() async {
    try {
      final boundary =
          _boundaryKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) return;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      final pngBytes = byteData.buffer.asUint8List();
      final fileName = _getFileName();

      if (kIsWeb) {
        await UniversalFileSaver.saveAndDownloadFile(
          bytes: pngBytes,
          fileName: fileName,
        );
        SnackbarUtils.showSuccess('QR Code downloaded successfully!');
        return;
      }

      await Share.shareXFiles([
        XFile.fromData(pngBytes, name: fileName, mimeType: 'image/png'),
      ], subject: 'Referrer QR Code');
    } catch (e) {
      if (mounted) {
        SnackbarUtils.showError('Could not process QR Code: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        RepaintBoundary(key: _boundaryKey, child: widget.child),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _handleQrAction,
          icon: Icon(kIsWeb ? Icons.download_outlined : Icons.share_outlined),
          label: Text(kIsWeb ? 'Download QR Code' : 'Share QR Code'),
        ),
      ],
    );
  }
}

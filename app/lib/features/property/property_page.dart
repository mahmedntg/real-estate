import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/config.dart';
import '../../core/format.dart';
import '../../core/labels.dart';
import '../../core/session.dart';
import '../../core/ui.dart';
import '../../data/api.dart';
import '../../data/models.dart';
import '../../l10n/generated/app_localizations.dart';
import '../chats/chats_controller.dart';
import '../favorites/favorites_controller.dart';
import '../home/home_controller.dart';
import '../listings/my_listings_controller.dart';
import 'property_controller.dart';
import 'property_video.dart';

class PropertyPage extends ConsumerStatefulWidget {
  const PropertyPage({super.key, required this.id});

  final String id;

  @override
  ConsumerState<PropertyPage> createState() => _PropertyPageState();
}

class _PropertyPageState extends ConsumerState<PropertyPage> {
  final _pageController = PageController();
  int _imageIndex = 0;
  bool? _favoriteOverride;
  bool _busy = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _toggleFavorite(PropertyDetail detail) async {
    if (!ref.read(isSignedInProvider)) {
      await context.push(
        '/login?from=${Uri.encodeComponent('/property/${widget.id}')}',
      );
      return;
    }
    final next = !(_favoriteOverride ?? detail.favorite);
    setState(() => _favoriteOverride = next);
    try {
      await ref.read(apiProvider).setFavorite(detail.id, next);
      ref.invalidate(favoritesProvider);
      ref.read(homeControllerProvider.notifier).markFavorite(detail.id, next);
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _favoriteOverride = !next);
      showErrorSnack(context, error);
    }
  }

  Future<void> _startChat(PropertyDetail detail) async {
    if (!ref.read(isSignedInProvider)) {
      await context.push(
        '/login?from=${Uri.encodeComponent('/property/${widget.id}')}',
      );
      return;
    }
    final localizations = AppLocalizations.of(context);
    final controller = TextEditingController(
      text: localizations.startChatGreeting,
    );
    final message = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(localizations.startingChatTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(localizations.startingChatHint),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              autofocus: true,
              minLines: 2,
              maxLines: 4,
              maxLength: 2000,
              decoration: InputDecoration(hintText: localizations.messageHint),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(localizations.cancel),
          ),
          FilledButton(
            onPressed: () {
              final text = controller.text.trim();
              if (text.isNotEmpty) {
                Navigator.of(context).pop(text);
              }
            },
            child: Text(localizations.startChat),
          ),
        ],
      ),
    );
    controller.dispose();
    if (message == null || !mounted) {
      return;
    }
    setState(() => _busy = true);
    try {
      final conversation = await ref
          .read(apiProvider)
          .startConversation(detail.id, message);
      ref.invalidate(chatsProvider);
      if (!mounted) {
        return;
      }
      setState(() => _busy = false);
      context.push('/chats/${conversation.id}');
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _busy = false);
      showErrorSnack(context, error);
    }
  }

  Future<void> _edit() async {
    final saved = await context.push<bool>('/listings/${widget.id}/edit');
    if (saved == true && mounted) {
      ref.invalidate(propertyProvider(widget.id));
      ref.invalidate(myListingsProvider);
      ref.read(homeControllerProvider.notifier).refresh();
    }
  }

  Future<void> _delete(PropertyDetail detail) async {
    final localizations = AppLocalizations.of(context);
    final confirmed = await confirmDialog(
      context,
      title: localizations.deleteListingTitle,
      body: localizations.deleteListingBody,
      confirmLabel: localizations.delete,
    );
    if (!confirmed || !mounted) {
      return;
    }
    setState(() => _busy = true);
    try {
      await ref.read(apiProvider).deleteProperty(detail.id);
      ref.invalidate(myListingsProvider);
      ref.invalidate(favoritesProvider);
      await ref.read(homeControllerProvider.notifier).refresh();
      if (!mounted) {
        return;
      }
      context.pop();
      showMessageSnack(context, localizations.listingDeleted);
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _busy = false);
      showErrorSnack(context, error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncDetail = ref.watch(propertyProvider(widget.id));
    final detail = asyncDetail.value;

    if (detail == null && asyncDetail.hasError) {
      return Scaffold(
        appBar: AppBar(),
        body: ErrorView(
          error: asyncDetail.error,
          onRetry: () => ref.invalidate(propertyProvider(widget.id)),
        ),
      );
    }
    if (detail == null) {
      return const Scaffold(body: LoadingView());
    }
    return _PropertyScaffold(
      detail: detail,
      favorite: _favoriteOverride ?? detail.favorite,
      busy: _busy,
      imageIndex: _imageIndex,
      pageController: _pageController,
      onImageChanged: (index) => setState(() => _imageIndex = index),
      onFavorite: () => _toggleFavorite(detail),
      onMessage: () => _startChat(detail),
      onEdit: _edit,
      onDelete: () => _delete(detail),
    );
  }
}

class _PropertyScaffold extends ConsumerWidget {
  const _PropertyScaffold({
    required this.detail,
    required this.favorite,
    required this.busy,
    required this.imageIndex,
    required this.pageController,
    required this.onImageChanged,
    required this.onFavorite,
    required this.onMessage,
    required this.onEdit,
    required this.onDelete,
  });

  final PropertyDetail detail;
  final bool favorite;
  final bool busy;
  final int imageIndex;
  final PageController pageController;
  final ValueChanged<int> onImageChanged;
  final VoidCallback onFavorite;
  final VoidCallback onMessage;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final localizations = AppLocalizations.of(context);
    final catalog = ref.watch(locationsProvider).value;
    final country = catalog?.byCode(detail.countryCode);
    final governorate = catalog?.governorate(country, detail.governorateCode);
    final title = localizedTitle(
      context,
      en: detail.titleEn,
      ar: detail.titleAr,
    );

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 320,
            actions: [
              if (!detail.mine)
                IconButton.filledTonal(
                  tooltip:
                      favorite ? localizations.unfavorite : localizations.favorite,
                  onPressed: onFavorite,
                  icon: Icon(
                    favorite ? Icons.favorite : Icons.favorite_border,
                    color: favorite ? colors.error : null,
                  ),
                ),
              if (detail.mine) ...[
                IconButton.filledTonal(
                  tooltip: localizations.editListing,
                  onPressed: busy ? null : onEdit,
                  icon: const Icon(Icons.edit_outlined),
                ),
                IconButton.filledTonal(
                  tooltip: localizations.delete,
                  onPressed: busy ? null : onDelete,
                  icon: Icon(Icons.delete_outline, color: colors.error),
                ),
              ],
              const SizedBox(width: 8),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  if (detail.images.isEmpty)
                    const AppNetworkImage('')
                  else
                    PageView.builder(
                      controller: pageController,
                      itemCount: detail.images.length,
                      onPageChanged: onImageChanged,
                      itemBuilder: (context, index) => AppNetworkImage(
                        mediaUrl(detail.images[index].url),
                      ),
                    ),
                  if (detail.images.length > 1) ...[
                    PositionedDirectional(
                      start: 8,
                      top: 0,
                      bottom: 0,
                      child: Center(
                        child: _GalleryArrow(
                          icon: Icons.chevron_left,
                          tooltip: localizations.previousImage,
                          onPressed: imageIndex == 0
                              ? null
                              : () => pageController.previousPage(
                                    duration:
                                        const Duration(milliseconds: 250),
                                    curve: Curves.easeOut,
                                  ),
                        ),
                      ),
                    ),
                    PositionedDirectional(
                      end: 8,
                      top: 0,
                      bottom: 0,
                      child: Center(
                        child: _GalleryArrow(
                          icon: Icons.chevron_right,
                          tooltip: localizations.nextImage,
                          onPressed: imageIndex == detail.images.length - 1
                              ? null
                              : () => pageController.nextPage(
                                    duration:
                                        const Duration(milliseconds: 250),
                                    curve: Curves.easeOut,
                                  ),
                        ),
                      ),
                    ),
                  ],
                  if (detail.images.length > 1)
                    PositionedDirectional(
                      bottom: 16,
                      start: 0,
                      end: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          for (var index = 0; index < detail.images.length; index++)
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              width: index == imageIndex ? 18 : 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: index == imageIndex
                                    ? colors.onPrimary
                                    : colors.onPrimary.withValues(alpha: 0.6),
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _Tag(
                        label: listingTypeLabel(
                          localizations,
                          detail.listingType,
                        ),
                        background: colors.primary,
                        foreground: colors.onPrimary,
                      ),
                      _Tag(
                        label: propertyTypeLabel(
                          localizations,
                          detail.propertyType,
                        ),
                        background: colors.secondaryContainer,
                        foreground: colors.onSecondaryContainer,
                      ),
                      if (detail.landKind != null)
                        _Tag(
                          label: landKindLabel(localizations, detail.landKind!),
                          background: colors.surfaceContainerHighest,
                          foreground: colors.onSurfaceVariant,
                        ),
                      if (detail.negotiable)
                        _Tag(
                          label: localizations.negotiableBadge,
                          background: colors.tertiaryContainer,
                          foreground: colors.onTertiaryContainer,
                        ),
                      if (detail.furnished)
                        _Tag(
                          label: localizations.furnished,
                          background: colors.tertiaryContainer,
                          foreground: colors.onTertiaryContainer,
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    title,
                    style: theme.textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.place_outlined,
                        size: 18,
                        color: colors.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          [
                            governorateLabel(
                              context,
                              governorate,
                              detail.governorateCode,
                            ),
                            if (detail.areaCode != null)
                              areaLabel(
                                context,
                                catalog?.area(governorate, detail.areaCode),
                                detail.areaCode!,
                              ),
                          ].join(' · '),
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(color: colors.onSurfaceVariant),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    listingPrice(
                      context,
                      detail.price,
                      detail.listingType,
                      currencySymbol:
                          country?.currencySymbol(localizations.localeName),
                    ),
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: colors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (detail.bedrooms != null ||
                      detail.bathrooms != null ||
                      detail.areaSqm != null ||
                      detail.areaQirats != null ||
                      (detail.frontageM != null && detail.depthM != null) ||
                      detail.streetWidthM != null ||
                      detail.buildingPermit != null) ...[
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (detail.bedrooms != null)
                          _InfoPill(
                            icon: Icons.bed_outlined,
                            label: localizations
                                .bedroomsShort(detail.bedrooms!),
                          ),
                        if (detail.bathrooms != null)
                          _InfoPill(
                            icon: Icons.bathtub_outlined,
                            label: localizations
                                .bathroomsShort(detail.bathrooms!),
                          ),
                        if (detail.areaQirats != null)
                          _InfoPill(
                            icon: Icons.landscape_outlined,
                            label: qiratsLabel(context, detail.areaQirats!),
                          )
                        else if (detail.areaSqm != null)
                          _InfoPill(
                            icon: Icons.square_foot,
                            label: localizations.areaShort(
                              formatArea(context, detail.areaSqm!),
                            ),
                          ),
                        if (detail.frontageM != null && detail.depthM != null)
                          _InfoPill(
                            icon: Icons.straighten,
                            label: localizations.dimensionsShort(
                              formatArea(context, detail.frontageM!),
                              formatArea(context, detail.depthM!),
                            ),
                          ),
                        if (detail.streetWidthM != null)
                          _InfoPill(
                            icon: Icons.add_road,
                            label: localizations.streetWidthShort(
                              formatArea(context, detail.streetWidthM!),
                            ),
                          ),
                        if (detail.buildingPermit != null)
                          _InfoPill(
                            icon: detail.buildingPermit!
                                ? Icons.verified_outlined
                                : Icons.block_outlined,
                            label: detail.buildingPermit!
                                ? localizations.permitAvailable
                                : localizations.permitMissing,
                          ),
                      ],
                    ),
                  ],
                  if (detail.boundaryNorth != null ||
                      detail.boundarySouth != null ||
                      detail.boundaryEast != null ||
                      detail.boundaryWest != null) ...[
                    const SizedBox(height: 20),
                    Text(
                      localizations.boundaries,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    for (final line in [
                      (localizations.boundaryNorth, detail.boundaryNorth),
                      (localizations.boundarySouth, detail.boundarySouth),
                      (localizations.boundaryEast, detail.boundaryEast),
                      (localizations.boundaryWest, detail.boundaryWest),
                    ])
                      if (line.$2 != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: 132,
                                child: Text(
                                  line.$1,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colors.onSurfaceVariant,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  line.$2!,
                                  style: theme.textTheme.bodyMedium,
                                ),
                              ),
                            ],
                          ),
                        ),
                  ],
                  if (detail.videoUrl != null &&
                      detail.videoUrl!.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Text(
                      localizations.video,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 10),
                    PropertyVideo(url: mediaUrl(detail.videoUrl!)),
                  ],
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),
                  Text(
                    localizations.description,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    localizedTitle(
                      context,
                      en: detail.descriptionEn,
                      ar: detail.descriptionAr,
                    ),
                    style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
                  ),
                  const SizedBox(height: 24),
                  if (detail.mine)
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: colors.secondaryContainer,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: colors.onSecondaryContainer,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              localizations.thisIsYourListing,
                              style: TextStyle(
                                color: colors.onSecondaryContainer,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: busy ? null : onEdit,
                            child: Text(localizations.edit),
                          ),
                        ],
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: colors.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 22,
                            backgroundColor: colors.primaryContainer,
                            child: Text(
                              initialOf(detail.owner.fullName),
                              style: TextStyle(
                                color: colors.onPrimaryContainer,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  detail.owner.fullName,
                                  style: theme.textTheme.titleSmall
                                      ?.copyWith(fontWeight: FontWeight.w600),
                                ),
                                Text(
                                  localizations.owner,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colors.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          FilledButton.icon(
                            onPressed: busy ? null : onMessage,
                            icon: busy
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.chat_bubble_outline),
                            label: Text(localizations.messageOwner),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({
    required this.label,
    required this.background,
    required this.foreground,
  });

  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: foreground,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
}

class _GalleryArrow extends StatelessWidget {
  const _GalleryArrow({
    required this.icon,
    required this.tooltip,
    this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => IconButton.filled(
        onPressed: onPressed,
        tooltip: tooltip,
        style: IconButton.styleFrom(
          backgroundColor: Colors.black.withValues(alpha: 0.4),
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.black.withValues(alpha: 0.15),
          disabledForegroundColor: Colors.white38,
        ),
        icon: Icon(icon),
      );
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: colors.onSurfaceVariant),
          const SizedBox(width: 6),
          Text(label),
        ],
      ),
    );
  }
}

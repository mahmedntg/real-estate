import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/config.dart';
import '../../core/format.dart';
import '../../core/labels.dart';
import '../../core/ui.dart';
import '../../data/api.dart';
import '../../data/models.dart';
import '../../l10n/generated/app_localizations.dart';
import '../favorites/favorites_controller.dart';
import '../home/home_controller.dart';
import 'my_listings_controller.dart';

class MyListingsPage extends ConsumerWidget {
  const MyListingsPage({super.key});

  Future<void> _openEditor(
    BuildContext context,
    WidgetRef ref,
    String id,
  ) async {
    final saved = await context.push<bool>('/listings/$id/edit');
    if (saved == true) {
      ref.invalidate(myListingsProvider);
    }
  }

  Future<void> _create(BuildContext context, WidgetRef ref) async {
    final saved = await context.push<bool>('/listings/new');
    if (saved == true) {
      ref.invalidate(myListingsProvider);
    }
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    PropertySummary property,
  ) async {
    final localizations = AppLocalizations.of(context);
    final confirmed = await confirmDialog(
      context,
      title: localizations.deleteListingTitle,
      body: localizations.deleteListingBody,
      confirmLabel: localizations.delete,
    );
    if (!confirmed) {
      return;
    }
    try {
      await ref.read(apiProvider).deleteProperty(property.id);
      ref.invalidate(myListingsProvider);
      ref.invalidate(favoritesProvider);
      await ref.read(homeControllerProvider.notifier).refresh();
      if (context.mounted) {
        showMessageSnack(context, localizations.listingDeleted);
      }
    } catch (error) {
      if (context.mounted) {
        showErrorSnack(context, error);
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localizations = AppLocalizations.of(context);
    final listings = ref.watch(myListingsProvider);
    final items = listings.value;
    final catalog = ref.watch(locationsProvider).value;

    final Widget body;
    if (items == null && listings.hasError) {
      body = ErrorView(
        error: listings.error,
        onRetry: () => ref.invalidate(myListingsProvider),
      );
    } else if (items == null) {
      body = const LoadingView();
    } else if (items.isEmpty) {
      body = EmptyView(
        icon: Icons.home_work_outlined,
        title: localizations.myListings,
        body: localizations.myListingsEmpty,
        actionLabel: localizations.newListing,
        onAction: () => _create(context, ref),
      );
    } else {
      body = RefreshIndicator(
        onRefresh: () async {
          try {
            final listings = ref.refresh(myListingsProvider.future);
            await listings;
          } catch (_) {
            // Rendered through the provider error state.
          }
        },
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
          itemCount: items.length,
          separatorBuilder: (context, index) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final property = items[index];
            return Card(
              margin: EdgeInsets.zero,
              elevation: 0,
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
              child: InkWell(
                onTap: () => context.push('/property/${property.id}'),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: SizedBox(
                          width: 84,
                          height: 84,
                          child: AppNetworkImage(
                            mediaUrl(property.coverImage),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              localizedTitle(
                                context,
                                en: property.titleEn,
                                ar: property.titleAr,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              listingPrice(
                                context,
                                property.price,
                                property.listingType,
                                currencySymbol: catalog
                                    ?.byCode(property.countryCode)
                                    ?.currencySymbol(localizations.localeName),
                              ),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: localizations.edit,
                        onPressed: () =>
                            _openEditor(context, ref, property.id),
                        icon: const Icon(Icons.edit_outlined),
                      ),
                      IconButton(
                        tooltip: localizations.delete,
                        onPressed: () => _delete(context, ref, property),
                        icon: Icon(
                          Icons.delete_outline,
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.myListings),
        actions: [
          IconButton(
            tooltip: localizations.newListing,
            onPressed: () => _create(context, ref),
            icon: const Icon(Icons.add),
          ),
          const SizedBox(width: 4),
        ],
      ),
      floatingActionButton: items == null || items.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _create(context, ref),
              icon: const Icon(Icons.add),
              label: Text(localizations.newListing),
            ),
      body: body,
    );
  }
}

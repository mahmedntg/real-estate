import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/ui.dart';
import '../../data/api.dart';
import '../../data/models.dart';
import '../../l10n/generated/app_localizations.dart';
import '../home/home_controller.dart';
import '../home/property_card.dart';
import 'favorites_controller.dart';

class FavoritesPage extends ConsumerWidget {
  const FavoritesPage({super.key});

  Future<void> _refresh(WidgetRef ref) async {
    try {
      final favorites = ref.refresh(favoritesProvider.future);
      await favorites;
    } catch (_) {
      // The error state is rendered from the provider.
    }
  }

  Future<void> _unfavorite(
    BuildContext context,
    WidgetRef ref,
    PropertySummary property,
  ) async {
    try {
      await ref.read(apiProvider).setFavorite(property.id, false);
      ref.read(homeControllerProvider.notifier).markFavorite(property.id, false);
      ref.invalidate(favoritesProvider);
    } catch (error) {
      if (context.mounted) {
        showErrorSnack(context, error);
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localizations = AppLocalizations.of(context);
    final favorites = ref.watch(favoritesProvider);
    final items = favorites.value;

    final Widget body;
    if (items == null && favorites.hasError) {
      body = ErrorView(
        error: favorites.error,
        onRetry: () => ref.invalidate(favoritesProvider),
      );
    } else if (items == null) {
      body = const LoadingView();
    } else if (items.isEmpty) {
      body = ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: 420,
            child: EmptyView(
              icon: Icons.favorite_border,
              title: localizations.favoritesEmpty,
              body: localizations.favoritesEmptyBody,
            ),
          ),
        ],
      );
    } else {
      body = ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        itemCount: items.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final property = items[index];
          return PropertyCard(
            property: property,
            onTap: () => context.push('/property/${property.id}'),
            onFavorite: () => _unfavorite(context, ref, property),
          );
        },
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(localizations.navFavorites)),
      body: RefreshIndicator(onRefresh: () => _refresh(ref), child: body),
    );
  }
}

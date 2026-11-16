import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/labels.dart';
import '../../core/session.dart';
import '../../core/settings.dart';
import '../../core/ui.dart';
import '../../data/api.dart';
import '../../data/models.dart';
import '../../l10n/generated/app_localizations.dart';
import '../listings/my_listings_controller.dart';
import 'filters_sheet.dart';
import 'home_controller.dart';
import 'property_card.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.extentAfter < 500) {
      ref.read(homeControllerProvider.notifier).loadMore();
    }
  }

  void _onSearchChanged(String value) {
    setState(() {});
    _debounce?.cancel();
    _debounce = Timer(
      const Duration(milliseconds: 400),
      () => ref.read(homeControllerProvider.notifier).setQuery(value),
    );
  }

  Future<void> _openFilters() async {
    final initial = ref.read(homeControllerProvider).filters;
    final filters = await showModalBottomSheet<HomeFilters>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => FiltersSheet(initial: initial),
    );
    if (filters != null && mounted) {
      ref.read(homeControllerProvider.notifier).applyFilters(filters);
    }
  }

  Future<void> _toggleFavorite(PropertySummary property) async {
    if (!ref.read(isSignedInProvider)) {
      await context.push('/login?from=%2F');
      return;
    }
    try {
      await ref.read(homeControllerProvider.notifier).toggleFavorite(property);
    } catch (error) {
      if (mounted) {
        showErrorSnack(context, error);
      }
    }
  }

  Future<void> _openEditor() async {
    final saved = await context.push<bool>('/listings/new');
    if (saved == true && mounted) {
      ref.invalidate(myListingsProvider);
      await ref.read(homeControllerProvider.notifier).refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final state = ref.watch(homeControllerProvider);
    final signedIn = ref.watch(isSignedInProvider);
    final theme = Theme.of(context);
    final catalog = ref.watch(locationsProvider).value;
    final country = catalog?.byCode(state.filters.countryCode);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              localizations.appName,
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            Text(
              country == null
                  ? localizations.tagline
                  : localizedTitle(
                      context,
                      en: country.taglineEn,
                      ar: country.taglineAr,
                    ),
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
        actions: [
          if (catalog != null && catalog.countries.length > 1)
            PopupMenuButton<String>(
              tooltip: localizations.country,
              onSelected: (code) => ref
                  .read(homeControllerProvider.notifier)
                  .selectCountry(code),
              itemBuilder: (context) => [
                for (final item in catalog.countries)
                  PopupMenuItem(
                    value: item.code,
                    child: Text(countryLabel(context, item, item.code)),
                  ),
              ],
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.public, size: 18),
                    const SizedBox(width: 4),
                    Text(
                      state.filters.countryCode,
                      style: theme.textTheme.labelLarge,
                    ),
                  ],
                ),
              ),
            ),
          IconButton(
            tooltip: localizations.language,
            onPressed: () {
              final current = ref.read(settingsProvider);
              ref
                  .read(settingsProvider.notifier)
                  .setLocale(current.localeCode == 'ar' ? 'en' : 'ar');
            },
            icon: const Icon(Icons.translate),
          ),
          const SizedBox(width: 4),
        ],
      ),
      floatingActionButton: signedIn
          ? FloatingActionButton.extended(
              onPressed: _openEditor,
              icon: const Icon(Icons.add_home_work_outlined),
              label: Text(localizations.newListing),
            )
          : null,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: localizations.searchHint,
                      prefixIcon: const Icon(Icons.search),
                      isDense: true,
                      suffixIcon: _searchController.text.isEmpty
                          ? null
                          : IconButton(
                              onPressed: () {
                                _searchController.clear();
                                _onSearchChanged('');
                              },
                              icon: const Icon(Icons.close),
                              tooltip: localizations.reset,
                            ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Badge(
                  isLabelVisible: state.filters.activeFilterCount > 0,
                  label: Text('${state.filters.activeFilterCount}'),
                  child: IconButton.filledTonal(
                    onPressed: _openFilters,
                    tooltip: localizations.filters,
                    icon: const Icon(Icons.tune),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () =>
                  ref.read(homeControllerProvider.notifier).refresh(),
              child: _buildContent(state, localizations),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(HomeState state, AppLocalizations localizations) {
    if (state.loading && state.items.isEmpty) {
      return const _Scrollable(child: LoadingView());
    }
    if (state.items.isEmpty && state.error != null) {
      return _Scrollable(
        child: ErrorView(
          error: state.error,
          onRetry: () => ref.read(homeControllerProvider.notifier).refresh(),
        ),
      );
    }
    if (state.items.isEmpty) {
      return _Scrollable(
        child: EmptyView(
          icon: Icons.search_off,
          title: localizations.noResultsTitle,
          body: localizations.noResultsBody,
          actionLabel: state.filters.hasActiveFilters ? localizations.reset : null,
          onAction: state.filters.hasActiveFilters
              ? () => ref
                  .read(homeControllerProvider.notifier)
                  .applyFilters(state.filters.clearedFilters())
              : null,
        ),
      );
    }
    return ListView.separated(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
      itemCount: state.items.length + (state.hasNext ? 1 : 0),
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        if (index >= state.items.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
            ),
          );
        }
        final property = state.items[index];
        return PropertyCard(
          property: property,
          onTap: () => context.push('/property/${property.id}'),
          onFavorite: () => _toggleFavorite(property),
        );
      },
    );
  }
}

class _Scrollable extends StatelessWidget {
  const _Scrollable({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [SizedBox(height: 420, child: child)],
      );
}

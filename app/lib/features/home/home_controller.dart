import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/settings.dart';
import '../../data/api.dart';
import '../../data/models.dart';
import '../favorites/favorites_controller.dart';

class HomeFilters {
  const HomeFilters({
    this.query = '',
    this.countryCode = 'EG',
    this.governorateCode,
    this.areaCode,
    this.type,
    this.listingType,
    this.minPrice,
    this.maxPrice,
    this.bedrooms,
    this.furnished,
    this.sort = 'newest',
  });

  final String query;
  final String countryCode;
  final String? governorateCode;
  final String? areaCode;
  final PropertyType? type;
  final ListingType? listingType;
  final num? minPrice;
  final num? maxPrice;
  final int? bedrooms;
  final bool? furnished;
  final String sort;

  bool get hasActiveFilters =>
      type != null ||
      listingType != null ||
      governorateCode != null ||
      areaCode != null ||
      minPrice != null ||
      maxPrice != null ||
      bedrooms != null ||
      furnished != null;

  int get activeFilterCount => [
        type != null,
        listingType != null,
        governorateCode != null || areaCode != null,
        minPrice != null || maxPrice != null,
        bedrooms != null,
        furnished != null,
      ].where((active) => active).length;

  HomeFilters withQuery(String value) => HomeFilters(
        query: value,
        countryCode: countryCode,
        governorateCode: governorateCode,
        areaCode: areaCode,
        type: type,
        listingType: listingType,
        minPrice: minPrice,
        maxPrice: maxPrice,
        bedrooms: bedrooms,
        furnished: furnished,
        sort: sort,
      );

  HomeFilters withCountry(String value) => HomeFilters(
        query: query,
        countryCode: value,
        type: type,
        listingType: listingType,
        minPrice: minPrice,
        maxPrice: maxPrice,
        bedrooms: bedrooms,
        furnished: furnished,
        sort: sort,
      );

  HomeFilters clearedFilters() =>
      HomeFilters(query: query, countryCode: countryCode, sort: sort);
}

const Object _unset = Object();

class HomeState {
  const HomeState({
    required this.filters,
    this.items = const [],
    this.page = 0,
    this.hasNext = false,
    this.loading = true,
    this.loadingMore = false,
    this.error,
  });

  final HomeFilters filters;
  final List<PropertySummary> items;
  final int page;
  final bool hasNext;
  final bool loading;
  final bool loadingMore;
  final Object? error;

  HomeState copyWith({
    HomeFilters? filters,
    List<PropertySummary>? items,
    int? page,
    bool? hasNext,
    bool? loading,
    bool? loadingMore,
    Object? error = _unset,
  }) =>
      HomeState(
        filters: filters ?? this.filters,
        items: items ?? this.items,
        page: page ?? this.page,
        hasNext: hasNext ?? this.hasNext,
        loading: loading ?? this.loading,
        loadingMore: loadingMore ?? this.loadingMore,
        error: identical(error, _unset) ? this.error : error,
      );
}

class HomeController extends Notifier<HomeState> {
  int _searchId = 0;

  @override
  HomeState build() {
    Future.microtask(_start);
    return HomeState(
      filters: HomeFilters(countryCode: ref.read(settingsProvider).countryCode),
    );
  }

  Future<void> _start() async {
    try {
      final catalog = await ref.read(locationsProvider.future);
      final stored = state.filters.countryCode;
      final active = catalog.byCode(stored)?.code;
      if (active != null && active != stored) {
        await ref.read(settingsProvider.notifier).setCountry(active);
        state = state.copyWith(filters: state.filters.withCountry(active));
      }
    } catch (_) {
      // refresh() below surfaces the connection error.
    }
    await refresh();
  }

  Future<void> refresh() async {
    final id = ++_searchId;
    state = state.copyWith(loading: true, loadingMore: false, error: null);
    try {
      final page = await ref.read(apiProvider).search(
            query: state.filters.query,
            countryCode: state.filters.countryCode,
            governorateCode: state.filters.governorateCode,
            areaCode: state.filters.areaCode,
            type: state.filters.type,
            listingType: state.filters.listingType,
            minPrice: state.filters.minPrice,
            maxPrice: state.filters.maxPrice,
            bedrooms: state.filters.bedrooms,
            furnished: state.filters.furnished,
            sort: state.filters.sort,
            page: 0,
          );
      if (id != _searchId) {
        return;
      }
      state = state.copyWith(
        items: page.items,
        page: 0,
        hasNext: page.hasNext,
        loading: false,
      );
    } catch (error) {
      if (id != _searchId) {
        return;
      }
      state = state.copyWith(loading: false, error: error);
    }
  }

  Future<void> loadMore() async {
    if (state.loading || state.loadingMore || !state.hasNext) {
      return;
    }
    final id = _searchId;
    state = state.copyWith(loadingMore: true);
    try {
      final page = await ref.read(apiProvider).search(
            query: state.filters.query,
            countryCode: state.filters.countryCode,
            governorateCode: state.filters.governorateCode,
            areaCode: state.filters.areaCode,
            type: state.filters.type,
            listingType: state.filters.listingType,
            minPrice: state.filters.minPrice,
            maxPrice: state.filters.maxPrice,
            bedrooms: state.filters.bedrooms,
            furnished: state.filters.furnished,
            sort: state.filters.sort,
            page: state.page + 1,
          );
      if (id != _searchId) {
        return;
      }
      state = state.copyWith(
        items: [...state.items, ...page.items],
        page: page.page,
        hasNext: page.hasNext,
        loadingMore: false,
      );
    } catch (error) {
      if (id != _searchId) {
        return;
      }
      state = state.copyWith(loadingMore: false, error: error);
    }
  }

  void setQuery(String value) {
    if (state.filters.query == value) {
      return;
    }
    state = state.copyWith(filters: state.filters.withQuery(value));
    refresh();
  }

  void applyFilters(HomeFilters filters) {
    state = state.copyWith(filters: filters);
    refresh();
  }

  Future<void> selectCountry(String code) async {
    if (state.filters.countryCode == code) {
      return;
    }
    await ref.read(settingsProvider.notifier).setCountry(code);
    state = state.copyWith(filters: state.filters.withCountry(code));
    await refresh();
  }

  Future<void> toggleFavorite(PropertySummary property) async {
    final next = !property.favorite;
    _patchFavorite(property.id, next);
    try {
      await ref.read(apiProvider).setFavorite(property.id, next);
      ref.invalidate(favoritesProvider);
    } catch (error) {
      _patchFavorite(property.id, !next);
      rethrow;
    }
  }

  void markFavorite(String id, bool favorite) => _patchFavorite(id, favorite);

  void _patchFavorite(String id, bool favorite) {
    state = state.copyWith(
      items: [
        for (final item in state.items)
          item.id == id ? item.copyWith(favorite: favorite) : item,
      ],
    );
  }
}

final homeControllerProvider =
    NotifierProvider<HomeController, HomeState>(HomeController.new);

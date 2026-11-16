import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/labels.dart';
import '../../core/location_fields.dart';
import '../../data/api.dart';
import '../../data/models.dart';
import '../../l10n/generated/app_localizations.dart';
import 'home_controller.dart';

class FiltersSheet extends ConsumerStatefulWidget {
  const FiltersSheet({super.key, required this.initial});

  final HomeFilters initial;

  @override
  ConsumerState<FiltersSheet> createState() => _FiltersSheetState();
}

class _FiltersSheetState extends ConsumerState<FiltersSheet> {
  late PropertyType? _type = widget.initial.type;
  late ListingType? _listingType = widget.initial.listingType;
  late String? _governorateCode = widget.initial.governorateCode;
  late String? _areaCode = widget.initial.areaCode;
  late bool _furnishedOnly = widget.initial.furnished == true;
  late String _sort = widget.initial.sort;
  late final TextEditingController _minPrice = TextEditingController(
    text: widget.initial.minPrice?.toString() ?? '',
  );
  late final TextEditingController _maxPrice = TextEditingController(
    text: widget.initial.maxPrice?.toString() ?? '',
  );
  late final TextEditingController _bedrooms = TextEditingController(
    text: widget.initial.bedrooms?.toString() ?? '',
  );

  @override
  void dispose() {
    _minPrice.dispose();
    _maxPrice.dispose();
    _bedrooms.dispose();
    super.dispose();
  }

  void _apply() {
    var minPrice = num.tryParse(_minPrice.text.trim());
    var maxPrice = num.tryParse(_maxPrice.text.trim());
    if (minPrice != null && maxPrice != null && minPrice > maxPrice) {
      final swap = minPrice;
      minPrice = maxPrice;
      maxPrice = swap;
    }
    final filters = HomeFilters(
      query: widget.initial.query,
      countryCode: widget.initial.countryCode,
      governorateCode: _governorateCode,
      areaCode: _areaCode,
      sort: _sort,
      type: _type,
      listingType: _listingType,
      minPrice: minPrice,
      maxPrice: maxPrice,
      bedrooms: int.tryParse(_bedrooms.text.trim()),
      furnished: _furnishedOnly ? true : null,
    );
    Navigator.of(context).pop(filters);
  }

  void _reset() {
    setState(() {
      _type = null;
      _listingType = null;
      _governorateCode = null;
      _areaCode = null;
      _furnishedOnly = false;
      _sort = 'newest';
      _minPrice.clear();
      _maxPrice.clear();
      _bedrooms.clear();
    });
  }

  Widget _sectionLabel(String label) => Padding(
        padding: const EdgeInsets.only(top: 18, bottom: 8),
        child: Text(
          label,
          style: Theme.of(context)
              .textTheme
              .titleSmall
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
      );

  Widget _choiceChips<T>({
    required List<T?> options,
    required T? selected,
    required String Function(T? option) labelOf,
    required ValueChanged<T?> onSelected,
  }) =>
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final option in options)
            FilterChip(
              label: Text(labelOf(option)),
              selected: selected == option,
              onSelected: (_) => setState(() => onSelected(option)),
            ),
        ],
      );

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final catalog = ref.watch(locationsProvider).value;
    final country = catalog?.byCode(widget.initial.countryCode);
    final governorates = country?.governorates ?? const <Governorate>[];
    final governorate = catalog?.governorate(country, _governorateCode);

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + bottomInset),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              localizations.filtersTitle,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            _sectionLabel(localizations.listingType),
            _choiceChips<ListingType>(
              options: [null, ...ListingType.values],
              selected: _listingType,
              labelOf: (option) => option == null
                  ? localizations.any
                  : listingTypeLabel(localizations, option),
              onSelected: (value) => _listingType = value,
            ),
            _sectionLabel(localizations.propertyType),
            _choiceChips<PropertyType>(
              options: [null, ...PropertyType.values],
              selected: _type,
              labelOf: (option) => option == null
                  ? localizations.any
                  : propertyTypeLabel(localizations, option),
              onSelected: (value) => _type = value,
            ),
            _sectionLabel(localizations.governorate),
            GovernorateAutocomplete(
              governorates: governorates,
              selected: _governorateCode,
              label: localizations.governorate,
              hint: localizations.governorateHint,
              clearTooltip: localizations.clearSelection,
              onChanged: (value) => setState(() {
                _governorateCode = value;
                _areaCode = null;
              }),
            ),
            if (governorate != null) ...[
              _sectionLabel(localizations.area),
              _choiceChips<String>(
                options: [null, ...governorate.areas.map((item) => item.code)],
                selected: _areaCode,
                labelOf: (option) => option == null
                    ? localizations.anyArea
                    : areaLabel(
                        context,
                        catalog?.area(governorate, option),
                        option,
                      ),
                onSelected: (value) => _areaCode = value,
              ),
            ],
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _minPrice,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: localizations.minPrice,
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _maxPrice,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: localizations.maxPrice,
                      isDense: true,
                    ),
                  ),
                ),
              ],
            ),
            _sectionLabel(localizations.bedrooms),
            TextField(
              controller: _bedrooms,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: localizations.bedrooms,
                isDense: true,
              ),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _furnishedOnly,
              onChanged: (value) => setState(() => _furnishedOnly = value),
              title: Text(localizations.furnishedOnly),
            ),
            _sectionLabel(localizations.sortLabel),
            _choiceChips<String>(
              options: const ['newest', 'price_asc', 'price_desc'],
              selected: _sort,
              labelOf: (option) => switch (option) {
                'price_asc' => localizations.sortPriceAsc,
                'price_desc' => localizations.sortPriceDesc,
                _ => localizations.sortNewest,
              },
              onSelected: (value) => _sort = value ?? 'newest',
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                TextButton(
                  onPressed: _reset,
                  child: Text(localizations.reset),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _apply,
                    child: Text(localizations.apply),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

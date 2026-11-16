import 'package:material_ui/material_ui.dart';

import '../data/models.dart';
import '../l10n/generated/app_localizations.dart';

String propertyTypeLabel(AppLocalizations localizations, PropertyType type) =>
    switch (type) {
      PropertyType.apartment => localizations.propertyTypeApartment,
      PropertyType.villa => localizations.propertyTypeVilla,
      PropertyType.land => localizations.propertyTypeLand,
      PropertyType.office => localizations.propertyTypeOffice,
      PropertyType.shop => localizations.propertyTypeShop,
    };

String listingTypeLabel(AppLocalizations localizations, ListingType type) =>
    switch (type) {
      ListingType.sale => localizations.forSale,
      ListingType.rent => localizations.forRent,
    };

String landKindLabel(AppLocalizations localizations, LandKind kind) =>
    switch (kind) {
      LandKind.agricultural => localizations.landAgricultural,
      LandKind.building => localizations.landBuilding,
    };

String governorateLabel(
  BuildContext context,
  Governorate? governorate,
  String fallbackCode,
) =>
    governorate == null
        ? fallbackCode
        : localizedTitle(
            context,
            en: governorate.nameEn,
            ar: governorate.nameAr,
          );

String areaLabel(BuildContext context, Area? area, String fallbackCode) =>
    area == null
        ? fallbackCode
        : localizedTitle(context, en: area.nameEn, ar: area.nameAr);

String countryLabel(BuildContext context, Country? country, String fallbackCode) =>
    country == null
        ? fallbackCode
        : localizedTitle(context, en: country.nameEn, ar: country.nameAr);

String localizedTitle(
  BuildContext context, {
  required String en,
  required String ar,
}) {
  final arabic = Localizations.localeOf(context).languageCode == 'ar';
  final preferred = (arabic ? ar : en).trim();
  if (preferred.isNotEmpty) {
    return preferred;
  }
  final fallback = (arabic ? en : ar).trim();
  return fallback.isEmpty ? preferred : fallback;
}

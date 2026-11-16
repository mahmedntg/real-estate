import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../data/models.dart';
import '../l10n/generated/app_localizations.dart';

String _localeName(BuildContext context) =>
    Localizations.localeOf(context).toLanguageTag();

String formatMoney(BuildContext context, num value) {
  final format = NumberFormat.decimalPattern(_localeName(context));
  return value == value.truncateToDouble()
      ? format.format(value.toInt())
      : format.format(value);
}

String formatArea(BuildContext context, num value) {
  final format = NumberFormat.decimalPatternDigits(
    locale: _localeName(context),
    decimalDigits: 2,
  );
  return format.format(value);
}

String formatDate(BuildContext context, DateTime date) =>
    DateFormat.yMMMd(_localeName(context)).format(date.toLocal());

String formatTime(BuildContext context, DateTime date) =>
    DateFormat.Hm(_localeName(context)).format(date.toLocal());

String listingPrice(
  BuildContext context,
  num price,
  ListingType type, {
  String? currencySymbol,
}) {
  final localizations = AppLocalizations.of(context);
  final amount = formatMoney(context, price);
  final label = currencySymbol == null ? amount : '$amount $currencySymbol';
  return type == ListingType.rent ? localizations.pricePerMonth(label) : label;
}

String qiratsLabel(BuildContext context, num qirats) => AppLocalizations.of(
      context,
    ).qiratsShort(formatArea(context, qirats));

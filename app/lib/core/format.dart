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

String qiratsSahmLabel(BuildContext context, num qirats, int? sahm) {
  final localizations = AppLocalizations.of(context);
  final qiratsText = localizations.qiratsShort(formatArea(context, qirats));
  if (sahm == null || sahm == 0) {
    return qiratsText;
  }
  return '$qiratsText ${localizations.sahmShort(sahm)}';
}

String whatsAppUrl(String number) =>
    'https://wa.me/${number.replaceAll(RegExp(r'[^0-9]'), '')}';

String normalizePhone(String number) {
  final cleaned = number.replaceAll(RegExp(r'[^0-9+]'), '');
  return cleaned.startsWith('+')
      ? '+${cleaned.replaceAll('+', '')}'
      : cleaned.replaceAll('+', '');
}

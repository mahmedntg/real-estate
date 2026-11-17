import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/config.dart';
import '../../core/format.dart';
import '../../core/labels.dart';
import '../../core/ui.dart';
import '../../data/api.dart';
import '../../data/models.dart';
import '../../l10n/generated/app_localizations.dart';

class PropertyCard extends ConsumerWidget {
  const PropertyCard({
    super.key,
    required this.property,
    this.onTap,
    this.onFavorite,
  });

  final PropertySummary property;
  final VoidCallback? onTap;
  final VoidCallback? onFavorite;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final localizations = AppLocalizations.of(context);
    final catalog = ref.watch(locationsProvider).value;
    final country = catalog?.byCode(property.countryCode);
    final governorate =
        catalog?.governorate(country, property.governorateCode);
    final location = [
      governorateLabel(context, governorate, property.governorateCode),
      if (property.areaCode != null)
        areaLabel(
          context,
          catalog?.area(governorate, property.areaCode),
          property.areaCode!,
        ),
    ].join(' · ');

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: colors.outlineVariant),
      ),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 16 / 10,
                  child: AppNetworkImage(mediaUrl(property.coverImage)),
                ),
                PositionedDirectional(
                  top: 8,
                  end: 8,
                  child: Material(
                    color: colors.surface.withValues(alpha: 0.92),
                    shape: const CircleBorder(),
                    child: IconButton(
                      onPressed: onFavorite,
                      tooltip: property.favorite
                          ? localizations.unfavorite
                          : localizations.favorite,
                      icon: Icon(
                        property.favorite
                            ? Icons.favorite
                            : Icons.favorite_border,
                        color: property.favorite ? colors.error : null,
                      ),
                    ),
                  ),
                ),
                PositionedDirectional(
                  bottom: 8,
                  start: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: colors.primary,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      listingTypeLabel(localizations, property.listingType),
                      style: TextStyle(
                        color: colors.onPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(14),
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
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    location,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: colors.onSurfaceVariant),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    listingPrice(
                      context,
                      property.price,
                      property.listingType,
                      currencySymbol:
                          country?.currencySymbol(localizations.localeName),
                    ),
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: colors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 16,
                    runSpacing: 6,
                    children: [
                      if (property.bedrooms != null)
                        _Spec(
                          icon: Icons.bed_outlined,
                          label: localizations.bedroomsShort(
                            property.bedrooms!,
                          ),
                        ),
                      if (property.bathrooms != null)
                        _Spec(
                          icon: Icons.bathtub_outlined,
                          label: localizations.bathroomsShort(
                            property.bathrooms!,
                          ),
                        ),
                      if (property.landKind != null &&
                          property.areaQirats != null)
                        _Spec(
                          icon: Icons.landscape_outlined,
                          label: qiratsSahmLabel(
                            context,
                            property.areaQirats!,
                            property.areaSahm,
                          ),
                        )
                      else if (property.landKind == null &&
                          property.areaSqm != null)
                        _Spec(
                          icon: Icons.square_foot,
                          label: localizations.areaShort(
                            formatArea(context, property.areaSqm!),
                          ),
                        ),
                      if (property.furnished)
                        _Spec(
                          icon: Icons.chair_outlined,
                          label: localizations.furnished,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Spec extends StatelessWidget {
  const _Spec({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: colors.onSurfaceVariant),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: colors.onSurfaceVariant),
        ),
      ],
    );
  }
}

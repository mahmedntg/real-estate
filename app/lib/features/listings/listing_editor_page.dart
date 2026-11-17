import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/config.dart';
import '../../core/labels.dart';
import '../../core/location_fields.dart';
import '../../core/settings.dart';
import '../../core/ui.dart';
import '../../data/api.dart';
import '../../data/models.dart';
import '../../l10n/generated/app_localizations.dart';
import '../favorites/favorites_controller.dart';
import '../home/home_controller.dart';
import '../property/property_controller.dart';
import 'my_listings_controller.dart';

class ListingEditorPage extends ConsumerStatefulWidget {
  const ListingEditorPage({super.key, this.id});

  final String? id;

  @override
  ConsumerState<ListingEditorPage> createState() => _ListingEditorPageState();
}

class _ListingEditorPageState extends ConsumerState<ListingEditorPage> {
  static const int _maxImages = 8;
  static const int _maxVideoBytes = 50 * 1024 * 1024;

  final _formKey = GlobalKey<FormState>();
  final _titleEn = TextEditingController();
  final _titleAr = TextEditingController();
  final _descriptionEn = TextEditingController();
  final _descriptionAr = TextEditingController();
  final _price = TextEditingController();
  final _areaSqm = TextEditingController();
  final _bedrooms = TextEditingController();
  final _bathrooms = TextEditingController();
  final _areaQirats = TextEditingController();
  final _eastSide = TextEditingController();
  final _westSide = TextEditingController();
  final _northSide = TextEditingController();
  final _southSide = TextEditingController();
  final _streetWidth = TextEditingController();
  final _boundaryNorth = TextEditingController();
  final _boundarySouth = TextEditingController();
  final _boundaryEast = TextEditingController();
  final _boundaryWest = TextEditingController();

  PropertyType _propertyType = PropertyType.apartment;
  ListingType _listingType = ListingType.rent;
  String _countryCode = 'EG';
  String? _governorateCode;
  String? _areaCode;
  bool _furnished = false;
  LandKind? _landKind;
  bool? _buildingPermit;
  bool _negotiable = false;

  bool _loading = false;
  bool _saving = false;
  Object? _loadError;

  List<PropertyImage> _existingImages = const [];
  final Set<String> _removedImageIds = {};
  final List<_PickedImage> _picked = [];

  String? _existingVideoUrl;
  bool _removeVideo = false;
  XFile? _pickedVideo;

  bool get _isEdit => widget.id != null;

  int get _imageCount =>
      _existingImages.where((image) => !_removedImageIds.contains(image.id)).length +
      _picked.length;

  @override
  void initState() {
    super.initState();
    _countryCode = ref.read(settingsProvider).countryCode;
    if (_isEdit) {
      _load();
    }
  }

  @override
  void dispose() {
    _titleEn.dispose();
    _titleAr.dispose();
    _descriptionEn.dispose();
    _descriptionAr.dispose();
    _price.dispose();
    _areaSqm.dispose();
    _bedrooms.dispose();
    _bathrooms.dispose();
    _areaQirats.dispose();
    _eastSide.dispose();
    _westSide.dispose();
    _northSide.dispose();
    _southSide.dispose();
    _streetWidth.dispose();
    _boundaryNorth.dispose();
    _boundarySouth.dispose();
    _boundaryEast.dispose();
    _boundaryWest.dispose();
    super.dispose();
  }

  String _numberText(num value) =>
      value % 1 == 0 ? value.toInt().toString() : value.toString();

  String? _optionalText(TextEditingController controller) {
    final text = controller.text.trim();
    return text.isEmpty ? null : text;
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final detail = await ref.read(apiProvider).property(widget.id!);
      if (!mounted) {
        return;
      }
      setState(() {
        _titleEn.text = detail.titleEn;
        _titleAr.text = detail.titleAr;
        _descriptionEn.text = detail.descriptionEn;
        _descriptionAr.text = detail.descriptionAr;
        _price.text = _numberText(detail.price);
        _areaSqm.text =
            detail.areaSqm == null ? '' : _numberText(detail.areaSqm!);
        _areaQirats.text =
            detail.areaQirats == null ? '' : _numberText(detail.areaQirats!);
        _eastSide.text =
            detail.eastSideM == null ? '' : _numberText(detail.eastSideM!);
        _westSide.text =
            detail.westSideM == null ? '' : _numberText(detail.westSideM!);
        _northSide.text =
            detail.northSideM == null ? '' : _numberText(detail.northSideM!);
        _southSide.text =
            detail.southSideM == null ? '' : _numberText(detail.southSideM!);
        _streetWidth.text = detail.streetWidthM == null
            ? ''
            : _numberText(detail.streetWidthM!);
        _boundaryNorth.text = detail.boundaryNorth ?? '';
        _boundarySouth.text = detail.boundarySouth ?? '';
        _boundaryEast.text = detail.boundaryEast ?? '';
        _boundaryWest.text = detail.boundaryWest ?? '';
        _bedrooms.text = detail.bedrooms?.toString() ?? '';
        _bathrooms.text = detail.bathrooms?.toString() ?? '';
        _propertyType = detail.propertyType;
        _listingType = detail.listingType;
        _countryCode = detail.countryCode;
        _governorateCode = detail.governorateCode;
        _areaCode = detail.areaCode;
        _furnished = detail.furnished;
        _landKind = detail.landKind;
        _buildingPermit = detail.buildingPermit;
        _negotiable = detail.negotiable;
        _existingImages = detail.images;
        _existingVideoUrl = detail.videoUrl;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loading = false;
        _loadError = error;
      });
    }
  }

  Future<void> _pickImages() async {
    final localizations = AppLocalizations.of(context);
    final remaining = _maxImages - _imageCount;
    if (remaining <= 0) {
      showMessageSnack(context, localizations.imageLimitReached);
      return;
    }
    try {
      final files = await ImagePicker().pickMultiImage(imageQuality: 85);
      if (files.isEmpty || !mounted) {
        return;
      }
      if (files.length > remaining) {
        showMessageSnack(context, localizations.imageLimitReached);
      }
      final picked = <_PickedImage>[];
      for (final file in files.take(remaining)) {
        picked.add(_PickedImage(file, await file.readAsBytes()));
      }
      if (!mounted) {
        return;
      }
      setState(() => _picked.addAll(picked));
    } catch (error) {
      if (mounted) {
        showErrorSnack(context, error);
      }
    }
  }

  Future<void> _pickVideo() async {
    final localizations = AppLocalizations.of(context);
    try {
      final file = await ImagePicker().pickVideo(source: ImageSource.gallery);
      if (file == null || !mounted) {
        return;
      }
      final size = await file.length();
      if (!mounted) {
        return;
      }
      if (size > _maxVideoBytes) {
        showMessageSnack(context, localizations.videoTooLarge);
        return;
      }
      setState(() {
        _pickedVideo = file;
        _removeVideo = false;
      });
    } catch (error) {
      if (mounted) {
        showErrorSnack(context, error);
      }
    }
  }

  Future<void> _save() async {
    final localizations = AppLocalizations.of(context);
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    final titleEn = _titleEn.text.trim();
    final titleAr = _titleAr.text.trim();
    if (titleEn.isEmpty && titleAr.isEmpty) {
      showMessageSnack(context, localizations.titleRequiredOneLanguage);
      return;
    }
    final descriptionEn = _descriptionEn.text.trim();
    final descriptionAr = _descriptionAr.text.trim();
    if (descriptionEn.isEmpty && descriptionAr.isEmpty) {
      showMessageSnack(context, localizations.descriptionRequiredOneLanguage);
      return;
    }
    if (_governorateCode == null) {
      showMessageSnack(context, localizations.requiredField);
      return;
    }
    final isLand = _propertyType == PropertyType.land;
    if (isLand && _landKind == LandKind.building && _buildingPermit == null) {
      showMessageSnack(context, localizations.requiredField);
      return;
    }
    if (isLand) {
      final filledSides = [
        _eastSide.text.trim(),
        _westSide.text.trim(),
        _northSide.text.trim(),
        _southSide.text.trim(),
      ].where((side) => side.isNotEmpty).length;
      if (filledSides != 0 && filledSides != 4) {
        showMessageSnack(context, localizations.plotSidesRequired);
        return;
      }
    }
    final countryCode =
        ref.read(locationsProvider).value?.byCode(_countryCode)?.code ??
            _countryCode;
    setState(() => _saving = true);
    try {
      final draft = PropertyDraft(
        titleEn: titleEn,
        titleAr: titleAr,
        descriptionEn: descriptionEn,
        descriptionAr: descriptionAr,
        propertyType: _propertyType,
        listingType: _listingType,
        countryCode: countryCode,
        governorateCode: _governorateCode!,
        areaCode: _areaCode,
        price: num.parse(_price.text.trim()),
        areaSqm: num.tryParse(_areaSqm.text.trim()),
        bedrooms: int.tryParse(_bedrooms.text.trim()),
        bathrooms: int.tryParse(_bathrooms.text.trim()),
        furnished: _furnished,
        landKind: isLand ? _landKind : null,
        areaQirats: isLand ? num.tryParse(_areaQirats.text.trim()) : null,
        northSideM: isLand ? num.tryParse(_northSide.text.trim()) : null,
        southSideM: isLand ? num.tryParse(_southSide.text.trim()) : null,
        eastSideM: isLand ? num.tryParse(_eastSide.text.trim()) : null,
        westSideM: isLand ? num.tryParse(_westSide.text.trim()) : null,
        streetWidthM: isLand ? num.tryParse(_streetWidth.text.trim()) : null,
        boundaryNorth: isLand ? _optionalText(_boundaryNorth) : null,
        boundarySouth: isLand ? _optionalText(_boundarySouth) : null,
        boundaryEast: isLand ? _optionalText(_boundaryEast) : null,
        boundaryWest: isLand ? _optionalText(_boundaryWest) : null,
        buildingPermit: isLand ? _buildingPermit : null,
        negotiable: isLand && _negotiable,
      );
      final saved = _isEdit
          ? await ref.read(apiProvider).updateProperty(widget.id!, draft)
          : await ref.read(apiProvider).createProperty(draft);

      for (final imageId in _removedImageIds) {
        try {
          await ref.read(apiProvider).deleteImage(saved.id, imageId);
        } catch (_) {
          // The image may already be gone; the listing itself is saved.
        }
      }

      var uploadFailed = false;
      if (_picked.isNotEmpty) {
        try {
          await ref.read(apiProvider).uploadImages(
                saved.id,
                [for (final picked in _picked) picked.file],
              );
        } catch (error) {
          uploadFailed = true;
          if (mounted) {
            showErrorSnack(context, error);
          }
        }
      }

      if (_pickedVideo != null) {
        try {
          await ref.read(apiProvider).uploadVideo(saved.id, _pickedVideo!);
        } catch (error) {
          uploadFailed = true;
          if (mounted) {
            showErrorSnack(context, error);
          }
        }
      } else if (_removeVideo && _existingVideoUrl != null) {
        try {
          await ref.read(apiProvider).deleteVideo(saved.id);
        } catch (_) {
          // The video may already be gone; the listing itself is saved.
        }
      }

      ref.invalidate(myListingsProvider);
      ref.invalidate(propertyProvider(saved.id));
      ref.invalidate(favoritesProvider);
      await ref.read(homeControllerProvider.notifier).refresh();

      if (!mounted) {
        return;
      }
      if (uploadFailed) {
        setState(() => _saving = false);
        return;
      }
      showMessageSnack(context, localizations.listingSaved);
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _saving = false);
      showErrorSnack(context, error);
    }
  }

  Widget _photoSection(AppLocalizations localizations) {
    final colors = Theme.of(context).colorScheme;
    final visibleExisting = _existingImages
        .where((image) => !_removedImageIds.contains(image.id))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              localizations.photos,
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            Text(
              '$_imageCount/$_maxImages',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: colors.onSurfaceVariant),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 100,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              for (final image in visibleExisting)
                _PhotoTile(
                  child: AppNetworkImage(mediaUrl(image.url)),
                  onRemove: () =>
                      setState(() => _removedImageIds.add(image.id)),
                ),
              for (final picked in _picked)
                _PhotoTile(
                  child: Image.memory(picked.bytes, fit: BoxFit.cover),
                  onRemove: () => setState(() => _picked.remove(picked)),
                ),
              if (_imageCount < _maxImages)
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: 8),
                  child: SizedBox(
                    width: 100,
                    height: 100,
                    child: OutlinedButton(
                      onPressed: _saving ? null : _pickImages,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.all(6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.add_a_photo_outlined),
                          const SizedBox(height: 6),
                          Text(
                            localizations.addPhotos,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          localizations.maxImages(_maxImages),
          style: Theme.of(context)
              .textTheme
              .labelSmall
              ?.copyWith(color: colors.onSurfaceVariant),
        ),
      ],
    );
  }

  Widget _videoSection(AppLocalizations localizations) {
    final colors = Theme.of(context).colorScheme;
    final existing = _removeVideo ? null : _existingVideoUrl;
    final hasVideo = existing != null || _pickedVideo != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          localizations.video,
          style: Theme.of(context)
              .textTheme
              .titleSmall
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 10),
        if (hasVideo)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.videocam_outlined),
            title: Text(
              _pickedVideo?.name ?? localizations.video,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              _pickedVideo != null
                  ? localizations.videoPendingUpload
                  : localizations.videoAttached,
            ),
            trailing: IconButton(
              tooltip: localizations.removeVideo,
              onPressed: _saving
                  ? null
                  : () => setState(() {
                        _pickedVideo = null;
                        if (_existingVideoUrl != null) {
                          _removeVideo = true;
                        }
                      }),
              icon: Icon(Icons.close, color: colors.error),
            ),
          )
        else
          OutlinedButton.icon(
            onPressed: _saving ? null : _pickVideo,
            icon: const Icon(Icons.videocam_outlined),
            label: Text(localizations.addVideo),
          ),
        const SizedBox(height: 6),
        Text(
          localizations.videoHint,
          style: Theme.of(context)
              .textTheme
              .labelSmall
              ?.copyWith(color: colors.onSurfaceVariant),
        ),
      ],
    );
  }

  Widget _section(String title, List<Widget> children) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          ...children,
        ],
      );

  String? _optionalPositive(AppLocalizations localizations, String text) {
    final parsed = num.tryParse(text);
    if (parsed == null) {
      return localizations.invalidNumber;
    }
    if (parsed <= 0) {
      return localizations.positiveNumber;
    }
    return null;
  }

  Widget _sideField(
    AppLocalizations localizations,
    TextEditingController controller,
    String label,
  ) =>
      TextFormField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(labelText: label),
        validator: (value) {
          final text = value?.trim() ?? '';
          if (text.isEmpty) {
            return null;
          }
          return _optionalPositive(localizations, text);
        },
      );

  Widget _chipGroup<T>({
    required List<T> values,
    required T? selected,
    required String Function(T value) labelOf,
    required ValueChanged<T> onSelected,
  }) =>
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final value in values)
            ChoiceChip(
              label: Text(labelOf(value)),
              selected: value == selected,
              onSelected: (_) => setState(() => onSelected(value)),
            ),
        ],
      );

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final catalog = ref.watch(locationsProvider).value;
    final country = catalog?.byCode(_countryCode);
    final governorate = catalog?.governorate(country, _governorateCode);

    final Widget body;
    if (_loading) {
      body = const LoadingView();
    } else if (_loadError != null) {
      body = ErrorView(error: _loadError, onRetry: _load);
    } else {
      body = Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            _photoSection(localizations),
            const SizedBox(height: 16),
            _videoSection(localizations),
            const SizedBox(height: 24),
            _section(localizations.basicInfo, [
              TextFormField(
                controller: _titleEn,
                textCapitalization: TextCapitalization.sentences,
                maxLength: 160,
                decoration: InputDecoration(
                  labelText: localizations.titleEn,
                  counterText: '',
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _titleAr,
                textDirection: TextDirection.rtl,
                maxLength: 160,
                decoration: InputDecoration(
                  labelText: localizations.titleAr,
                  counterText: '',
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionEn,
                minLines: 3,
                maxLines: 5,
                maxLength: 2000,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: localizations.descriptionEn,
                  counterText: '',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionAr,
                minLines: 3,
                maxLines: 5,
                maxLength: 2000,
                textDirection: TextDirection.rtl,
                decoration: InputDecoration(
                  labelText: localizations.descriptionAr,
                  counterText: '',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                localizations.listingType,
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 8),
              _chipGroup<ListingType>(
                values: ListingType.values,
                selected: _listingType,
                labelOf: (value) =>
                    listingTypeLabel(localizations, value),
                onSelected: (value) => _listingType = value,
              ),
              const SizedBox(height: 16),
              Text(
                localizations.propertyType,
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 8),
              _chipGroup<PropertyType>(
                values: PropertyType.values,
                selected: _propertyType,
                labelOf: (value) =>
                    propertyTypeLabel(localizations, value),
                onSelected: (value) => _propertyType = value,
              ),
            ]),
            const SizedBox(height: 24),
            _section(localizations.location, [
              if (catalog != null && catalog.countries.length > 1) ...[
                Text(
                  localizations.country,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: 8),
                _chipGroup<String>(
                  values: [for (final item in catalog.countries) item.code],
                  selected: country?.code ?? _countryCode,
                  labelOf: (value) =>
                      countryLabel(context, catalog.byCode(value), value),
                  onSelected: (value) {
                    _countryCode = value;
                    _governorateCode = null;
                    _areaCode = null;
                  },
                ),
                const SizedBox(height: 14),
              ],
              GovernorateAutocomplete(
                governorates: country?.governorates ?? const [],
                selected: _governorateCode,
                label: localizations.governorate,
                hint: localizations.governorateHint,
                clearTooltip: localizations.clearSelection,
                onChanged: (value) => setState(() {
                  _governorateCode = value;
                  _areaCode = null;
                }),
              ),
              if (governorate != null && governorate.areas.isNotEmpty) ...[
                const SizedBox(height: 14),
                Text(
                  localizations.area,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: 8),
                _chipGroup<String>(
                  values: [
                    for (final item in governorate.areas) item.code,
                  ],
                  selected: _areaCode,
                  labelOf: (value) => areaLabel(
                    context,
                    catalog?.area(governorate, value),
                    value,
                  ),
                  onSelected: (value) => _areaCode = value,
                ),
              ],
            ]),
            const SizedBox(height: 24),
            _section(localizations.pricing, [
              TextFormField(
                controller: _price,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: localizations.price,
                  suffixText: country?.currencySymbol(localizations.localeName),
                ),
                validator: (value) {
                  final text = value?.trim() ?? '';
                  if (text.isEmpty) {
                    return localizations.requiredField;
                  }
                  final parsed = num.tryParse(text);
                  if (parsed == null) {
                    return localizations.invalidNumber;
                  }
                  if (parsed <= 0) {
                    return localizations.positiveNumber;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _areaSqm,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration:
                          InputDecoration(labelText: localizations.areaSqm),
                      validator: (value) {
                        final text = value?.trim() ?? '';
                        if (text.isEmpty) {
                          return null;
                        }
                        final parsed = num.tryParse(text);
                        if (parsed == null) {
                          return localizations.invalidNumber;
                        }
                        if (parsed <= 0) {
                          return localizations.positiveNumber;
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _bedrooms,
                      keyboardType: TextInputType.number,
                      decoration:
                          InputDecoration(labelText: localizations.bedrooms),
                      validator: (value) {
                        final text = value?.trim() ?? '';
                        if (text.isEmpty) {
                          return null;
                        }
                        final parsed = int.tryParse(text);
                        if (parsed == null || parsed < 0) {
                          return localizations.invalidNumber;
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _bathrooms,
                      keyboardType: TextInputType.number,
                      decoration:
                          InputDecoration(labelText: localizations.bathrooms),
                      validator: (value) {
                        final text = value?.trim() ?? '';
                        if (text.isEmpty) {
                          return null;
                        }
                        final parsed = int.tryParse(text);
                        if (parsed == null || parsed < 0) {
                          return localizations.invalidNumber;
                        }
                        return null;
                      },
                    ),
                  ),
                  const Expanded(child: SizedBox()),
                ],
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(localizations.furnished),
                value: _furnished,
                onChanged: (value) => setState(() => _furnished = value),
              ),
            ]),
            if (_propertyType == PropertyType.land) ...[
              const SizedBox(height: 24),
              _section(localizations.landDetails, [
                _chipGroup<LandKind>(
                  values: LandKind.values,
                  selected: _landKind,
                  labelOf: (value) => landKindLabel(localizations, value),
                  onSelected: (value) {
                    _landKind = value;
                    if (value == LandKind.building) {
                      _areaQirats.clear();
                    } else {
                      _buildingPermit = null;
                    }
                  },
                ),
                if (_landKind == LandKind.agricultural) ...[
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _areaQirats,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: localizations.areaQirats,
                      helperText: localizations.feddanHint,
                    ),
                    validator: (value) {
                      final text = value?.trim() ?? '';
                      if (text.isEmpty) {
                        return localizations.requiredField;
                      }
                      return _optionalPositive(localizations, text);
                    },
                  ),
                ],
                const SizedBox(height: 12),
                Text(
                  localizations.plotDimensions,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: 4),
                Text(
                  localizations.plotSidesHint,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _sideField(
                        localizations,
                        _eastSide,
                        localizations.sideEast,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _sideField(
                        localizations,
                        _westSide,
                        localizations.sideWest,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _sideField(
                        localizations,
                        _northSide,
                        localizations.sideNorth,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _sideField(
                        localizations,
                        _southSide,
                        localizations.sideSouth,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _streetWidth,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration:
                      InputDecoration(labelText: localizations.streetWidth),
                  validator: (value) {
                    final text = value?.trim() ?? '';
                    if (text.isEmpty) {
                      return null;
                    }
                    return _optionalPositive(localizations, text);
                  },
                ),
                const SizedBox(height: 16),
                Text(
                  localizations.boundaries,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _boundaryNorth,
                  maxLength: 200,
                  decoration: InputDecoration(
                    labelText: localizations.boundaryNorth,
                    counterText: '',
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _boundarySouth,
                  maxLength: 200,
                  decoration: InputDecoration(
                    labelText: localizations.boundarySouth,
                    counterText: '',
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _boundaryEast,
                  maxLength: 200,
                  decoration: InputDecoration(
                    labelText: localizations.boundaryEast,
                    counterText: '',
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _boundaryWest,
                  maxLength: 200,
                  decoration: InputDecoration(
                    labelText: localizations.boundaryWest,
                    counterText: '',
                  ),
                ),
                if (_landKind == LandKind.building) ...[
                  const SizedBox(height: 16),
                  Text(
                    localizations.buildingPermit,
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: 8),
                  _chipGroup<bool>(
                    values: const [true, false],
                    selected: _buildingPermit,
                    labelOf: (value) =>
                        value ? localizations.yes : localizations.no,
                    onSelected: (value) => _buildingPermit = value,
                  ),
                ],
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(localizations.negotiable),
                  value: _negotiable,
                  onChanged: (value) => setState(() => _negotiable = value),
                ),
              ]),
            ],
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEdit ? localizations.editListing : localizations.newListing,
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: SizedBox(
            height: 50,
            child: FilledButton(
              onPressed: (_saving || _loading || _loadError != null) ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      _isEdit
                          ? localizations.saveChanges
                          : localizations.createListing,
                    ),
            ),
          ),
        ),
      ),
      body: body,
    );
  }
}

class _PhotoTile extends StatelessWidget {
  const _PhotoTile({required this.child, required this.onRemove});

  final Widget child;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 8),
      child: SizedBox(
        width: 100,
        height: 100,
        child: Stack(
          children: [
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: child,
              ),
            ),
            PositionedDirectional(
              top: 4,
              end: 4,
              child: Material(
                color: colors.surface.withValues(alpha: 0.9),
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: onRemove,
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(Icons.close, size: 16, color: colors.error),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PickedImage {
  const _PickedImage(this.file, this.bytes);

  final XFile file;
  final Uint8List bytes;
}

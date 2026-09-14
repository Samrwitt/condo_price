import 'package:flutter/material.dart';

import '../format.dart';
import '../layout.dart';
import '../models/capital.dart';
import '../widgets/flag_mark.dart';
import '../widgets/listing_photo.dart';
import '../widgets/size_control.dart';
import 'city_picker_screen.dart';
import 'result_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.catalog,
  });

  final CapitalsCatalog catalog;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Capital? _cityA;
  Capital? _cityB;
  late int _sizeM2 = widget.catalog.standardM2.round();

  bool get _canCompare =>
      _cityA != null && _cityB != null && _cityA!.id != _cityB!.id;

  Future<void> _pickCity({required bool isA}) async {
    final selected = await Navigator.of(context).push<Capital>(
      fadeRoute(
        CityPickerScreen(
          cities: widget.catalog.cities,
          title: isA ? 'City A' : 'City B',
          selectedId: isA ? _cityA?.id : _cityB?.id,
          standardM2: _sizeM2,
        ),
      ),
    );
    if (selected == null) return;
    setState(() {
      if (isA) {
        _cityA = selected;
      } else {
        _cityB = selected;
      }
    });
  }

  void _swap() {
    setState(() {
      final previous = _cityA;
      _cityA = _cityB;
      _cityB = previous;
    });
  }

  void _compare() {
    if (!_canCompare) return;
    Navigator.of(context).push(
      fadeRoute(
        ResultScreen(
          cityA: _cityA!,
          cityB: _cityB!,
          sizeM2: _sizeM2,
          catalog: widget.catalog,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final sameCity =
        _cityA != null && _cityB != null && _cityA!.id == _cityB!.id;
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'assets/icon/app_icon.png',
                width: 28,
                height: 28,
                errorBuilder: (_, _, _) => Icon(
                  Icons.home_rounded,
                  color: colors.primary,
                ),
              ),
            ),
            const SizedBox(width: 10),
            const Text('Condo Compare'),
          ],
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: PageInset.of(context),
          child: FillColumn(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${widget.catalog.cities.length} capitals · real listing photos',
                    style: text.labelLarge?.copyWith(
                      color: colors.primary,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.catalog.coverage,
                    style: text.bodyMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
              Card.filled(
                color: colors.surfaceContainerHighest,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      _CityField(
                        fieldKey: const ValueKey('city-a'),
                        badge: 'A',
                        city: _cityA,
                        placeholder: 'City A',
                        onTap: () => _pickCity(isA: true),
                      ),
                      const SizedBox(height: 4),
                      IconButton.filledTonal(
                        onPressed: _swap,
                        tooltip: 'Swap cities',
                        icon: const Icon(Icons.swap_vert),
                      ),
                      const SizedBox(height: 4),
                      _CityField(
                        fieldKey: const ValueKey('city-b'),
                        badge: 'B',
                        city: _cityB,
                        placeholder: 'City B',
                        onTap: () => _pickCity(isA: false),
                      ),
                    ],
                  ),
                ),
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 280),
                switchInCurve: Curves.easeOutCubic,
                child: !_canCompare
                    ? const SizedBox.shrink()
                    : _LivePreview(
                        key: ValueKey('${_cityA!.id}-${_cityB!.id}-$_sizeM2'),
                        cityA: _cityA!,
                        cityB: _cityB!,
                        sizeM2: _sizeM2,
                      ),
              ),
              Card.filled(
                color: colors.surfaceContainerLow,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: SizeControl(
                    sizeM2: _sizeM2,
                    defaultSize: widget.catalog.standardM2.round(),
                    onChanged: (value) => setState(() => _sizeM2 = value),
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FilledButton(
                    onPressed: _canCompare ? _compare : null,
                    child: const Text('Compare'),
                  ),
                  if (sameCity) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Pick two different cities',
                      textAlign: TextAlign.center,
                      style: text.bodyMedium?.copyWith(color: colors.error),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LivePreview extends StatelessWidget {
  const _LivePreview({
    super.key,
    required this.cityA,
    required this.cityB,
    required this.sizeM2,
  });

  final Capital cityA;
  final Capital cityB;
  final int sizeM2;

  @override
  Widget build(BuildContext context) {
    final priceA = cityA.priceFor(sizeM2);
    final priceB = cityB.priceFor(sizeM2);
    return Row(
      children: [
        Expanded(
          child: CityHeroCard(
            city: cityA,
            priceLabel: formatUsd(priceA),
            subtitle: formatSample(
              cityA.listingCount,
              indicative: cityA.indicative,
            ),
            highlight: priceA <= priceB,
            height: 148,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: CityHeroCard(
            city: cityB,
            priceLabel: formatUsd(priceB),
            subtitle: formatSample(
              cityB.listingCount,
              indicative: cityB.indicative,
            ),
            highlight: priceB < priceA,
            height: 148,
          ),
        ),
      ],
    );
  }
}

class _CityField extends StatelessWidget {
  const _CityField({
    required this.fieldKey,
    required this.badge,
    required this.city,
    required this.placeholder,
    required this.onTap,
  });

  final Key fieldKey;
  final String badge;
  final Capital? city;
  final String placeholder;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        key: fieldKey,
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 10, 14, 10),
          child: Row(
            children: [
              if (city?.heroPhoto != null)
                GestureDetector(
                  onTap: city!.photos.length > 1
                      ? () => openCityPhotoGallery(context, city: city!)
                      : null,
                  child: Stack(
                    children: [
                      SizedBox(
                        width: 56,
                        height: 56,
                        child: ListingPhoto(
                          url: city!.heroPhoto,
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      if (city!.photos.length > 1)
                        Positioned(
                          right: 3,
                          bottom: 3,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.55),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              '${city!.photos.length}',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 10,
                                  ),
                            ),
                          ),
                        ),
                    ],
                  ),
                )
              else
                FlagMark(
                  country: city?.country ?? '',
                  letter: city == null ? badge : null,
                  size: 44,
                ),
              const SizedBox(width: 12),
              Expanded(
                child: city == null
                    ? Text(
                        placeholder,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(color: colors.onSurfaceVariant),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            city!.city,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            '${city!.country} · ${formatSample(city!.listingCount, indicative: city!.indicative)}',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: colors.onSurfaceVariant),
                          ),
                        ],
                      ),
              ),
              Icon(Icons.expand_more_rounded, color: colors.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../format.dart';
import '../models/capital.dart';
import '../widgets/listing_photo.dart';

enum _CitySort { name, price }

class CityPickerScreen extends StatefulWidget {
  const CityPickerScreen({
    super.key,
    required this.cities,
    required this.title,
    required this.standardM2,
    this.selectedId,
    this.hiddenId,
  });

  final List<Capital> cities;
  final String title;
  final int standardM2;
  final String? selectedId;
  final String? hiddenId;

  @override
  State<CityPickerScreen> createState() => _CityPickerScreenState();
}

class _CityPickerScreenState extends State<CityPickerScreen> {
  final _query = TextEditingController();
  _CitySort _sort = _CitySort.name;

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  List<Capital> get _filtered {
    final needle = _query.text.trim().toLowerCase();
    final matches = widget.cities.where((city) {
      if (city.id == widget.hiddenId) return false;
      if (needle.isEmpty) return true;
      return city.city.toLowerCase().contains(needle) ||
          city.country.toLowerCase().contains(needle);
    }).toList();
    matches.sort((a, b) {
      if (_sort == _CitySort.price) {
        return a.medianUsdPerM2.compareTo(b.medianUsdPerM2);
      }
      return a.city.compareTo(b.city);
    });
    return matches;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final matches = _filtered;

    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: SearchBar(
                controller: _query,
                hintText: 'City or country',
                leading: const Icon(Icons.search),
                trailing: [
                  if (_query.text.isNotEmpty)
                    IconButton(
                      onPressed: () {
                        _query.clear();
                        setState(() {});
                      },
                      icon: const Icon(Icons.close),
                    ),
                ],
                onChanged: (_) => setState(() {}),
                elevation: const WidgetStatePropertyAll(0),
                backgroundColor: WidgetStatePropertyAll(
                  colors.surfaceContainerHigh,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: SegmentedButton<_CitySort>(
                  segments: const [
                    ButtonSegment(
                      value: _CitySort.name,
                      label: Text('A–Z'),
                    ),
                    ButtonSegment(
                      value: _CitySort.price,
                      label: Text('Price'),
                    ),
                  ],
                  selected: {_sort},
                  onSelectionChanged: (value) {
                    setState(() => _sort = value.first);
                  },
                  showSelectedIcon: false,
                  style: const ButtonStyle(
                    visualDensity: VisualDensity.compact,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ),
            ),
            Expanded(
              child: matches.isEmpty
                  ? Center(
                      child: Text(
                        'No match in this listing set',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.only(bottom: 12),
                      itemCount: matches.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final city = matches[index];
                        final selected = city.id == widget.selectedId;
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Material(
                            color: selected
                                ? colors.secondaryContainer
                                : colors.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(18),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(18),
                              onTap: () => Navigator.of(context).pop(city),
                              child: Padding(
                                padding: const EdgeInsets.all(10),
                                child: Row(
                                  children: [
                                    GestureDetector(
                                      onTap: city.photos.length > 1
                                          ? () => openCityPhotoGallery(
                                                context,
                                                city: city,
                                              )
                                          : null,
                                      child: Stack(
                                        children: [
                                          SizedBox(
                                            width: 72,
                                            height: 72,
                                            child: ListingPhoto(
                                              url: city.heroPhoto,
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                            ),
                                          ),
                                          if (city.photos.length > 1)
                                            Positioned(
                                              right: 4,
                                              bottom: 4,
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 6,
                                                  vertical: 2,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Colors.black
                                                      .withValues(alpha: 0.55),
                                                  borderRadius:
                                                      BorderRadius.circular(999),
                                                ),
                                                child: Text(
                                                  '${city.photos.length}',
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .labelSmall
                                                      ?.copyWith(
                                                        color: Colors.white,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                      ),
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            city.city,
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w600,
                                                ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${city.country} · ${formatSample(city.listingCount, indicative: city.indicative)}',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.copyWith(
                                                  color:
                                                      colors.onSurfaceVariant,
                                                ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            formatUsd(
                                              city.priceFor(widget.standardM2),
                                            ),
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleSmall
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w600,
                                                  letterSpacing: -0.3,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (selected)
                                      Icon(
                                        Icons.check_circle_rounded,
                                        color: colors.primary,
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

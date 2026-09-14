import 'package:flutter/material.dart';

import '../format.dart';
import '../layout.dart';
import '../models/capital.dart';
import '../widgets/listing_photo.dart';
import '../widgets/size_control.dart';

class ResultScreen extends StatefulWidget {
  const ResultScreen({
    super.key,
    required this.cityA,
    required this.cityB,
    required this.sizeM2,
    required this.catalog,
  });

  final Capital cityA;
  final Capital cityB;
  final int sizeM2;
  final CapitalsCatalog catalog;

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  late int _sizeM2 = widget.sizeM2;

  @override
  Widget build(BuildContext context) {
    final cityA = widget.cityA;
    final cityB = widget.cityB;
    final priceA = cityA.priceFor(_sizeM2);
    final priceB = cityB.priceFor(_sizeM2);
    final cheaper = priceA <= priceB ? cityA : cityB;
    final costlier = cheaper.id == cityA.id ? cityB : cityA;
    final cheapPrice = cheaper.priceFor(_sizeM2);
    final highPrice = costlier.priceFor(_sizeM2);
    final dollarGap = highPrice - cheapPrice;
    final maxPrice = highPrice.toDouble();
    final times = formatTimes(highPrice, cheapPrice);
    final thinNote = _thinSampleNote(cityA, cityB);
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: Text(formatM2(_sizeM2))),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: PageInset.of(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                cheaper.city,
                textAlign: TextAlign.center,
                style: text.labelLarge?.copyWith(
                  color: colors.primary,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                formatUsd(dollarGap),
                textAlign: TextAlign.center,
                style: text.displaySmall?.copyWith(
                  fontWeight: FontWeight.w300,
                  letterSpacing: -1.4,
                  height: 1.05,
                  color: colors.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${cheaper.city} is ${formatUsd(dollarGap)} cheaper',
                textAlign: TextAlign.center,
                style: text.titleMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              if (times != 'about the same') ...[
                const SizedBox(height: 6),
                Text(
                  '$times the ${cheaper.city} price',
                  textAlign: TextAlign.center,
                  style: text.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
              if (thinNote != null) ...[
                const SizedBox(height: 10),
                Text(
                  thinNote,
                  textAlign: TextAlign.center,
                  style: text.bodySmall?.copyWith(color: colors.tertiary),
                ),
              ],
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: CityHeroCard(
                      city: cityA,
                      priceLabel: formatUsd(priceA),
                      subtitle: cityA.rankLabelAmong(widget.catalog.cities),
                      highlight: cityA.id == cheaper.id,
                      height: 190,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CityHeroCard(
                      city: cityB,
                      priceLabel: formatUsd(priceB),
                      subtitle: cityB.rankLabelAmong(widget.catalog.cities),
                      highlight: cityB.id == cheaper.id,
                      height: 190,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'Tap a photo to swipe through more listings',
                textAlign: TextAlign.center,
                style: text.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              _PriceBar(
                city: cityA,
                price: priceA,
                maxPrice: maxPrice,
                highlight: cityA.id == cheaper.id,
              ),
              const SizedBox(height: 14),
              _PriceBar(
                city: cityB,
                price: priceB,
                maxPrice: maxPrice,
                highlight: cityB.id == cheaper.id,
              ),
              const SizedBox(height: 24),
              Card.filled(
                color: colors.surfaceContainerLow,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: SizeControl(
                    sizeM2: _sizeM2,
                    defaultSize: widget.catalog.standardM2.round(),
                    onChanged: (value) => setState(() => _sizeM2 = value),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _StatsCard(cityA: cityA, cityB: cityB, sizeM2: _sizeM2),
              const SizedBox(height: 12),
              Text(
                widget.catalog.method,
                textAlign: TextAlign.center,
                style: text.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

String? _thinSampleNote(Capital cityA, Capital cityB) {
  final thin = [cityA, cityB].where((city) => city.indicative).toList();
  if (thin.isEmpty) return null;
  if (thin.length == 2) {
    return 'Both prices use fewer than 200 listings, so treat them as indicative.';
  }
  final city = thin.first;
  return '${city.city} uses ${formatListings(city.listingCount)}, so treat it as indicative.';
}

class _PriceBar extends StatelessWidget {
  const _PriceBar({
    required this.city,
    required this.price,
    required this.maxPrice,
    required this.highlight,
  });

  final Capital city;
  final int price;
  final double maxPrice;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final widthFactor = maxPrice == 0 ? 0.0 : price / maxPrice;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            SizedBox(
              width: 28,
              height: 28,
              child: ListingPhoto(
                url: city.heroPhoto,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                city.city,
                style: text.labelLarge?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            Text(
              formatUsd(price),
              style: text.labelLarge?.copyWith(
                fontWeight: FontWeight.w500,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: widthFactor.clamp(0.04, 1.0)),
          duration: const Duration(milliseconds: 700),
          curve: Curves.easeOutCubic,
          builder: (context, value, _) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: value,
                minHeight: 10,
                backgroundColor: colors.surfaceContainerHighest,
                color: highlight ? colors.primary : colors.outline,
              ),
            );
          },
        ),
      ],
    );
  }
}

class _StatsCard extends StatelessWidget {
  const _StatsCard({
    required this.cityA,
    required this.cityB,
    required this.sizeM2,
  });

  final Capital cityA;
  final Capital cityB;
  final int sizeM2;

  @override
  Widget build(BuildContext context) {
    return Card.filled(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Column(
          children: [
            _StatRow(
              label: 'USD / m²',
              left: formatUsd(cityA.medianUsdPerM2),
              right: formatUsd(cityB.medianUsdPerM2),
            ),
            _StatRow(
              label: 'Listings',
              left: formatSample(
                cityA.listingCount,
                indicative: cityA.indicative,
              ),
              right: formatSample(
                cityB.listingCount,
                indicative: cityB.indicative,
              ),
            ),
            _StatRow(
              label: 'Typical range',
              left:
                  '${formatUsd(cityA.rangeLowFor(sizeM2))}–${formatUsd(cityA.rangeHighFor(sizeM2))}',
              right:
                  '${formatUsd(cityB.rangeLowFor(sizeM2))}–${formatUsd(cityB.rangeHighFor(sizeM2))}',
            ),
          ],
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({
    required this.label,
    required this.left,
    required this.right,
  });

  final String label;
  final String left;
  final String right;

  @override
  Widget build(BuildContext context) {
    final strong = Theme.of(context).textTheme.bodyMedium?.copyWith(
      fontWeight: FontWeight.w600,
      letterSpacing: -0.2,
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(child: Text(left, style: strong)),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          Expanded(
            child: Text(right, style: strong, textAlign: TextAlign.end),
          ),
        ],
      ),
    );
  }
}

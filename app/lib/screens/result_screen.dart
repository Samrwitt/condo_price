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
    final modelA = cityA.modelPriceFor(_sizeM2);
    final modelB = cityB.modelPriceFor(_sizeM2);
    final cheaper = priceA <= priceB ? cityA : cityB;
    final costlier = cheaper.id == cityA.id ? cityB : cityA;
    final cheapPrice = cheaper.priceFor(_sizeM2);
    final highPrice = costlier.priceFor(_sizeM2);
    final dollarGap = highPrice - cheapPrice;
    final maxPrice = [
      priceA,
      priceB,
      if (modelA != null) modelA,
      if (modelB != null) modelB,
    ].fold<double>(0, (max, value) => value > max ? value.toDouble() : max);
    final times = formatTimes(highPrice, cheapPrice);
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
              const SizedBox(height: 8),
              Text(
                'Headline uses median · model shown below',
                textAlign: TextAlign.center,
                style: text.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: CityHeroCard(
                      city: cityA,
                      sizeM2: _sizeM2,
                      priceLabel: formatUsd(priceA),
                      subtitle: _heroSubtitle(cityA, modelA),
                      highlight: cityA.id == cheaper.id,
                      height: 190,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CityHeroCard(
                      city: cityB,
                      sizeM2: _sizeM2,
                      priceLabel: formatUsd(priceB),
                      subtitle: _heroSubtitle(cityB, modelB),
                      highlight: cityB.id == cheaper.id,
                      height: 190,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'Tap a photo to swipe listings near ${formatM2(_sizeM2)}',
                textAlign: TextAlign.center,
                style: text.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              _PriceBar(
                city: cityA,
                medianPrice: priceA,
                modelPrice: modelA,
                sizeM2: _sizeM2,
                maxPrice: maxPrice,
                highlight: cityA.id == cheaper.id,
              ),
              const SizedBox(height: 14),
              _PriceBar(
                city: cityB,
                medianPrice: priceB,
                modelPrice: modelB,
                sizeM2: _sizeM2,
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
              if (cityA.hasModel || cityB.hasModel) ...[
                const SizedBox(height: 12),
                _ModelWhyCard(
                  cityA: cityA,
                  cityB: cityB,
                  sizeM2: _sizeM2,
                ),
              ],
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  String _heroSubtitle(Capital city, int? modelPrice) {
    final rank = city.rankLabelAmong(widget.catalog.cities);
    if (modelPrice == null) return rank;
    return 'Model ${formatUsd(modelPrice)} · $rank';
  }
}

class _PriceBar extends StatelessWidget {
  const _PriceBar({
    required this.city,
    required this.medianPrice,
    required this.modelPrice,
    required this.sizeM2,
    required this.maxPrice,
    required this.highlight,
  });

  final Capital city;
  final int medianPrice;
  final int? modelPrice;
  final int sizeM2;
  final double maxPrice;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final medianFactor = maxPrice == 0 ? 0.0 : medianPrice / maxPrice;
    final modelFactor =
        modelPrice == null || maxPrice == 0 ? null : modelPrice! / maxPrice;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            SizedBox(
              width: 28,
              height: 28,
              child: ListingPhoto(
                url: city.heroPhotoFor(sizeM2),
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
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Median ${formatUsd(medianPrice)}',
                  style: text.labelLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                    letterSpacing: -0.2,
                  ),
                ),
                if (modelPrice != null)
                  Text(
                    'Model ${formatUsd(modelPrice!)}',
                    style: text.labelSmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: medianFactor.clamp(0.04, 1.0)),
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
        if (modelFactor != null) ...[
          const SizedBox(height: 6),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: modelFactor.clamp(0.04, 1.0)),
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeOutCubic,
            builder: (context, value, _) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  value: value,
                  minHeight: 6,
                  backgroundColor: colors.surfaceContainerHighest,
                  color: colors.tertiary,
                ),
              );
            },
          ),
        ],
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
    final modelA = cityA.modelPriceFor(sizeM2);
    final modelB = cityB.modelPriceFor(sizeM2);
    final ppm2A = cityA.modelPpm2For(sizeM2);
    final ppm2B = cityB.modelPpm2For(sizeM2);

    return Card.filled(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Column(
          children: [
            _StatRow(
              label: 'Median USD / m²',
              left: formatUsd(cityA.medianUsdPerM2),
              right: formatUsd(cityB.medianUsdPerM2),
            ),
            _StatRow(
              label: 'Median price',
              left: formatUsd(cityA.priceFor(sizeM2)),
              right: formatUsd(cityB.priceFor(sizeM2)),
            ),
            if (modelA != null || modelB != null) ...[
              _StatRow(
                label: 'Model USD / m²',
                left: ppm2A == null ? '—' : formatUsd(ppm2A),
                right: ppm2B == null ? '—' : formatUsd(ppm2B),
              ),
              _StatRow(
                label: 'Model price',
                left: modelA == null ? '—' : formatUsd(modelA),
                right: modelB == null ? '—' : formatUsd(modelB),
              ),
            ],
            _StatRow(
              label: 'Listings',
              left: formatSample(cityA.listingCount),
              right: formatSample(cityB.listingCount),
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

class _ModelWhyCard extends StatelessWidget {
  const _ModelWhyCard({
    required this.cityA,
    required this.cityB,
    required this.sizeM2,
  });

  final Capital cityA;
  final Capital cityB;
  final int sizeM2;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final blocks = <Widget>[
      Text(
        'Why model differs from median',
        style: text.titleSmall?.copyWith(fontWeight: FontWeight.w600),
      ),
      const SizedBox(height: 4),
      Text(
        'Median is the city-wide middle USD/m². The model prices a typical '
        'condo near this size using rooms, year, and floors.',
        style: text.bodySmall?.copyWith(color: colors.onSurfaceVariant),
      ),
    ];

    for (final city in [cityA, cityB]) {
      final why = city.modelExplanationFor(sizeM2);
      if (why == null) continue;
      final gapLabel = why.vsMedian == 'close'
          ? 'about even with median'
          : '${why.gapPct.abs().toStringAsFixed(0)}% ${why.vsMedian} than median';
      blocks.add(const SizedBox(height: 14));
      blocks.add(
        Text(
          city.city,
          style: text.labelLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
      );
      blocks.add(
        Text(
          gapLabel,
          style: text.bodyMedium?.copyWith(
            color: why.vsMedian == 'higher'
                ? colors.tertiary
                : why.vsMedian == 'lower'
                    ? colors.primary
                    : colors.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
      blocks.add(const SizedBox(height: 4));
      blocks.add(
        Text(
          why.assumes,
          style: text.bodySmall?.copyWith(color: colors.onSurfaceVariant),
        ),
      );
      for (final driver in why.drivers) {
        blocks.add(const SizedBox(height: 6));
        blocks.add(
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                driver.pushesUp
                    ? Icons.arrow_upward_rounded
                    : Icons.arrow_downward_rounded,
                size: 16,
                color: driver.pushesUp ? colors.tertiary : colors.primary,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(driver.label, style: text.bodySmall),
              ),
            ],
          ),
        );
      }
    }

    return Card.filled(
      color: colors.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: blocks,
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

import 'package:flutter/material.dart';

import '../format.dart';
import '../models/capital.dart';

class ResultScreen extends StatelessWidget {
  const ResultScreen({
    super.key,
    required this.cityA,
    required this.cityB,
  });

  final Capital cityA;
  final Capital cityB;

  @override
  Widget build(BuildContext context) {
    final cheaper = cityA.price80m2 <= cityB.price80m2 ? cityA : cityB;
    final costlier = cheaper.id == cityA.id ? cityB : cityA;
    final dollarGap = costlier.price80m2 - cheaper.price80m2;
    final percentGap = dollarGap / cheaper.price80m2 * 100;
    final maxPrice = costlier.price80m2.toDouble();

    return Scaffold(
      appBar: AppBar(title: const Text('80 m² comparison')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Text(
            'Typical 80 m² condo',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            '${cheaper.city} is ${formatUsd(dollarGap)} cheaper '
            '(${percentGap.toStringAsFixed(0)}%).',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _PriceCard(
                  city: cityA,
                  highlight: cityA.id == cheaper.id,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _PriceCard(
                  city: cityB,
                  highlight: cityB.id == cheaper.id,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Price scale',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 12),
          _PriceBar(city: cityA, maxPrice: maxPrice),
          const SizedBox(height: 10),
          _PriceBar(city: cityB, maxPrice: maxPrice),
          const SizedBox(height: 24),
          _CityStats(city: cityA),
          const SizedBox(height: 12),
          _CityStats(city: cityB),
        ],
      ),
    );
  }
}

class _PriceCard extends StatelessWidget {
  const _PriceCard({required this.city, required this.highlight});

  final Capital city;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      color: highlight ? colors.primaryContainer : colors.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              city.city,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            Text(
              city.country,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              formatUsd(city.price80m2),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            if (highlight) ...[
              const SizedBox(height: 8),
              Text(
                'Lower price',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: colors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PriceBar extends StatelessWidget {
  const _PriceBar({required this.city, required this.maxPrice});

  final Capital city;
  final double maxPrice;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final widthFactor = maxPrice == 0 ? 0.0 : city.price80m2 / maxPrice;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(city.city, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: SizedBox(
            height: 14,
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: widthFactor.clamp(0.04, 1.0),
              child: ColoredBox(color: colors.primary),
            ),
          ),
        ),
      ],
    );
  }
}

class _CityStats extends StatelessWidget {
  const _CityStats({required this.city});

  final Capital city;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(city.label, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 12),
            _StatRow(label: 'USD per m²', value: formatUsdPerM2(city.medianUsdPerM2)),
            _StatRow(
              label: 'Listings used',
              value: formatCount(city.listingCount),
            ),
            _StatRow(
              label: 'Typical 80 m² range',
              value: '${formatUsd(city.rangeLow80)} – ${formatUsd(city.rangeHigh80)}',
            ),
            const SizedBox(height: 8),
            Text(
              'Range is the 25th–75th percentile of listing prices, scaled to 80 m².',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

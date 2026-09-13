import 'package:flutter/material.dart';

import '../format.dart';
import '../models/capital.dart';
import '../widgets/size_control.dart';

class ResultScreen extends StatefulWidget {
  const ResultScreen({
    super.key,
    required this.cityA,
    required this.cityB,
    required this.sizeM2,
  });

  final Capital cityA;
  final Capital cityB;
  final int sizeM2;

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
    final dollarGap = costlier.priceFor(_sizeM2) - cheapPrice;
    final percentGap = cheapPrice == 0 ? 0.0 : dollarGap / cheapPrice * 100;
    final maxPrice = costlier.priceFor(_sizeM2).toDouble();

    return Scaffold(
      appBar: AppBar(title: Text('${formatM2(_sizeM2)} comparison')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          SizeControl(
            sizeM2: _sizeM2,
            onChanged: (value) => setState(() => _sizeM2 = value),
          ),
          const SizedBox(height: 20),
          Text(
            'Typical ${formatM2(_sizeM2)} condo',
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
                  price: priceA,
                  highlight: cityA.id == cheaper.id,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _PriceCard(
                  city: cityB,
                  price: priceB,
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
          _PriceBar(city: cityA, price: priceA, maxPrice: maxPrice),
          const SizedBox(height: 10),
          _PriceBar(city: cityB, price: priceB, maxPrice: maxPrice),
          const SizedBox(height: 24),
          _CityStats(city: cityA, sizeM2: _sizeM2),
          const SizedBox(height: 12),
          _CityStats(city: cityB, sizeM2: _sizeM2),
        ],
      ),
    );
  }
}

class _PriceCard extends StatelessWidget {
  const _PriceCard({
    required this.city,
    required this.price,
    required this.highlight,
  });

  final Capital city;
  final int price;
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
              formatUsd(price),
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
  const _PriceBar({
    required this.city,
    required this.price,
    required this.maxPrice,
  });

  final Capital city;
  final int price;
  final double maxPrice;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final widthFactor = maxPrice == 0 ? 0.0 : price / maxPrice;
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
  const _CityStats({required this.city, required this.sizeM2});

  final Capital city;
  final int sizeM2;

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
              label: 'Typical ${formatM2(sizeM2)} range',
              value:
                  '${formatUsd(city.rangeLowFor(sizeM2))} – ${formatUsd(city.rangeHighFor(sizeM2))}',
            ),
            const SizedBox(height: 8),
            Text(
              'Range is the 25th–75th percentile of listing prices, scaled to ${formatM2(sizeM2)}.',
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

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
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(formatM2(_sizeM2))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
        children: [
          SizeControl(
            sizeM2: _sizeM2,
            onChanged: (value) => setState(() => _sizeM2 = value),
          ),
          const SizedBox(height: 20),
          Text(
            '${cheaper.city} is ${formatUsd(dollarGap)} cheaper '
            '(${percentGap.toStringAsFixed(0)}%)',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: colors.primary,
              fontWeight: FontWeight.w700,
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
          const SizedBox(height: 20),
          _PriceBar(label: cityA.city, price: priceA, maxPrice: maxPrice),
          const SizedBox(height: 10),
          _PriceBar(label: cityB.city, price: priceB, maxPrice: maxPrice),
          const SizedBox(height: 20),
          _StatsCard(cityA: cityA, cityB: cityB, sizeM2: _sizeM2),
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
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              city.city,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              city.country,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              formatUsd(price),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PriceBar extends StatelessWidget {
  const _PriceBar({
    required this.label,
    required this.price,
    required this.maxPrice,
  });

  final String label;
  final int price;
  final double maxPrice;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final widthFactor = maxPrice == 0 ? 0.0 : price / maxPrice;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: ColoredBox(
            color: colors.surfaceContainer,
            child: SizedBox(
              height: 10,
              width: double.infinity,
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: widthFactor.clamp(0.06, 1.0),
                child: ColoredBox(color: colors.primary),
              ),
            ),
          ),
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Column(
          children: [
            _StatRow(
              label: 'Per m²',
              left: formatUsd(cityA.medianUsdPerM2),
              right: formatUsd(cityB.medianUsdPerM2),
            ),
            _StatRow(
              label: 'Listings',
              left: formatCount(cityA.listingCount),
              right: formatCount(cityB.listingCount),
            ),
            _StatRow(
              label: 'Range',
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
    final style = Theme.of(context).textTheme.bodyMedium;
    final strong = style?.copyWith(fontWeight: FontWeight.w700);
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

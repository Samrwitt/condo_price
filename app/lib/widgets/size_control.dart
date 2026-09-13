import 'package:flutter/material.dart';

import '../format.dart';

class SizeControl extends StatelessWidget {
  const SizeControl({
    super.key,
    required this.sizeM2,
    required this.onChanged,
    this.defaultSize = 80,
    this.minSize = 30,
    this.maxSize = 200,
  });

  final int sizeM2;
  final ValueChanged<int> onChanged;
  final int defaultSize;
  final int minSize;
  final int maxSize;

  static const presets = [50, 80, 100, 120];

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      children: [
        Text(
          'Condo size',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              formatM2(sizeM2),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            if (sizeM2 != defaultSize)
              IconButton(
                key: const ValueKey('size-reset'),
                tooltip: formatM2(defaultSize),
                onPressed: () => onChanged(defaultSize),
                icon: Icon(Icons.restart_alt, color: colors.primary),
              ),
          ],
        ),
        Slider(
          key: const ValueKey('size-slider'),
          value: sizeM2.toDouble(),
          min: minSize.toDouble(),
          max: maxSize.toDouble(),
          divisions: maxSize - minSize,
          label: formatM2(sizeM2),
          onChanged: (value) => onChanged(value.round()),
        ),
        Wrap(
          spacing: 8,
          alignment: WrapAlignment.center,
          children: [
            for (final preset in presets)
              ChoiceChip(
                key: ValueKey('size-preset-$preset'),
                label: Text(formatM2(preset)),
                selected: sizeM2 == preset,
                onSelected: (_) => onChanged(preset),
              ),
          ],
        ),
      ],
    );
  }
}

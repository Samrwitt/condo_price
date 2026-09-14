import 'package:flutter/material.dart';

import '../flags.dart';

class FlagMark extends StatelessWidget {
  const FlagMark({
    super.key,
    required this.country,
    this.letter,
    this.size = 40,
  });

  final String country;
  final String? letter;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: colors.secondaryContainer,
        shape: BoxShape.circle,
      ),
      child: letter == null
          ? Text(flagFor(country), style: TextStyle(fontSize: size * 0.46))
          : Text(
              letter!,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: colors.onSecondaryContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
    );
  }
}

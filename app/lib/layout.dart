import 'package:flutter/material.dart';

class PageInset {
  static EdgeInsets of(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final horizontal = size.width < 360 ? 16.0 : 20.0;
    return EdgeInsets.fromLTRB(horizontal, 8, horizontal, 12);
  }

  static double maxContentWidth(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return width < 600 ? width : 600;
  }
}

class PhoneShell extends StatelessWidget {
  const PhoneShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth < 600
            ? constraints.maxWidth
            : PageInset.maxContentWidth(context);
        return ColoredBox(
          color: Theme.of(context).colorScheme.surface,
          child: Align(
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: width,
              height: constraints.maxHeight,
              child: child,
            ),
          ),
        );
      },
    );
  }
}

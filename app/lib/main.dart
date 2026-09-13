import 'package:flutter/material.dart';

import 'data/capitals_repository.dart';
import 'models/capital.dart';
import 'screens/home_screen.dart';
import 'theme.dart';

void main() {
  runApp(const CondoCompareApp());
}

class CondoCompareApp extends StatelessWidget {
  const CondoCompareApp({
    super.key,
    this.repository = const CapitalsRepository(),
  });

  final CapitalsRepository repository;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Condo Compare',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      builder: (context, child) {
        final content = child ?? const SizedBox.shrink();
        return LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth <= 480) return content;
            return ColoredBox(
              color: Theme.of(context).colorScheme.surfaceContainerLowest,
              child: Center(
                child: SizedBox(width: 480, height: constraints.maxHeight, child: content),
              ),
            );
          },
        );
      },
      home: CatalogGate(repository: repository),
    );
  }
}

class CatalogGate extends StatefulWidget {
  const CatalogGate({super.key, required this.repository});

  final CapitalsRepository repository;

  @override
  State<CatalogGate> createState() => _CatalogGateState();
}

class _CatalogGateState extends State<CatalogGate> {
  late final Future<CapitalsCatalog> _catalog = widget.repository.load();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<CapitalsCatalog>(
      future: _catalog,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Could not load capital prices.\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return HomeScreen(catalog: snapshot.data!);
      },
    );
  }
}

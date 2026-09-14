import 'package:flutter/material.dart';

import 'data/capitals_repository.dart';
import 'layout.dart';
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
        return PhoneShell(child: child ?? const SizedBox.shrink());
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
          final colors = Theme.of(context).colorScheme;
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.asset(
                      'assets/icon/app_icon.png',
                      width: 64,
                      height: 64,
                      errorBuilder: (_, _, _) => Icon(
                        Icons.home_rounded,
                        size: 48,
                        color: colors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const CircularProgressIndicator(),
                ],
              ),
            ),
          );
        }
        return HomeScreen(catalog: snapshot.data!);
      },
    );
  }
}

import 'package:condo_compare/models/capital.dart';
import 'package:condo_compare/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

final _catalog = CapitalsCatalog(
  standardM2: 80,
  source: 'test',
  cities: const [
    Capital(
      id: 'athens',
      city: 'Athens',
      country: 'Greece',
      listingCount: 1001,
      medianUsdPerM2: 3330.9,
      p25UsdPerM2: 2338.2,
      p75UsdPerM2: 4617.0,
      price80m2: 266473,
    ),
    Capital(
      id: 'minsk',
      city: 'Minsk',
      country: 'Belarus',
      listingCount: 4104,
      medianUsdPerM2: 1224.5,
      p25UsdPerM2: 1000,
      p75UsdPerM2: 1500,
      price80m2: 97959,
    ),
    Capital(
      id: 'prague',
      city: 'Prague',
      country: 'Czech Republic',
      listingCount: 718,
      medianUsdPerM2: 5622.8,
      p25UsdPerM2: 4800,
      p75UsdPerM2: 6500,
      price80m2: 449824,
    ),
    Capital(
      id: 'rome',
      city: 'Rome',
      country: 'Italy',
      listingCount: 57,
      medianUsdPerM2: 11355.4,
      p25UsdPerM2: 6000,
      p75UsdPerM2: 16000,
      price80m2: 908433,
      indicative: true,
    ),
  ],
);

Future<void> _openApp(WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp(home: HomeScreen(catalog: _catalog)),
  );
  await tester.pump();
}

Future<void> _pickFromList(WidgetTester tester, Key fieldKey, String city) async {
  await tester.ensureVisible(find.byKey(fieldKey));
  await tester.tap(find.byKey(fieldKey));
  await tester.pumpAndSettle();
  expect(find.text(city), findsWidgets);
  await tester.tap(find.text(city).last);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('compares two different capitals', (tester) async {
    await _openApp(tester);

    expect(find.text('Condo Compare'), findsOneWidget);
    expect(find.text('Condo size'), findsOneWidget);
    expect(find.text('80 m²'), findsWidgets);

    await _pickFromList(tester, const ValueKey('city-a'), 'Prague');
    await _pickFromList(tester, const ValueKey('city-b'), 'Minsk');

    await tester.ensureVisible(find.widgetWithText(FilledButton, 'Compare'));
    await tester.tap(find.widgetWithText(FilledButton, 'Compare'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(AppBar, '80 m²'), findsOneWidget);
    expect(find.text('\$449,824'), findsWidgets);
    expect(find.text('\$97,960'), findsWidgets);
    expect(find.textContaining('cheaper'), findsOneWidget);
  });

  testWidgets('rescales prices when condo size changes', (tester) async {
    await _openApp(tester);

    await _pickFromList(tester, const ValueKey('city-a'), 'Prague');
    await _pickFromList(tester, const ValueKey('city-b'), 'Minsk');

    await tester.ensureVisible(find.byKey(const ValueKey('size-preset-100')));
    await tester.tap(find.byKey(const ValueKey('size-preset-100')));
    await tester.pump();

    await tester.ensureVisible(find.widgetWithText(FilledButton, 'Compare'));
    await tester.tap(find.widgetWithText(FilledButton, 'Compare'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(AppBar, '100 m²'), findsOneWidget);
    expect(find.text('\$562,280'), findsWidgets);
    expect(find.text('\$122,450'), findsWidgets);
  });

  testWidgets('keeps Compare disabled for the same city', (tester) async {
    await _openApp(tester);

    await _pickFromList(tester, const ValueKey('city-a'), 'Athens');
    await _pickFromList(tester, const ValueKey('city-b'), 'Athens');

    final button = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Compare'),
    );
    expect(button.onPressed, isNull);
    expect(find.text('Pick two different cities'), findsOneWidget);
  });

  testWidgets('shows listing counts without indicative labels', (tester) async {
    await _openApp(tester);

    await _pickFromList(tester, const ValueKey('city-a'), 'Prague');
    await _pickFromList(tester, const ValueKey('city-b'), 'Rome');

    expect(find.textContaining('57 listings'), findsWidgets);
    expect(find.textContaining('indicative'), findsNothing);

    await tester.ensureVisible(find.widgetWithText(FilledButton, 'Compare'));
    await tester.tap(find.widgetWithText(FilledButton, 'Compare'));
    await tester.pumpAndSettle();

    expect(find.textContaining('57 listings'), findsWidgets);
    expect(find.textContaining('indicative'), findsNothing);
  });

  testWidgets('shows median and model prices when a city has a model',
      (tester) async {
    final modeled = CapitalsCatalog(
      standardM2: 80,
      source: 'test',
      cities: [
        Capital(
          id: 'minsk',
          city: 'Minsk',
          country: 'Belarus',
          listingCount: 4104,
          medianUsdPerM2: 1224.5,
          p25UsdPerM2: 1000,
          p75UsdPerM2: 1500,
          price80m2: 97959,
          model: PriceModel(
            n: 4104,
            weights: List<double>.filled(15, 0),
            mean: List<double>.filled(15, 0),
            std: List<double>.filled(15, 1),
            defaults: const {
              'rooms': 2,
              'bedrooms': 1,
              'bathrooms': 1,
              'year': 2010,
              'building_floors': 5,
              'apartment_floor': 2,
            },
            profile: const {
              'rooms': 2,
              'bedrooms': 1,
              'bathrooms': 1,
              'year': 2010,
              'building_floors': 5,
              'apartment_floor': 2,
            },
          ),
        ),
        _catalog.cities[2],
      ],
    );

    await tester.pumpWidget(
      MaterialApp(home: HomeScreen(catalog: modeled)),
    );
    await tester.pump();

    await _pickFromList(tester, const ValueKey('city-a'), 'Prague');
    await _pickFromList(tester, const ValueKey('city-b'), 'Minsk');
    await tester.ensureVisible(find.widgetWithText(FilledButton, 'Compare'));
    await tester.tap(find.widgetWithText(FilledButton, 'Compare'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Median'), findsWidgets);
    expect(find.textContaining('Model'), findsWidgets);
    expect(find.text('Median USD / m²'), findsOneWidget);
    expect(find.text('Model price'), findsOneWidget);
  });
}

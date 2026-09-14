import 'package:condo_compare/models/capital.dart';
import 'package:condo_compare/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

final _catalog = CapitalsCatalog(
  standardM2: 80,
  source: 'test',
  coverage:
      'Median condo prices for the 22 capitals in this listing set. London, Paris, Tokyo and New York are not in the source data.',
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
    expect(find.textContaining('London, Paris, Tokyo and New York'), findsOneWidget);
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

  testWidgets('flags a thin sample as indicative', (tester) async {
    await _openApp(tester);

    await _pickFromList(tester, const ValueKey('city-a'), 'Prague');
    await _pickFromList(tester, const ValueKey('city-b'), 'Rome');

    expect(find.textContaining('indicative'), findsWidgets);

    await tester.ensureVisible(find.widgetWithText(FilledButton, 'Compare'));
    await tester.tap(find.widgetWithText(FilledButton, 'Compare'));
    await tester.pumpAndSettle();

    expect(find.textContaining('57 listings · indicative'), findsWidgets);
    expect(
      find.textContaining('Rome uses 57 listings, so treat it as indicative'),
      findsOneWidget,
    );
  });
}

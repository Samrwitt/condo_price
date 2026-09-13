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
      listingCount: 5540,
      medianUsdPerM2: 1224.5,
      p25UsdPerM2: 1000,
      p75UsdPerM2: 1500,
      price80m2: 97959,
    ),
    Capital(
      id: 'prague',
      city: 'Prague',
      country: 'Czech Republic',
      listingCount: 809,
      medianUsdPerM2: 5622.8,
      p25UsdPerM2: 4800,
      p75UsdPerM2: 6500,
      price80m2: 449824,
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
  await tester.pump();
  expect(find.widgetWithText(ListTile, city), findsOneWidget);
  await tester.tap(find.widgetWithText(ListTile, city));
  await tester.pump();
}

void main() {
  testWidgets('compares two different capitals', (tester) async {
    await _openApp(tester);

    expect(find.text('Compare condo prices'), findsOneWidget);
    expect(find.text('Condo size'), findsOneWidget);
    expect(find.text('80 m²'), findsWidgets);

    await _pickFromList(tester, const ValueKey('city-a'), 'Prague');
    await _pickFromList(tester, const ValueKey('city-b'), 'Minsk');

    await tester.ensureVisible(find.text('Compare'));
    await tester.tap(find.text('Compare'));
    await tester.pump();

    expect(find.text('80 m² comparison'), findsOneWidget);
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

    await tester.ensureVisible(find.text('Compare'));
    await tester.tap(find.text('Compare'));
    await tester.pump();

    expect(find.text('100 m² comparison'), findsOneWidget);
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
    expect(find.text('Choose two different capitals to compare.'), findsOneWidget);
  });
}

import 'package:flutter/material.dart';

import '../format.dart';
import '../models/capital.dart';
import '../widgets/size_control.dart';
import 'city_picker_screen.dart';
import 'result_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.catalog,
  });

  final CapitalsCatalog catalog;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Capital? _cityA;
  Capital? _cityB;
  late int _sizeM2 = widget.catalog.standardM2.round();

  bool get _canCompare =>
      _cityA != null && _cityB != null && _cityA!.id != _cityB!.id;

  Future<void> _pickCity({required bool isA}) async {
    final selected = await Navigator.of(context).push<Capital>(
      PageRouteBuilder(
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
        pageBuilder: (_, _, _) => CityPickerScreen(
          cities: widget.catalog.cities,
          title: isA ? 'Choose city A' : 'Choose city B',
          selectedId: isA ? _cityA?.id : _cityB?.id,
        ),
      ),
    );
    if (selected == null) return;
    setState(() {
      if (isA) {
        _cityA = selected;
      } else {
        _cityB = selected;
      }
    });
  }

  void _swap() {
    setState(() {
      final previous = _cityA;
      _cityA = _cityB;
      _cityB = previous;
    });
  }

  void _compare() {
    if (!_canCompare) return;
    Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
        pageBuilder: (_, _, _) => ResultScreen(
          cityA: _cityA!,
          cityB: _cityB!,
          sizeM2: _sizeM2,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Condo Compare')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          Text(
            'Compare condo prices',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Listing-based estimates for a ${formatM2(_sizeM2)} condo in two capital cities. '
            '${formatM2(widget.catalog.standardM2.round())} is the default standard.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          _CityField(
            fieldKey: const ValueKey('city-a'),
            label: 'City A',
            city: _cityA,
            onTap: () => _pickCity(isA: true),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.center,
            child: IconButton.filledTonal(
              onPressed: _swap,
              tooltip: 'Swap cities',
              icon: const Icon(Icons.swap_vert),
            ),
          ),
          const SizedBox(height: 8),
          _CityField(
            fieldKey: const ValueKey('city-b'),
            label: 'City B',
            city: _cityB,
            onTap: () => _pickCity(isA: false),
          ),
          const SizedBox(height: 24),
          SizeControl(
            sizeM2: _sizeM2,
            defaultSize: widget.catalog.standardM2.round(),
            onChanged: (value) => setState(() => _sizeM2 = value),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _canCompare ? _compare : null,
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('Compare'),
            ),
          ),
          if (_cityA != null && _cityB != null && _cityA!.id == _cityB!.id) ...[
            const SizedBox(height: 12),
            Text(
              'Choose two different capitals to compare.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colors.error,
              ),
            ),
          ],
          const SizedBox(height: 32),
          Text(
            'Coverage is limited to ${widget.catalog.cities.length} capitals '
            'with enough apartment listings in the source data. '
            'Missing world capitals are not estimated.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _CityField extends StatelessWidget {
  const _CityField({
    required this.fieldKey,
    required this.label,
    required this.city,
    required this.onTap,
  });

  final Key fieldKey;
  final String label;
  final Capital? city;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        Material(
          color: colors.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            key: fieldKey,
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      city?.label ?? 'Select a capital',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: city == null
                            ? colors.onSurfaceVariant
                            : colors.onSurface,
                      ),
                    ),
                  ),
                  Icon(Icons.expand_more, color: colors.onSurfaceVariant),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

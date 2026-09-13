import 'package:flutter/material.dart';

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
          title: isA ? 'City A' : 'City B',
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
      appBar: AppBar(title: const Text('Compare')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          _CityField(
            fieldKey: const ValueKey('city-a'),
            city: _cityA,
            placeholder: 'City A',
            onTap: () => _pickCity(isA: true),
          ),
          const SizedBox(height: 10),
          Center(
            child: IconButton.filledTonal(
              onPressed: _swap,
              tooltip: 'Swap cities',
              style: IconButton.styleFrom(
                backgroundColor: colors.primaryContainer,
                foregroundColor: colors.onPrimaryContainer,
              ),
              icon: const Icon(Icons.swap_vert),
            ),
          ),
          const SizedBox(height: 10),
          _CityField(
            fieldKey: const ValueKey('city-b'),
            city: _cityB,
            placeholder: 'City B',
            onTap: () => _pickCity(isA: false),
          ),
          const SizedBox(height: 28),
          SizeControl(
            sizeM2: _sizeM2,
            defaultSize: widget.catalog.standardM2.round(),
            onChanged: (value) => setState(() => _sizeM2 = value),
          ),
          const SizedBox(height: 28),
          FilledButton(
            onPressed: _canCompare ? _compare : null,
            child: const Text('Compare'),
          ),
          if (_cityA != null && _cityB != null && _cityA!.id == _cityB!.id) ...[
            const SizedBox(height: 12),
            Text(
              'Pick two different cities',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colors.error,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CityField extends StatelessWidget {
  const _CityField({
    required this.fieldKey,
    required this.city,
    required this.placeholder,
    required this.onTap,
  });

  final Key fieldKey;
  final Capital? city;
  final String placeholder;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: colors.surfaceContainerLow,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        key: fieldKey,
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          child: Row(
            children: [
              Expanded(
                child: city == null
                    ? Text(
                        placeholder,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            city!.city,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            city!.country,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: colors.onSurfaceVariant),
                          ),
                        ],
                      ),
              ),
              Icon(Icons.expand_more, color: colors.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

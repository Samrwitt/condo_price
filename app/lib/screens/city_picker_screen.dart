import 'package:flutter/material.dart';

import '../models/capital.dart';

class CityPickerScreen extends StatefulWidget {
  const CityPickerScreen({
    super.key,
    required this.cities,
    required this.title,
    this.selectedId,
    this.hiddenId,
  });

  final List<Capital> cities;
  final String title;
  final String? selectedId;
  final String? hiddenId;

  @override
  State<CityPickerScreen> createState() => _CityPickerScreenState();
}

class _CityPickerScreenState extends State<CityPickerScreen> {
  final _query = TextEditingController();

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  List<Capital> get _filtered {
    final needle = _query.text.trim().toLowerCase();
    return widget.cities.where((city) {
      if (city.id == widget.hiddenId) return false;
      if (needle.isEmpty) return true;
      return city.city.toLowerCase().contains(needle) ||
          city.country.toLowerCase().contains(needle);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final matches = _filtered;

    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: SearchBar(
                controller: _query,
                hintText: 'Search',
                leading: const Icon(Icons.search),
                trailing: [
                  if (_query.text.isNotEmpty)
                    IconButton(
                      onPressed: () {
                        _query.clear();
                        setState(() {});
                      },
                      icon: const Icon(Icons.close),
                    ),
                ],
                onChanged: (_) => setState(() {}),
                elevation: const WidgetStatePropertyAll(0),
                backgroundColor: WidgetStatePropertyAll(
                  colors.surfaceContainerHigh,
                ),
              ),
            ),
            Expanded(
              child: matches.isEmpty
                  ? Center(
                      child: Text(
                        'No match',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    )
                  : ListView.separated(
                      itemCount: matches.length,
                      separatorBuilder: (_, _) => Divider(
                        height: 1,
                        color: colors.outlineVariant,
                      ),
                      itemBuilder: (context, index) {
                        final city = matches[index];
                        final selected = city.id == widget.selectedId;
                        return ListTile(
                          title: Text(city.city),
                          subtitle: Text(city.country),
                          trailing: selected
                              ? Icon(Icons.check, color: colors.primary)
                              : null,
                          selected: selected,
                          selectedTileColor: colors.secondaryContainer,
                          onTap: () => Navigator.of(context).pop(city),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

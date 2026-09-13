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
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
            child: TextField(
              controller: _query,
              autofocus: true,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Search',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _query.text.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          _query.clear();
                          setState(() {});
                        },
                        icon: const Icon(Icons.close),
                      ),
                filled: true,
                fillColor: colors.surfaceContainerLow,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (_) => setState(() {}),
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
                        title: Text(
                          city.city,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(city.country),
                        trailing: selected
                            ? Icon(Icons.check, color: colors.primary)
                            : null,
                        selected: selected,
                        selectedTileColor: colors.primaryContainer.withValues(
                          alpha: 0.45,
                        ),
                        onTap: () => Navigator.of(context).pop(city),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

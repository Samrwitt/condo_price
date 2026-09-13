import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/capital.dart';

class CapitalsRepository {
  const CapitalsRepository({
    this.assetPath = 'assets/data/capitals.json',
  });

  final String assetPath;

  Future<CapitalsCatalog> load() async {
    final raw = await rootBundle.loadString(assetPath);
    final json = jsonDecode(raw) as Map<String, dynamic>;
    return CapitalsCatalog.fromJson(json);
  }
}

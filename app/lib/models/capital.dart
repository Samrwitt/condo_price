import 'dart:math' as math;

import '../format.dart';

class ListingPhotoRef {
  const ListingPhotoRef({
    required this.url,
    required this.m2,
  });

  final String url;
  final double m2;

  factory ListingPhotoRef.fromJson(Object? json) {
    if (json is String) {
      return ListingPhotoRef(url: json, m2: 80);
    }
    final map = json as Map<String, dynamic>;
    return ListingPhotoRef(
      url: map['url'] as String,
      m2: (map['m2'] as num).toDouble(),
    );
  }
}

/// Per-city linear regression on log(USD/m²), exported from the training script.
class PriceModel {
  const PriceModel({
    required this.n,
    required this.weights,
    required this.mean,
    required this.std,
    required this.defaults,
    required this.profile,
  });

  final int n;
  final List<double> weights;
  final List<double> mean;
  final List<double> std;
  final Map<String, double> defaults;
  final Map<String, double> profile;

  factory PriceModel.fromJson(Map<String, dynamic> json) {
    double readDefault(String key, double fallback) {
      final value = json['defaults']?[key] ?? json['profile']?[key];
      if (value is num) return value.toDouble();
      return fallback;
    }

    final defaults = <String, double>{
      'rooms': readDefault('rooms', 2),
      'bedrooms': readDefault('bedrooms', 1),
      'bathrooms': readDefault('bathrooms', 1),
      'year': readDefault('year', 2010),
      'building_floors': readDefault('building_floors', 5),
      'apartment_floor': readDefault('apartment_floor', 2),
    };
    final profileRaw = json['profile'] as Map<String, dynamic>? ?? const {};
    final profile = <String, double>{
      for (final key in defaults.keys)
        key: (profileRaw[key] as num?)?.toDouble() ?? defaults[key]!,
    };

    return PriceModel(
      n: json['n'] as int? ?? 0,
      weights: (json['weights'] as List<dynamic>)
          .map((item) => (item as num).toDouble())
          .toList(),
      mean: (json['mean'] as List<dynamic>)
          .map((item) => (item as num).toDouble())
          .toList(),
      std: (json['std'] as List<dynamic>)
          .map((item) => (item as num).toDouble())
          .toList(),
      defaults: defaults,
      profile: profile,
    );
  }

  List<double> _featuresFor(num areaM2) {
    final area = areaM2.toDouble();
    final rooms = profile['rooms']!;
    final bedrooms = profile['bedrooms']!;
    final bathrooms = profile['bathrooms']!;
    final year = profile['year']!;
    final buildingFloors = profile['building_floors']!;
    final apartmentFloor = profile['apartment_floor']!;
    return [
      1.0,
      area,
      math.log(math.max(area, 1.0)),
      rooms,
      0.0,
      bedrooms,
      0.0,
      bathrooms,
      0.0,
      year,
      0.0,
      buildingFloors,
      0.0,
      apartmentFloor,
      0.0,
    ];
  }

  double predictPpm2(num areaM2) {
    final raw = _featuresFor(areaM2);
    if (raw.length != weights.length ||
        raw.length != mean.length ||
        raw.length != std.length) {
      throw StateError('Model feature size mismatch');
    }
    var logPpm2 = 0.0;
    for (var i = 0; i < raw.length; i++) {
      final scale = std[i].abs() < 1e-8 ? 1.0 : std[i];
      final z = (raw[i] - mean[i]) / scale;
      logPpm2 += z * weights[i];
    }
    return math.exp(logPpm2);
  }

  int predictPrice(num areaM2) => (predictPpm2(areaM2) * areaM2).round();
}

class Capital {
  const Capital({
    required this.id,
    required this.city,
    required this.country,
    required this.listingCount,
    required this.medianUsdPerM2,
    required this.p25UsdPerM2,
    required this.p75UsdPerM2,
    required this.price80m2,
    this.indicative = false,
    this.photos = const [],
    this.model,
  });

  final String id;
  final String city;
  final String country;
  final int listingCount;
  final double medianUsdPerM2;
  final double p25UsdPerM2;
  final double p75UsdPerM2;
  final int price80m2;
  final bool indicative;
  final List<ListingPhotoRef> photos;
  final PriceModel? model;

  bool get hasModel => model != null;

  int priceFor(num m2) => (medianUsdPerM2 * m2).round();
  int rangeLowFor(num m2) => (p25UsdPerM2 * m2).round();
  int rangeHighFor(num m2) => (p75UsdPerM2 * m2).round();

  int? modelPriceFor(num m2) {
    final trained = model;
    if (trained == null) return null;
    return trained.predictPrice(m2);
  }

  double? modelPpm2For(num m2) {
    final trained = model;
    if (trained == null) return null;
    return trained.predictPpm2(m2);
  }

  String get label => '$city, $country';

  /// Photos from listings closest to [sizeM2], for thumbnails and gallery.
  List<ListingPhotoRef> photosNear(num sizeM2, {int limit = 4}) {
    if (photos.isEmpty) return const [];
    final ranked = [...photos]
      ..sort((a, b) {
        final byArea = (a.m2 - sizeM2).abs().compareTo((b.m2 - sizeM2).abs());
        if (byArea != 0) return byArea;
        return a.url.compareTo(b.url);
      });
    final picked = <ListingPhotoRef>[];
    final seen = <String>{};
    for (final photo in ranked) {
      if (!seen.add(photo.url)) continue;
      picked.add(photo);
      if (picked.length >= limit) break;
    }
    return picked;
  }

  String? heroPhotoFor(num sizeM2) {
    final near = photosNear(sizeM2, limit: 1);
    return near.isEmpty ? null : near.first.url;
  }

  int cheapestRankAmong(List<Capital> cities) {
    final ordered = [...cities]
      ..sort((a, b) => a.medianUsdPerM2.compareTo(b.medianUsdPerM2));
    return ordered.indexWhere((item) => item.id == id) + 1;
  }

  String rankLabelAmong(List<Capital> cities) {
    final rank = cheapestRankAmong(cities);
    return '${formatOrdinal(rank)} cheapest of ${cities.length}';
  }

  factory Capital.fromJson(Map<String, dynamic> json) {
    final listingCount = json['listingCount'] as int;
    final photos = (json['photos'] as List<dynamic>? ?? const [])
        .map(ListingPhotoRef.fromJson)
        .where((photo) => photo.url.isNotEmpty)
        .toList();
    final modelJson = json['model'] as Map<String, dynamic>?;
    return Capital(
      id: json['id'] as String,
      city: json['city'] as String,
      country: json['country'] as String,
      listingCount: listingCount,
      medianUsdPerM2: (json['medianUsdPerM2'] as num).toDouble(),
      p25UsdPerM2: (json['p25UsdPerM2'] as num).toDouble(),
      p75UsdPerM2: (json['p75UsdPerM2'] as num).toDouble(),
      price80m2: json['price80m2'] as int,
      indicative: json['indicative'] as bool? ?? listingCount < 200,
      photos: photos,
      model: modelJson == null ? null : PriceModel.fromJson(modelJson),
    );
  }
}

class CapitalsCatalog {
  const CapitalsCatalog({
    required this.standardM2,
    required this.source,
    required this.cities,
    this.indicativeBelow = 200,
    this.coverage =
        'Median condo prices for the capitals in this listing set.',
    this.method =
        'Median USD per m² from apartment listings in the city itself.',
    this.modelNote = '',
  });

  final double standardM2;
  final String source;
  final List<Capital> cities;
  final int indicativeBelow;
  final String coverage;
  final String method;
  final String modelNote;

  factory CapitalsCatalog.fromJson(Map<String, dynamic> json) {
    final cities = (json['cities'] as List<dynamic>)
        .map((item) => Capital.fromJson(item as Map<String, dynamic>))
        .toList();
    return CapitalsCatalog(
      standardM2: (json['standardM2'] as num).toDouble(),
      source: json['source'] as String,
      cities: cities,
      indicativeBelow: json['indicativeBelow'] as int? ?? 200,
      coverage: json['coverage'] as String? ??
          'Median condo prices for the capitals in this listing set.',
      method: json['method'] as String? ??
          'Median USD per m² from apartment listings in the city itself.',
      modelNote: json['modelNote'] as String? ?? '',
    );
  }
}

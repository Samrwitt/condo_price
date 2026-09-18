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

class ModelDriver {
  const ModelDriver({
    required this.label,
    required this.pushesUp,
  });

  final String label;
  final bool pushesUp;
}

class ModelExplanation {
  const ModelExplanation({
    required this.vsMedian,
    required this.gapPct,
    required this.assumes,
    required this.drivers,
  });

  /// 'higher', 'lower', or 'close'
  final String vsMedian;
  final double gapPct;
  final String assumes;
  final List<ModelDriver> drivers;
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

  static const _featureNames = [
    'bias',
    'area',
    'log_area',
    'rooms',
    'rooms_missing',
    'bedrooms',
    'bedrooms_missing',
    'bathrooms',
    'bathrooms_missing',
    'year',
    'year_missing',
    'building_floors',
    'building_floors_missing',
    'apartment_floor',
    'apartment_floor_missing',
  ];

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

  List<double> _contributions(num areaM2) {
    final raw = _featuresFor(areaM2);
    if (raw.length != weights.length ||
        raw.length != mean.length ||
        raw.length != std.length) {
      throw StateError('Model feature size mismatch');
    }
    return [
      for (var i = 0; i < raw.length; i++)
        ((raw[i] - mean[i]) / (std[i].abs() < 1e-8 ? 1.0 : std[i])) *
            weights[i],
    ];
  }

  double predictPpm2(num areaM2) {
    final parts = _contributions(areaM2);
    var logPpm2 = 0.0;
    for (final part in parts) {
      logPpm2 += part;
    }
    return math.exp(logPpm2);
  }

  int predictPrice(num areaM2) => (predictPpm2(areaM2) * areaM2).round();

  /// Plain-language reasons the model sits above/below the city median.
  ModelExplanation explain(num areaM2, double medianPpm2) {
    final modelPpm2 = predictPpm2(areaM2);
    final gapPct = medianPpm2 <= 0
        ? 0.0
        : ((modelPpm2 - medianPpm2) / medianPpm2) * 100;
    final vsMedian = gapPct.abs() < 5
        ? 'close'
        : (gapPct > 0 ? 'higher' : 'lower');

    final rooms = profile['rooms']!;
    final bedrooms = profile['bedrooms']!;
    final bathrooms = profile['bathrooms']!;
    final year = profile['year']!;
    final floors = profile['building_floors']!;
    final aptFloor = profile['apartment_floor']!;
    final yearText = year >= 1800 && year <= 2100
        ? 'built ~${year.round()}'
        : 'build year unknown';
    final assumes =
        'Assumes ~${rooms.round()} rooms / ${bedrooms.round()} bed / '
        '${bathrooms.round()} bath, $yearText, floor ${aptFloor.round()} '
        'in a ${floors.round()}-story building';

    final parts = _contributions(areaM2);
    final raw = _featuresFor(areaM2);
    final scored = <({String name, double contrib, double value, double avg})>[];
    for (var i = 0; i < parts.length; i++) {
      final name = _featureNames[i];
      if (name == 'bias' || name.endsWith('_missing')) continue;
      if (parts[i].abs() < 0.015) continue;
      scored.add((
        name: name,
        contrib: parts[i],
        value: raw[i],
        avg: mean[i],
      ));
    }
    scored.sort((a, b) => b.contrib.abs().compareTo(a.contrib.abs()));

    final drivers = <ModelDriver>[];
    for (final item in scored.take(3)) {
      final phrase = _driverPhrase(
        item.name,
        item.value,
        item.avg,
        item.contrib,
      );
      if (phrase == null) continue;
      drivers.add(ModelDriver(label: phrase, pushesUp: item.contrib > 0));
    }

    return ModelExplanation(
      vsMedian: vsMedian,
      gapPct: gapPct,
      assumes: assumes,
      drivers: drivers,
    );
  }

  static String? _driverPhrase(
    String name,
    double value,
    double avg,
    double contrib,
  ) {
    final up = contrib > 0;
    final effect = up ? 'pushes model up' : 'pulls model down';
    switch (name) {
      case 'area':
      case 'log_area':
        if (value > avg * 1.05) {
          return 'Larger than typical listing size $effect';
        }
        if (value < avg * 0.95) {
          return 'Smaller than typical listing size $effect';
        }
        return 'Size mix vs city average $effect';
      case 'year':
        if (value < 1800 || value > 2100) {
          return 'Odd build-year data $effect';
        }
        if (value > avg + 5) {
          return 'Newer build (~${value.round()} vs avg ${avg.round()}) $effect';
        }
        if (value < avg - 5) {
          return 'Older build (~${value.round()} vs avg ${avg.round()}) $effect';
        }
        return 'Build year $effect';
      case 'rooms':
        return value > avg
            ? 'More rooms than avg (~${value.round()} vs ${avg.round()}) $effect'
            : 'Fewer rooms than avg (~${value.round()} vs ${avg.round()}) $effect';
      case 'bedrooms':
        return value > avg
            ? 'More bedrooms than avg $effect'
            : 'Fewer bedrooms than avg $effect';
      case 'bathrooms':
        return value > avg
            ? 'More bathrooms than avg $effect'
            : 'Fewer bathrooms than avg $effect';
      case 'building_floors':
        return value > avg
            ? 'Taller building (~${value.round()} floors) $effect'
            : 'Lower-rise building (~${value.round()} floors) $effect';
      case 'apartment_floor':
        return value > avg
            ? 'Higher floor (~${value.round()}) $effect'
            : 'Lower floor (~${value.round()}) $effect';
      default:
        return null;
    }
  }
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

  ModelExplanation? modelExplanationFor(num m2) {
    final trained = model;
    if (trained == null) return null;
    return trained.explain(m2, medianUsdPerM2);
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

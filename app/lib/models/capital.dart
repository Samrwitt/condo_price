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

  int priceFor(num m2) => (medianUsdPerM2 * m2).round();
  int rangeLowFor(num m2) => (p25UsdPerM2 * m2).round();
  int rangeHighFor(num m2) => (p75UsdPerM2 * m2).round();

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
  });

  final double standardM2;
  final String source;
  final List<Capital> cities;
  final int indicativeBelow;
  final String coverage;
  final String method;

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
    );
  }
}

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
  });

  final String id;
  final String city;
  final String country;
  final int listingCount;
  final double medianUsdPerM2;
  final double p25UsdPerM2;
  final double p75UsdPerM2;
  final int price80m2;

  int get rangeLow80 => (p25UsdPerM2 * 80).round();
  int get rangeHigh80 => (p75UsdPerM2 * 80).round();

  String get label => '$city, $country';

  factory Capital.fromJson(Map<String, dynamic> json) {
    return Capital(
      id: json['id'] as String,
      city: json['city'] as String,
      country: json['country'] as String,
      listingCount: json['listingCount'] as int,
      medianUsdPerM2: (json['medianUsdPerM2'] as num).toDouble(),
      p25UsdPerM2: (json['p25UsdPerM2'] as num).toDouble(),
      p75UsdPerM2: (json['p75UsdPerM2'] as num).toDouble(),
      price80m2: json['price80m2'] as int,
    );
  }
}

class CapitalsCatalog {
  const CapitalsCatalog({
    required this.standardM2,
    required this.source,
    required this.cities,
  });

  final double standardM2;
  final String source;
  final List<Capital> cities;

  factory CapitalsCatalog.fromJson(Map<String, dynamic> json) {
    final cities = (json['cities'] as List<dynamic>)
        .map((item) => Capital.fromJson(item as Map<String, dynamic>))
        .toList();
    return CapitalsCatalog(
      standardM2: (json['standardM2'] as num).toDouble(),
      source: json['source'] as String,
      cities: cities,
    );
  }
}

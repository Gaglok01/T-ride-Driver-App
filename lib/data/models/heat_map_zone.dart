class HeatMapZone {
  final int id;
  final String name;
  final String? description;
  final double lat;
  final double lng;
  final int radiusMeters;
  final String demandLevel;
  final double surgeMultiplier;
  final double priceMultiplier;

  HeatMapZone({
    required this.id,
    required this.name,
    this.description,
    required this.lat,
    required this.lng,
    required this.radiusMeters,
    required this.demandLevel,
    required this.surgeMultiplier,
    required this.priceMultiplier,
  });

  factory HeatMapZone.fromJson(Map<String, dynamic> json) {
    return HeatMapZone(
      id: int.tryParse(json['id'].toString()) ?? 0,
      name: json['name']?.toString() ?? 'Demand zone',
      description: json['description']?.toString(),
      lat: double.tryParse(json['lat'].toString()) ?? 0,
      lng: double.tryParse(json['lng'].toString()) ?? 0,
      radiusMeters: int.tryParse(json['radius_meters'].toString()) ?? 2000,
      demandLevel: json['demand_level']?.toString() ?? 'normal',
      surgeMultiplier:
          double.tryParse(json['surge_multiplier'].toString()) ?? 1.0,
      priceMultiplier:
          double.tryParse(json['price_multiplier'].toString()) ?? 1.0,
    );
  }
}

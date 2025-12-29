class Airport {
  final String city;
  final String airport;
  final String code;
  final String country;

  Airport({
    required this.city,
    required this.airport,
    required this.code,
    required this.country,
  });

  factory Airport.fromJson(Map<String, dynamic> j) {
    return Airport(
      city: j['city'],
      airport: j['name'],
      code: j['iata'],
      country: j['country'],
    );
  }

  factory Airport.fromFirestore(Map<String, dynamic> d) {
    return Airport(
      city: d['city'],
      airport: d['name'],
      code: d['iata'],
      country: d['country'],
    );
  }
}

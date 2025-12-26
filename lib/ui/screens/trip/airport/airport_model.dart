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
}

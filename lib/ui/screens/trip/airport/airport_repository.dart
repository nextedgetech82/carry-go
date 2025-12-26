import 'dart:convert';
import 'package:flutter/services.dart';
import 'airport_model.dart';

class AirportRepository {
  static List<Airport>? _cache;

  /// Load JSON ONLY ONCE (lazy)
  static Future<void> _loadIfNeeded() async {
    if (_cache != null) return;

    final jsonStr = await rootBundle.loadString('assets/airports.json');

    final List list = jsonDecode(jsonStr);
    _cache = list.map((e) => Airport.fromJson(e)).toList();
  }

  /// Search airports (MIN 3 chars)
  static Future<List<Airport>> search(String query) async {
    if (query.length < 3) return [];

    await _loadIfNeeded();

    final q = query.toLowerCase();

    return _cache!
        .where(
          (a) =>
              a.city.toLowerCase().startsWith(q) ||
              a.code.toLowerCase().startsWith(q) ||
              a.airport.toLowerCase().contains(q),
        )
        .take(15)
        .toList();
  }
}

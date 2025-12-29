import 'dart:convert';
import 'package:carrygo/ui/screens/trip/airport/airport.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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

class AirportRepo {
  static final List<Airport> _cache = [...airports];
  static bool _firebaseLoaded = false;

  /// 🔥 Load Firebase airports ONCE
  static Future<void> loadFromFirebase() async {
    if (_firebaseLoaded) return;

    final snap = await FirebaseFirestore.instance.collection('airports').get();

    for (final d in snap.docs) {
      _cache.add(Airport.fromFirestore(d.data()));
    }

    _firebaseLoaded = true;
  }

  /// 🔍 Search (sync)
  static Iterable<Airport> search(String query) {
    final q = query.toLowerCase();

    return _cache.where(
      (a) =>
          a.city.toLowerCase().startsWith(q) ||
          a.code.toLowerCase().startsWith(q) ||
          a.airport.toLowerCase().contains(q),
    );
  }
}

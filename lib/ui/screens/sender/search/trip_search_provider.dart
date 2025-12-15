import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

final tripSearchFilterProvider =
    StateNotifierProvider<TripSearchFilterController, TripSearchFilterState>(
      (ref) => TripSearchFilterController(),
    );

class TripSearchFilterState {
  final String fromCity;
  final String toCity;

  const TripSearchFilterState({this.fromCity = '', this.toCity = ''});
}

class TripSearchFilterController extends StateNotifier<TripSearchFilterState> {
  TripSearchFilterController() : super(const TripSearchFilterState());

  void setFromCity(String v) =>
      state = TripSearchFilterState(fromCity: v, toCity: state.toCity);

  void setToCity(String v) =>
      state = TripSearchFilterState(fromCity: state.fromCity, toCity: v);
}

final tripSearchProvider =
    StreamProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
      final filters = ref.watch(tripSearchFilterProvider);

      Query<Map<String, dynamic>> query = FirebaseFirestore.instance
          .collection('trips')
          .where('status', isEqualTo: 'active')
          .where('availableWeightKg', isGreaterThan: 0);

      if (filters.fromCity.isNotEmpty) {
        query = query.where(
          'fromCity',
          isEqualTo: filters.fromCity.toUpperCase(),
        );
      }

      if (filters.toCity.isNotEmpty) {
        query = query.where('toCity', isEqualTo: filters.toCity.toUpperCase());
      }

      return query.snapshots().map((s) => s.docs.map((d) => d.data()).toList());
    });

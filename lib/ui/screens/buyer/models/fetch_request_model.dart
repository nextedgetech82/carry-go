import 'package:cloud_firestore/cloud_firestore.dart';

class FetchRequestModel {
  final String fromCity;
  final String toCity;
  final String itemName;
  final double weight;
  final int quantity;
  final double budget;
  final DateTime deadline;

  FetchRequestModel({
    required this.fromCity,
    required this.toCity,
    required this.itemName,
    required this.weight,
    required this.quantity,
    required this.budget,
    required this.deadline,
  });

  Map<String, dynamic> toMap(String buyerId) {
    return {
      'buyerId': buyerId,
      'fromCity': fromCity,
      'toCity': toCity,
      'itemName': itemName,
      'weight': weight,
      'quantity': quantity,
      'budget': budget,
      'deadline': deadline,
      'status': 'pending',
      'createdAt': DateTime.now(),
    };
  }

  factory FetchRequestModel.fromMap(Map<String, dynamic> map) {
    return FetchRequestModel(
      fromCity: map['fromCity'],
      toCity: map['toCity'],
      itemName: map['itemName'],
      weight: (map['weight'] ?? 0).toDouble(),
      quantity: map['quantity'],
      budget: (map['budget'] ?? 0).toDouble(),
      deadline: (map['deadline'] as Timestamp).toDate(),
    );
  }
}

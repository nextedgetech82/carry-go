import 'package:cloud_firestore/cloud_firestore.dart';

class FetchRequestModel {
  final String id;
  final String buyerId;
  final String fromCity;
  final String toCity;
  final String itemName;
  final double weight;
  final int quantity;
  final double budget;
  final DateTime deadline;
  final String status;

  FetchRequestModel({
    required this.id,
    required this.buyerId,
    required this.fromCity,
    required this.toCity,
    required this.itemName,
    required this.weight,
    required this.quantity,
    required this.budget,
    required this.deadline,
    required this.status,
  });

  Map<String, dynamic> toMap() {
    return {
      'buyerId': buyerId,
      'fromCity': fromCity,
      'toCity': toCity,
      'itemName': itemName,
      'weight': weight,
      'quantity': quantity,
      'budget': budget,
      'deadline': deadline,
      'status': status,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  factory FetchRequestModel.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final d = doc.data()!;
    return FetchRequestModel(
      id: doc.id,
      buyerId: d['buyerId'],
      fromCity: d['fromCity'],
      toCity: d['toCity'],
      itemName: d['itemName'],
      weight: (d['weight'] ?? 0).toDouble(),
      quantity: d['quantity'],
      budget: (d['budget'] ?? 0).toDouble(),
      deadline: (d['deadline'] as Timestamp).toDate(),
      status: d['status'],
    );
  }
}

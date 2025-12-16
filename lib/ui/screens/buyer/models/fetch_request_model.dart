class FetchRequestModel {
  final String itemName;
  final double weight;
  final int quantity;
  final double budget;
  final DateTime deadline;

  FetchRequestModel({
    required this.itemName,
    required this.weight,
    required this.quantity,
    required this.budget,
    required this.deadline,
  });

  Map<String, dynamic> toMap(String buyerId) {
    return {
      'buyerId': buyerId,
      'itemName': itemName,
      'weight': weight,
      'quantity': quantity,
      'budget': budget,
      'deadline': deadline,
      'status': 'pending',
      'createdAt': DateTime.now(),
    };
  }
}

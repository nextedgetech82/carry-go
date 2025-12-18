class FetchRequestInput {
  final String fromCity;
  final String toCity;
  final String itemName;
  final double weight;
  final int quantity;
  final double budget;
  final DateTime deadline;

  FetchRequestInput({
    required this.fromCity,
    required this.toCity,
    required this.itemName,
    required this.weight,
    required this.quantity,
    required this.budget,
    required this.deadline,
  });
}

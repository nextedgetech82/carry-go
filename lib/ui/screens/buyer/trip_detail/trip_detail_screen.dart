import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/fetch_request_model.dart';

class TripDetailScreen extends StatelessWidget {
  final QueryDocumentSnapshot<Map<String, dynamic>> tripDoc;

  final FetchRequestModel? request;

  const TripDetailScreen({super.key, required this.tripDoc, this.request});

  //final FetchRequestModel request;

  // const TripDetailScreen({
  //   super.key,
  //   required this.tripDoc,
  //   required this.request,
  // });

  @override
  Widget build(BuildContext context) {
    final trip = tripDoc.data();

    final availableWeight = (trip['availableWeightKg'] ?? 0).toDouble();
    final pricePerKg = (trip['pricePerKg'] ?? 0).toDouble();

    //final requiredWeight = request.weight;
    //final totalPrice = requiredWeight * pricePerKg;

    //final canCarry = availableWeight >= requiredWeight;
    //final withinBudget = totalPrice <= request.budget;

    final requiredWeight = request?.weight ?? 0;
    final totalPrice = requiredWeight * pricePerKg;
    final withinBudget = request == null ? true : totalPrice <= request!.budget;

    final canCarry = availableWeight >= requiredWeight;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F9),
      appBar: AppBar(title: const Text('Trip Details')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _RouteCard(trip: trip),
          const SizedBox(height: 16),

          _TravellerCard(trip: trip),
          const SizedBox(height: 16),

          _CargoCard(
            availableWeight: availableWeight,
            requiredWeight: requiredWeight,
          ),
          const SizedBox(height: 16),

          _PriceCard(
            pricePerKg: pricePerKg,
            requiredWeight: requiredWeight,
            totalPrice: totalPrice,
            budget: request?.budget ?? 0,
            withinBudget: withinBudget,
          ),

          const SizedBox(height: 24),

          _SendRequestButton(
            //enabled: canCarry && withinBudget,
            enabled: request != null && canCarry && withinBudget,
            onPressed: () {
              // NEXT STEP:
              // create request-trip link
              // navigate to request detail
            },
          ),
        ],
      ),
    );
  }
}

class _RouteCard extends StatelessWidget {
  final Map<String, dynamic> trip;

  const _RouteCard({required this.trip});

  @override
  Widget build(BuildContext context) {
    final departure = (trip['departureDate'] as Timestamp).toDate();
    final arrival = (trip['arrivalDate'] as Timestamp).toDate();

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${trip['fromCity']} → ${trip['toCity']}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'Departure: ${_fmt(departure)}\nArrival: ${_fmt(arrival)}',
              style: TextStyle(color: Colors.grey.shade700),
            ),
          ],
        ),
      ),
    );
  }

  String _fmt(DateTime d) => '${d.day}/${d.month}/${d.year}';
}

class _TravellerCard extends StatelessWidget {
  final Map<String, dynamic> trip;

  const _TravellerCard({required this.trip});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: const CircleAvatar(radius: 24, child: Icon(Icons.person)),
        title: const Text(
          'Traveller',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(trip['notes'] ?? 'Verified traveller'),
        trailing: const Icon(Icons.verified, color: Colors.blue),
      ),
    );
  }
}

class _CargoCard extends StatelessWidget {
  final double availableWeight;
  final double requiredWeight;

  const _CargoCard({
    required this.availableWeight,
    required this.requiredWeight,
  });

  @override
  Widget build(BuildContext context) {
    final ok = availableWeight >= requiredWeight;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              ok ? Icons.check_circle : Icons.error,
              color: ok ? Colors.green : Colors.red,
            ),
            const SizedBox(width: 10),
            Text(
              'Available: $availableWeight kg • Required: $requiredWeight kg',
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

class _PriceCard extends StatelessWidget {
  final double pricePerKg;
  final double requiredWeight;
  final double totalPrice;
  final double budget;
  final bool withinBudget;

  const _PriceCard({
    required this.pricePerKg,
    required this.requiredWeight,
    required this.totalPrice,
    required this.budget,
    required this.withinBudget,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Price Calculation',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text('₹$pricePerKg × $requiredWeight kg'),
            const SizedBox(height: 4),
            Text(
              'Total: ₹$totalPrice',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'Your Budget: ₹$budget',
              style: TextStyle(color: withinBudget ? Colors.green : Colors.red),
            ),
          ],
        ),
      ),
    );
  }
}

class _SendRequestButton extends StatelessWidget {
  final bool enabled;
  final VoidCallback onPressed;

  const _SendRequestButton({required this.enabled, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: enabled ? onPressed : null,
      style: ElevatedButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: Text(
        enabled ? 'Send Request' : 'Cannot Send Request',
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    );
  }
}

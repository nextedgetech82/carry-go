import 'package:carrygo/ui/screens/buyer/requests/active_buyer_request_provider.dart';
import 'package:carrygo/ui/screens/buyer/sendrequest/sendtrip_request_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/fetch_request_model.dart';

class TripDetailScreen extends ConsumerWidget {
  final QueryDocumentSnapshot<Map<String, dynamic>> tripDoc;

  //final FetchRequestModel? request;

  const TripDetailScreen({super.key, required this.tripDoc});

  //final FetchRequestModel request;

  // const TripDetailScreen({
  //   super.key,
  //   required this.tripDoc,
  //   required this.request,
  // });

  @override
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trip = tripDoc.data();

    final availableWeight = (trip['availableWeightKg'] ?? 0).toDouble();
    final pricePerKg = (trip['pricePerKg'] ?? 0).toDouble();

    final requestsAsync = ref.watch(buyerOpenRequestsProvider);
    final selectedRequestId = ref.watch(selectedBuyerRequestIdProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F9),
      appBar: AppBar(title: const Text('Trip Details')),
      body: requestsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (requests) {
          /// 🔥 Resolve selected request from ID
          final selectedRequest = requests
              .where((r) => r.id == selectedRequestId)
              .cast<FetchRequestModel?>()
              .firstOrNull;

          final requiredWeight = selectedRequest?.weight ?? 0;
          final totalPrice = requiredWeight * pricePerKg;
          final withinBudget =
              selectedRequest != null && totalPrice <= selectedRequest.budget;
          final canCarry = availableWeight >= requiredWeight;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _RouteCard(trip: trip),
              const SizedBox(height: 16),

              _TravellerCard(trip: trip),
              const SizedBox(height: 16),

              /// 🔹 SELECT REQUEST (ID-BASED)
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Select Request',
                  filled: true,
                ),
                value: selectedRequestId,
                items: requests.map((r) {
                  return DropdownMenuItem<String>(
                    value: r.id,
                    child: Text('${r.itemName} • ${r.weight} kg'),
                  );
                }).toList(),
                onChanged: (id) {
                  ref.read(selectedBuyerRequestIdProvider.notifier).state = id;
                },
              ),

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
                budget: selectedRequest?.budget ?? 0,
                withinBudget: withinBudget,
              ),

              const SizedBox(height: 24),

              _SendRequestButton(
                enabled: selectedRequest != null && canCarry && withinBudget,
                onPressed: () async {
                  if (selectedRequest == null) return;

                  await ref
                      .read(sendTripRequestProvider.notifier)
                      .send(tripDoc: tripDoc, request: selectedRequest);

                  /// 🔥 Reset selection
                  ref.read(selectedBuyerRequestIdProvider.notifier).state =
                      null;

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Request sent to traveller')),
                  );

                  Navigator.pop(context);
                },
              ),
            ],
          );
        },
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
              'Available: $availableWeight kg', // • Required: $requiredWeight kg',
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
            // const Text(
            //   'Price Calculation',
            //   style: TextStyle(fontWeight: FontWeight.w700),
            // ),
            const SizedBox(height: 8),
            Text('Price per Kg ₹$pricePerKg'),
            //const SizedBox(height: 4),
            // Text(
            //   'Total: ₹$totalPrice',
            //   style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            // ),
            //const SizedBox(height: 8),
            // Text(
            //   'Your Budget: ₹$budget',
            //   style: TextStyle(color: withinBudget ? Colors.green : Colors.red),
            // ),
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
      //onPressed: enabled ? onPressed : null,
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: Text(
        //enabled ? 'Send Request' : 'Cannot Send Request',
        'Send Request',
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    );
  }
}

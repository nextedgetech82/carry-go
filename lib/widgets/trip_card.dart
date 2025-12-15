import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class TripCard extends StatelessWidget {
  final Map<String, dynamic> trip;

  const TripCard({super.key, required this.trip});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// Route
          Text(
            '${trip['fromCity']} → ${trip['toCity']}',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 6),

          /// Dates
          Text(
            '${_fmt(trip['departureDate'])}  →  ${_fmt(trip['arrivalDate'])}',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
          ),

          const SizedBox(height: 12),

          /// Stats
          Row(
            children: [
              _InfoChip(
                icon: Icons.inventory_2,
                label: '${trip['availableWeightKg']} kg',
              ),
              const SizedBox(width: 12),
              _InfoChip(
                icon: Icons.currency_rupee,
                label: '${trip['pricePerKg']} /kg',
              ),
            ],
          ),

          const SizedBox(height: 12),

          /// Status
          Align(
            alignment: Alignment.centerRight,
            child: Chip(
              label: Text(
                trip['status'] ?? 'active',
                style: const TextStyle(color: Colors.white),
              ),
              backgroundColor: Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  static String _fmt(Timestamp t) =>
      t.toDate().toLocal().toString().split(' ')[0];
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 16, color: theme.colorScheme.primary),
        const SizedBox(width: 4),
        Text(label, style: theme.textTheme.bodySmall),
      ],
    );
  }
}

import 'package:carrygo/providers/trip_details_provider.dart';
import 'package:carrygo/ui/screens/trip/edit_trip_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TripDetailsScreen extends ConsumerWidget {
  final String tripId;

  const TripDetailsScreen({super.key, required this.tripId});

  String _formatDate(Timestamp ts) {
    final d = ts.toDate();
    return '${d.day}/${d.month}/${d.year}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final tripAsync = ref.watch(tripDetailsStreamProvider(tripId));
    final actions = ref.read(tripActionsProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Trip Details')),
      body: tripAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (trip) {
          final status = trip['status'] ?? 'active';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// 🔹 Route + Status
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${trip['fromCity']} → ${trip['toCity']}',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    _StatusBadge(status: status),
                  ],
                ),

                const SizedBox(height: 20),

                _InfoTile(
                  icon: Icons.calendar_today,
                  label: 'Travel Dates',
                  value:
                      '${_formatDate(trip['departureDate'])} → ${_formatDate(trip['arrivalDate'])}',
                ),

                _InfoTile(
                  icon: Icons.inventory_2,
                  label: 'Available Weight',
                  value: '${trip['availableWeightKg']} kg',
                ),

                _InfoTile(
                  icon: Icons.currency_rupee,
                  label: 'Price',
                  value: '₹${trip['pricePerKg']} per kg',
                ),

                if ((trip['notes'] ?? '').toString().isNotEmpty)
                  _InfoTile(
                    icon: Icons.note,
                    label: 'Notes',
                    value: trip['notes'],
                  ),

                const SizedBox(height: 32),

                /// 🔹 Actions
                if (status == 'active') ...[
                  _PrimaryButton(
                    label: 'Edit Trip',
                    icon: Icons.edit,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EditTripScreen(
                            tripId: tripId,
                            trip: trip, // latest snapshot data
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),

                  _OutlineButton(
                    label: 'Mark Completed',
                    icon: Icons.check_circle,
                    onPressed: () async {
                      await actions.updateStatus(
                        tripId: tripId,
                        status: 'completed',
                        context: context,
                      );
                    },
                  ),
                  const SizedBox(height: 12),

                  _DangerButton(
                    label: 'Cancel Trip',
                    icon: Icons.cancel,
                    onPressed: () async {
                      await actions.updateStatus(
                        tripId: tripId,
                        status: 'cancelled',
                        context: context,
                      );
                    },
                  ),
                  const SizedBox(height: 12),

                  _DangerButton(
                    label: 'Delete Trip',
                    icon: Icons.delete,
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text('Delete Trip'),
                          content: const Text(
                            'This will permanently hide the trip.\n\nAre you sure?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('No'),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                              ),
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Yes, Delete'),
                            ),
                          ],
                        ),
                      );

                      if (confirm == true) {
                        await actions.deleteTrip(
                          tripId: tripId,
                          context: context,
                        );

                        if (context.mounted) {
                          Navigator.pop(context); // go back to dashboard
                        }
                      }
                    },
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

/// ─────────────────────────────────────────────
/// STATUS BADGE
/// ─────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String text;

    switch (status) {
      case 'completed':
        color = Colors.green;
        text = 'Completed';
        break;
      case 'cancelled':
        color = Colors.red;
        text = 'Cancelled';
        break;
      default:
        color = Theme.of(context).colorScheme.primary;
        text = 'Active';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}

/// ─────────────────────────────────────────────
/// INFO TILE
/// ─────────────────────────────────────────────

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: theme.textTheme.bodySmall),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// ─────────────────────────────────────────────
/// BUTTONS
/// ─────────────────────────────────────────────

class _PrimaryButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  const _PrimaryButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        icon: Icon(icon),
        label: Text(label),
        onPressed: onPressed,
      ),
    );
  }
}

class _OutlineButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  const _OutlineButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton.icon(
        icon: Icon(icon),
        label: Text(label),
        onPressed: onPressed,
      ),
    );
  }
}

class _DangerButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  const _DangerButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
        icon: Icon(icon),
        label: Text(label),
        onPressed: onPressed,
      ),
    );
  }
}

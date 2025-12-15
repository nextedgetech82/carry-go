import 'package:carrygo/providers/trip_timeline_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TripTimelineScreen extends ConsumerWidget {
  final String tripId;

  const TripTimelineScreen({super.key, required this.tripId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final timelineAsync = ref.watch(tripTimelineProvider(tripId));

    return Scaffold(
      appBar: AppBar(title: const Text('Trip Activity'), centerTitle: true),
      body: timelineAsync.when(
        loading: () => const _LoadingState(),

        error: (e, _) => Center(
          child: Text(
            'Unable to load activity',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
        ),

        data: (events) {
          if (events.isEmpty) {
            return const _EmptyTimeline();
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            itemCount: events.length,
            itemBuilder: (context, index) {
              final event = events[index];
              return _PremiumTimelineTile(
                event: event,
                isLast: index == events.length - 1,
              );
            },
          );
        },
      ),
    );
  }
}

class _PremiumTimelineTile extends StatelessWidget {
  final Map<String, dynamic> event;
  final bool isLast;

  const _PremiumTimelineTile({required this.event, required this.isLast});

  String _formatDate(Timestamp ts) {
    final d = ts.toDate();
    return '${d.day}/${d.month}/${d.year} • '
        '${d.hour}:${d.minute.toString().padLeft(2, '0')}';
  }

  IconData _icon(String action) {
    switch (action) {
      case 'created':
        return Icons.add_circle;
      case 'edited':
        return Icons.edit;
      case 'completed':
        return Icons.check_circle;
      case 'cancelled':
        return Icons.cancel;
      case 'deleted':
        return Icons.delete;
      default:
        return Icons.info;
    }
  }

  Color _color(BuildContext context, String action) {
    switch (action) {
      case 'completed':
        return Colors.green;
      case 'cancelled':
      case 'deleted':
        return Colors.red;
      default:
        return Theme.of(context).colorScheme.primary;
    }
  }

  String _label(String action) {
    return action[0].toUpperCase() + action.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _color(context, event['action']);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// Timeline rail
        Column(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(_icon(event['action']), color: color, size: 20),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 70,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color.withOpacity(0.6), theme.dividerColor],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
          ],
        ),

        const SizedBox(width: 16),

        /// Content card
        Expanded(
          child: Container(
            margin: const EdgeInsets.only(bottom: 24),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(color: theme.dividerColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// Title + Badge
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        event['title'],
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    _ActionBadge(label: _label(event['action']), color: color),
                  ],
                ),

                const SizedBox(height: 6),

                /// Description
                Text(event['description'], style: theme.textTheme.bodyMedium),

                const SizedBox(height: 10),

                /// Time
                Text(
                  _formatDate(event['createdAt']),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.hintColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ActionBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _ActionBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator(strokeWidth: 2));
  }
}

class _EmptyTimeline extends StatelessWidget {
  const _EmptyTimeline();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 48, color: theme.hintColor),
          const SizedBox(height: 12),
          Text('No activity yet', style: theme.textTheme.titleMedium),
          const SizedBox(height: 6),
          Text(
            'All trip actions will appear here',
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

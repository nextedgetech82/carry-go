import 'package:flutter/material.dart';

class TimelineTile extends StatelessWidget {
  final String title;
  final String description;
  final String date;
  final String action;

  const TimelineTile({
    required this.title,
    required this.description,
    required this.date,
    required this.action,
  });

  Color _iconColor(BuildContext context) {
    switch (action) {
      case 'completed':
        return Colors.green;
      case 'cancelled':
      case 'deleted':
        return Colors.red;
      case 'updated':
        return Colors.orange;
      default:
        return Theme.of(context).colorScheme.primary;
    }
  }

  IconData _icon() {
    switch (action) {
      case 'completed':
        return Icons.check_circle;
      case 'cancelled':
        return Icons.cancel;
      case 'deleted':
        return Icons.delete;
      case 'updated':
        return Icons.edit;
      default:
        return Icons.flight_takeoff;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _iconColor(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(_icon(), color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(description, style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 2),
                Text(
                  date,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

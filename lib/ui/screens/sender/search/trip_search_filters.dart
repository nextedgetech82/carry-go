import 'package:carrygo/ui/screens/sender/search/trip_search_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TripSearchFilters extends ConsumerWidget {
  const TripSearchFilters({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filters = ref.watch(tripSearchFilterProvider);
    final notifier = ref.read(tripSearchFilterProvider.notifier);

    return Column(
      children: [
        TextField(
          decoration: const InputDecoration(labelText: 'From City'),
          onChanged: notifier.setFromCity,
        ),
        const SizedBox(height: 8),
        TextField(
          decoration: const InputDecoration(labelText: 'To City'),
          onChanged: notifier.setToCity,
        ),
      ],
    );
  }
}

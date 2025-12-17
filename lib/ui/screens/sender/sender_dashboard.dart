// import 'package:carrygo/ui/screens/sender/send_request_provider.dart'
//     show senderRequestsProvider;
// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';

// class SenderDashboard extends ConsumerWidget {
//   const SenderDashboard({super.key});

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final theme = Theme.of(context);
//     final requestsAsync = ref.watch(senderRequestsProvider);

//     return Scaffold(
//       appBar: AppBar(title: const Text('My Requests'), centerTitle: true),
//       body: requestsAsync.when(
//         loading: () => const Center(child: CircularProgressIndicator()),
//         error: (e, _) => Center(
//           child: Text(e.toString(), style: const TextStyle(color: Colors.red)),
//         ),
//         data: (requests) {
//           if (requests.isEmpty) {
//             return _EmptyState(theme: theme);
//           }

//           return ListView.builder(
//             padding: const EdgeInsets.all(16),
//             itemCount: requests.length,
//             itemBuilder: (context, index) {
//               final r = requests[index];
//               return Padding(
//                 padding: const EdgeInsets.only(bottom: 12),
//                 child: _RequestCard(request: r),
//               );
//             },
//           );
//         },
//       ),
//     );
//   }
// }

// class _RequestCard extends StatelessWidget {
//   final Map<String, dynamic> request;

//   const _RequestCard({required this.request});

//   Color _statusColor(String status, BuildContext context) {
//     switch (status) {
//       case 'accepted':
//         return Colors.green;
//       case 'rejected':
//         return Colors.red;
//       case 'completed':
//         return Colors.blue;
//       default:
//         return Theme.of(context).colorScheme.primary;
//     }
//   }

//   String _statusText(String status) {
//     switch (status) {
//       case 'accepted':
//         return 'Accepted';
//       case 'rejected':
//         return 'Rejected';
//       case 'completed':
//         return 'Completed';
//       default:
//         return 'Pending';
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);
//     final status = request['status'];

//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: theme.cardColor,
//         borderRadius: BorderRadius.circular(16),
//         border: Border.all(color: theme.dividerColor),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           /// Route + Status
//           Row(
//             children: [
//               Expanded(
//                 child: Text(
//                   '${request['fromCity']} → ${request['toCity']}',
//                   style: theme.textTheme.titleMedium?.copyWith(
//                     fontWeight: FontWeight.w600,
//                   ),
//                 ),
//               ),
//               _StatusBadge(
//                 text: _statusText(status),
//                 color: _statusColor(status, context),
//               ),
//             ],
//           ),

//           const SizedBox(height: 8),

//           /// Weight & Price
//           Row(
//             children: [
//               Icon(Icons.inventory_2, size: 16, color: theme.hintColor),
//               const SizedBox(width: 6),
//               Text(
//                 '${request['requestedWeightKg']} kg',
//                 style: theme.textTheme.bodySmall,
//               ),
//               const SizedBox(width: 16),
//               Icon(Icons.currency_rupee, size: 16, color: theme.hintColor),
//               const SizedBox(width: 4),
//               Text(
//                 '₹${request['totalPrice']}',
//                 style: theme.textTheme.bodySmall?.copyWith(
//                   fontWeight: FontWeight.w600,
//                 ),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
// }

// class _StatusBadge extends StatelessWidget {
//   final String text;
//   final Color color;

//   const _StatusBadge({required this.text, required this.color});

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
//       decoration: BoxDecoration(
//         color: color.withValues(alpha: 0.12),
//         borderRadius: BorderRadius.circular(20),
//         border: Border.all(color: color),
//       ),
//       child: Text(
//         text,
//         style: TextStyle(
//           color: color,
//           fontSize: 11,
//           fontWeight: FontWeight.w600,
//         ),
//       ),
//     );
//   }
// }

// class _EmptyState extends StatelessWidget {
//   final ThemeData theme;

//   const _EmptyState({required this.theme});

//   @override
//   Widget build(BuildContext context) {
//     return Center(
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Icon(Icons.send, size: 48, color: theme.hintColor),
//           const SizedBox(height: 12),
//           Text(
//             'No requests yet',
//             style: theme.textTheme.titleMedium?.copyWith(
//               fontWeight: FontWeight.w600,
//             ),
//           ),
//           const SizedBox(height: 4),
//           Text(
//             'Search trips and send requests',
//             style: theme.textTheme.bodySmall,
//           ),
//         ],
//       ),
//     );
//   }
// }

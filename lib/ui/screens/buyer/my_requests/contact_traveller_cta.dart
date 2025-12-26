import 'package:carrygo/ui/screens/buyer/my_requests/contact_launcher.dart';
import 'package:flutter/material.dart';

class ContactTravellerCTA extends StatelessWidget {
  final String travellerName;
  final String phone;

  const ContactTravellerCTA({
    super.key,
    required this.travellerName,
    required this.phone,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// HEADER
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.verified_user, color: Colors.green),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      travellerName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Traveller assigned',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          /// ACTION BUTTONS
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.call),
                  label: const Text('Call'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () async {
                    try {
                      await ContactLauncher.call(phone);
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Unable to make call')),
                      );
                    }
                  },
                ),
              ),
              // const SizedBox(width: 12),
              // Expanded(
              //   child: OutlinedButton.icon(
              //     icon: const Icon(Icons.chat),
              //     label: const Text('WhatsApp'),
              //     style: OutlinedButton.styleFrom(
              //       padding: const EdgeInsets.symmetric(vertical: 14),
              //       shape: RoundedRectangleBorder(
              //         borderRadius: BorderRadius.circular(14),
              //       ),
              //     ),
              //     onPressed: () async {
              //       try {
              //         ContactLauncher.whatsapp(
              //           phone,
              //           'Hi, I am contacting you regarding my Travel Fetcher request.',
              //         );
              //       } catch (e) {
              //         ScaffoldMessenger.of(context).showSnackBar(
              //           const SnackBar(content: Text('Unable to make call')),
              //         );
              //       }
              //     },
              //   ),
              // ),
            ],
          ),
        ],
      ),
    );
  }
}

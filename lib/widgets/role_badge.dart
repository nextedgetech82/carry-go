import 'package:flutter/material.dart';

class RoleBadge extends StatelessWidget {
  final String role;

  const RoleBadge({super.key, required this.role});

  @override
  Widget build(BuildContext context) {
    final isTraveller = role == 'traveller';

    final gradient = isTraveller
        ? const LinearGradient(
            colors: [Color(0xFF00C853), Color(0xFF69F0AE)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : const LinearGradient(
            colors: [Color(0xFFFF8F00), Color(0xFFFFD54F)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          );

    final icon = isTraveller ? Icons.flight_takeoff : Icons.inventory_2;
    final label = role.toUpperCase();

    return Tooltip(
      message: 'You are in ${isTraveller ? "Traveller" : "Buyer"} mode',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.18),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: Colors.white),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

IconData roleIcon(String role) {
  switch (role) {
    case 'traveller':
      return Icons.flight_takeoff_rounded; // ✈️
    case 'fetcher':
    case 'buyer':
      return Icons.local_shipping_rounded; // 📦
    default:
      return Icons.person_outline;
  }
}

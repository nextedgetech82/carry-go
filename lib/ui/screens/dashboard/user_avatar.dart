import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class UserAvatar extends StatelessWidget {
  final String? photoUrl;
  final String initials;
  final double size;
  final bool showRing;
  final String? role; // traveller / sender / buyer

  const UserAvatar({
    super.key,
    required this.initials,
    this.photoUrl,
    this.size = 48,
    this.showRing = false,
    this.role,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final ringGradient = _roleGradient(theme, role);

    return Container(
      padding: showRing ? const EdgeInsets.all(2.5) : EdgeInsets.zero,
      decoration: showRing
          ? BoxDecoration(shape: BoxShape.circle, gradient: ringGradient)
          : null,
      child: ClipOval(
        child: SizedBox(width: size, height: size, child: _buildImage(theme)),
      ),
    );
  }

  Widget _buildImage(ThemeData theme) {
    if (photoUrl != null && photoUrl!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: photoUrl!,
        fit: BoxFit.cover,
        fadeInDuration: const Duration(milliseconds: 250),

        /// 🔄 LOADING
        placeholder: (_, __) => _placeholder(theme, loading: true),

        /// ❌ ERROR
        errorWidget: (_, __, ___) => _placeholder(theme),
      );
    }

    return _placeholder(theme);
  }

  Widget _placeholder(ThemeData theme, {bool loading = false}) {
    return Container(
      color: Colors.white,
      alignment: Alignment.center,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Text(
            initials.isEmpty ? '?' : initials,
            style: TextStyle(
              fontSize: size * 0.38,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),

          if (loading)
            SizedBox(
              width: size * 0.45,
              height: size * 0.45,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: theme.colorScheme.primary.withOpacity(0.8),
              ),
            ),
        ],
      ),
    );
  }

  /// 🎨 ROLE-BASED GRADIENT
  LinearGradient _roleGradient(ThemeData theme, String? role) {
    switch (role) {
      case 'traveller':
        return const LinearGradient(
          colors: [Color(0xFF2196F3), Color(0xFF3F51B5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );

      case 'sender':
      case 'buyer':
        return const LinearGradient(
          colors: [Color(0xFFFF9800), Color(0xFFF44336)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );

      default:
        return LinearGradient(
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withOpacity(0.7),
          ],
        );
    }
  }
}

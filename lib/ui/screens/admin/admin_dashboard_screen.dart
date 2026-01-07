import 'package:carrygo/core/startup/startup_provider.dart';
import 'package:carrygo/providers/my_trips_provider.dart';
import 'package:carrygo/providers/user_profile_provider.dart';
import 'package:carrygo/ui/screens/admin/admin_dispute_detail_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
// keep your other imports

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    // optional confirm dialog
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    await FirebaseAuth.instance.signOut();

    // invalidate your providers (keep the ones you have)
    ref.invalidate(startupProvider);
    ref.invalidate(userProfileProvider);
    ref.invalidate(myTripsProvider);

    if (!context.mounted) return;

    Navigator.of(context).pushNamedAndRemoveUntil('/', (_) => false);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Dispute Management - Admin',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),

          // ✅ LOGOUT BUTTON (top-right)
          actions: [
            IconButton(
              tooltip: 'Logout',
              icon: const Icon(Icons.logout),
              onPressed: () => _logout(context, ref),
            ),
          ],

          bottom: const TabBar(
            tabs: [
              Tab(text: 'OPEN'),
              Tab(text: 'APPEALS'), // 🔥 NEW
              Tab(text: 'RESOLVED'),
            ],
          ),
        ),
        body: Column(
          children: [
            _AdminStatsHeader(),
            const Divider(height: 1),
            const Expanded(
              child: TabBarView(
                children: [
                  _DisputeList(statuses: ['OPEN']),
                  _DisputeList(statuses: ['APPEALED']), // 🔥 NEW
                  _DisputeList(
                    statuses: [
                      'RESOLVED',
                      'APPEAL_ACCEPTED',
                      'APPEAL_REJECTED',
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

//
// =======================
// 🔹 HEADER STATS
// =======================
//
class _AdminStatsHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('disputes').snapshots(),
      builder: (context, snap) {
        final docs = snap.data?.docs ?? [];

        final openCount = docs.where((d) => d['status'] == 'OPEN').length;
        final resolvedCount = docs
            .where(
              (d) =>
                  d['status'] == 'RESOLVED' ||
                  d['status'] == 'APPEAL_ACCEPTED' ||
                  d['status'] == 'APPEAL_REJECTED',
            )
            .length;

        final appealedCount = docs
            .where((d) => d['status'] == 'APPEALED')
            .length;

        final width = MediaQuery.of(context).size.width;
        final cardWidth = width > 600 ? (width - 64) / 3 : (width - 48) / 2;

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              SizedBox(
                width: cardWidth,
                child: _StatCard(
                  title: 'Open',
                  value: openCount.toString(),
                  color: Colors.orange,
                  icon: Icons.warning,
                ),
              ),
              SizedBox(
                width: cardWidth,
                child: _StatCard(
                  title: 'Appeals',
                  value: appealedCount.toString(),
                  color: Colors.red,
                  icon: Icons.gavel,
                ),
              ),
              SizedBox(
                width: cardWidth,
                child: _StatCard(
                  title: 'Resolved',
                  value: resolvedCount.toString(),
                  color: Colors.green,
                  icon: Icons.check_circle,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  final IconData icon;

  const _StatCard({
    required this.title,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color,
            child: Icon(icon, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 14, color: Colors.black54),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

//
// =======================
// 🔹 DISPUTE LIST
// =======================
//
class _DisputeList extends StatefulWidget {
  final List<String> statuses;

  const _DisputeList({required this.statuses});

  @override
  State<_DisputeList> createState() => _DisputeListState();
}

class _DisputeMeta {
  final String fromCity;
  final String toCity;
  final String itemName;
  final String buyerName;
  final String travellerName;

  const _DisputeMeta({
    required this.fromCity,
    required this.toCity,
    required this.itemName,
    required this.buyerName,
    required this.travellerName,
  });

  String blob() {
    return '${fromCity.trim()} ${toCity.trim()} ${itemName.trim()} ${buyerName.trim()} ${travellerName.trim()}'
        .toLowerCase();
  }
}

class _DisputeListState extends State<_DisputeList> {
  String? winnerFilter; // null | 'BUYER' | 'TRAVELLER'
  final TextEditingController _searchCtrl = TextEditingController();
  String _search = '';

  final Map<String, _DisputeMeta> _metaCache = {};
  final Set<String> _loadingMeta = {};

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _ensureMetaLoaded(
    Map<String, dynamic> dispute,
    String disputeId,
  ) async {
    if (_metaCache.containsKey(disputeId) || _loadingMeta.contains(disputeId))
      return;

    _loadingMeta.add(disputeId);

    try {
      final db = FirebaseFirestore.instance;

      // Trip
      final tripId = dispute['tripRequestId'] as String?;
      if (tripId == null || tripId.isEmpty) return;

      final tripSnap = await db.collection('trip_requests').doc(tripId).get();
      final trip = tripSnap.data() ?? {};

      final fromCity = (trip['fromCity'] ?? '').toString();
      final toCity = (trip['toCity'] ?? '').toString();
      final itemName = (trip['itemName'] ?? '').toString();

      // Users
      final buyerId = (dispute['buyerId'] ?? '').toString();
      final travellerId = (dispute['travellerId'] ?? '').toString();

      String buyerName = '';
      String travellerName = '';

      if (buyerId.isNotEmpty) {
        final u = await db.collection('users').doc(buyerId).get();
        final ud = u.data() ?? {};
        buyerName = '${(ud['firstName'] ?? '')} ${(ud['lastName'] ?? '')}'
            .trim();
      }
      if (travellerId.isNotEmpty) {
        final u = await db.collection('users').doc(travellerId).get();
        final ud = u.data() ?? {};
        travellerName = '${(ud['firstName'] ?? '')} ${(ud['lastName'] ?? '')}'
            .trim();
      }

      if (!mounted) return;

      setState(() {
        _metaCache[disputeId] = _DisputeMeta(
          fromCity: fromCity,
          toCity: toCity,
          itemName: itemName,
          buyerName: buyerName,
          travellerName: travellerName,
        );
      });
    } finally {
      _loadingMeta.remove(disputeId);
    }
  }

  bool _matchesSearch(Map<String, dynamic> dispute, String disputeId) {
    final q = _search.trim().toLowerCase();
    if (q.isEmpty) return true;

    final reason = (dispute['reason'] ?? '').toString().toLowerCase();
    final desc = (dispute['description'] ?? '').toString().toLowerCase();
    final resolvedBy = (dispute['resolvedBy'] ?? '').toString().toLowerCase();
    final tripId = (dispute['tripRequestId'] ?? '').toString().toLowerCase();

    final localBlob = '$reason $desc $resolvedBy $tripId $disputeId'
        .toLowerCase();

    // meta blob (cities/item/users) if loaded
    final metaBlob = _metaCache[disputeId]?.blob() ?? '';

    return localBlob.contains(q) || metaBlob.contains(q);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('disputes')
          .where('status', whereIn: widget.statuses)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snap.hasData) return const SizedBox.shrink();

        final allDocs = snap.data!.docs;

        // Preload meta for visible docs (so search by city/item/user works)
        for (final d in allDocs) {
          final data = d.data() as Map<String, dynamic>;
          _ensureMetaLoaded(data, d.id);
        }

        // ✅ Winner filter (only for RESOLVED)
        final afterWinnerFilter = allDocs.where((d) {
          if (widget.statuses.contains('RESOLVED') != 'RESOLVED') return true;
          if (winnerFilter == null) return true;
          final data = d.data() as Map<String, dynamic>;
          return (data['resolvedBy'] as String?) == winnerFilter;
        }).toList();

        // ✅ Search filter (city/item/user/reason/desc)
        final filteredDocs = afterWinnerFilter.where((d) {
          final data = d.data() as Map<String, dynamic>;
          return _matchesSearch(data, d.id);
        }).toList();

        return Column(
          children: [
            // ✅ SEARCH BAR (both tabs)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: TextField(
                controller: _searchCtrl,
                decoration: InputDecoration(
                  hintText: 'Search city / item / user / reason...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _search.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() => _search = '');
                          },
                        ),
                ),
                onChanged: (v) => setState(() => _search = v),
              ),
            ),

            // ✅ WINNER FILTER (only RESOLVED tab) — ALWAYS visible
            if (widget.statuses.contains('RESOLVED'))
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
                child: Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    ChoiceChip(
                      label: const Text('All'),
                      selected: winnerFilter == null,
                      onSelected: (_) => setState(() => winnerFilter = null),
                    ),
                    ChoiceChip(
                      label: const Text('Buyer Wins'),
                      selected: winnerFilter == 'BUYER',
                      onSelected: (_) => setState(() => winnerFilter = 'BUYER'),
                    ),
                    ChoiceChip(
                      label: const Text('Traveller Wins'),
                      selected: winnerFilter == 'TRAVELLER',
                      onSelected: (_) =>
                          setState(() => winnerFilter = 'TRAVELLER'),
                    ),
                  ],
                ),
              ),

            // ✅ LIST AREA
            Expanded(
              child: filteredDocs.isEmpty
                  ? Center(
                      child: Text(
                        widget.statuses.contains('OPEN')
                            ? 'No open disputes 🎉'
                            : (_search.trim().isNotEmpty ||
                                  winnerFilter != null)
                            ? 'No resolved disputes for this filter/search'
                            : 'No resolved disputes yet',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 16,
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: filteredDocs.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (_, index) {
                        final d = filteredDocs[index];
                        final data = d.data() as Map<String, dynamic>;

                        return _DisputeCard(
                          disputeId: d.id,
                          tripRequestId: data['tripRequestId'],
                          buyerId: data['buyerId'],
                          travellerId: data['travellerId'],
                          reason: data['reason'],
                          createdAt: data['createdAt'],
                          status: data['status'],
                          resolvedBy: data['resolvedBy'] as String?, // nullable
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}

//
// =======================
// 🔹 DISPUTE CARD
// =======================
//

class _DisputeCard extends StatelessWidget {
  final String disputeId;
  final String tripRequestId;
  final String buyerId;
  final String travellerId;
  final String reason;
  final Timestamp createdAt;
  final String status;
  final String? resolvedBy;

  const _DisputeCard({
    required this.disputeId,
    required this.tripRequestId,
    required this.buyerId,
    required this.travellerId,
    required this.reason,
    required this.createdAt,
    required this.status,
    required this.resolvedBy,
  });

  @override
  Widget build(BuildContext context) {
    final date = DateTime.fromMillisecondsSinceEpoch(
      createdAt.millisecondsSinceEpoch,
    );

    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: status == 'OPEN' || status == 'APPEALED'
            ? () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        AdminDisputeDetailScreen(disputeId: disputeId),
                  ),
                );
              }
            : null,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// 🔴 STATUS + DATE
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// LEFT: STATUS + WINNER
                  Expanded(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        _StatusBadge(status: status),
                        if (status == 'RESOLVED' && resolvedBy != null)
                          _WinnerBadge(winner: resolvedBy!),
                      ],
                    ),
                  ),

                  /// RIGHT: DATE (fixed width)
                  SizedBox(
                    width: 150,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          DateFormat.yMMMd().format(date), // Jan 5, 2026
                          style: Theme.of(context).textTheme.bodyMedium,
                          maxLines: 1,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          DateFormat.jm().format(date), // 10:49 AM
                          style: Theme.of(
                            context,
                          ).textTheme.bodySmall?.copyWith(color: Colors.grey),
                          maxLines: 1,
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              /// 🚚 ROUTE (HERO)
              _TripRouteText(tripRequestId: tripRequestId),

              const SizedBox(height: 10),

              /// 📝 REASON
              Text(
                reason,
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(fontSize: 15),
              ),

              const SizedBox(height: 14),

              /// 👤 USERS
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _UserChip(label: 'Buyer', userId: buyerId),
                  _UserChip(label: 'Traveller', userId: travellerId),
                ],
              ),

              const SizedBox(height: 14),

              /// 📎 EVIDENCE
              Row(
                children: const [
                  Icon(Icons.attach_file, size: 16),
                  SizedBox(width: 6),
                  Text('Evidence available', style: TextStyle(fontSize: 13)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WinnerBadge extends StatelessWidget {
  final String winner;

  const _WinnerBadge({required this.winner});

  @override
  Widget build(BuildContext context) {
    final isBuyer = winner == 'BUYER';

    final color = isBuyer ? Colors.green : Colors.blue;
    final icon = isBuyer ? Icons.shopping_bag : Icons.flight_takeoff;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            '$winner WINS',
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _UserChip extends StatelessWidget {
  final String label;
  final String userId;

  const _UserChip({required this.label, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.person, size: 14),
          const SizedBox(width: 6),
          Text('$label:', style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(width: 4),
          _UserNameText(userId: userId, fallbackLabel: label),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case 'OPEN':
        color = Colors.orange;
        break;
      case 'APPEALED':
        color = Colors.red; // 🔥 HIGH ATTENTION
        break;
      default:
        color = Colors.green;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

class _TripRouteText extends StatelessWidget {
  final String tripRequestId;

  const _TripRouteText({required this.tripRequestId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('trip_requests')
          .doc(tripRequestId)
          .get(),
      builder: (context, snap) {
        if (!snap.hasData || !snap.data!.exists) {
          return const Text(
            'Route unavailable',
            style: TextStyle(color: Colors.grey),
          );
        }

        final data = snap.data!.data() as Map<String, dynamic>;

        final fromCity = data['fromCity'] ?? '';
        final toCity = data['toCity'] ?? '';
        final itemName = data['itemName'] ?? '';
        final weight = (data['requestedWeightKg'] ?? 0).toDouble();
        final pricePerKg = (data['pricePerKg'] ?? 0).toDouble();

        final totalAmount = weight * pricePerKg;
        final priority = _calculatePriority(totalAmount);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// 🚚 ROUTE
            Text(
              '$fromCity → $toCity',
              style: Theme.of(context).textTheme.headlineSmall,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 8),

            /// 📦 ITEM BADGE + DETAILS
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _ItemBadge(itemName: itemName),

                Text(
                  '${weight.toStringAsFixed(0)}kg × ₹${pricePerKg.toStringAsFixed(0)}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),

                /// 💰 TOTAL
                Text(
                  '= ₹${totalAmount.toStringAsFixed(0)}',
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
                ),

                /// 🔥 PRIORITY
                _PriorityBadge(priority: priority),
              ],
            ),
          ],
        );
      },
    );
  }

  /// 🔥 Priority logic (can later be admin-controlled)
  String _calculatePriority(double amount) {
    if (amount >= 5000) return 'HIGH';
    if (amount >= 1000) return 'MEDIUM';
    return 'LOW';
  }
}

class _ItemBadge extends StatelessWidget {
  final String itemName;

  const _ItemBadge({required this.itemName});

  @override
  Widget build(BuildContext context) {
    final color = _itemColor(itemName);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        itemName.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
          letterSpacing: 0.4,
        ),
      ),
    );
  }

  Color _itemColor(String item) {
    final name = item.toLowerCase();

    if (name.contains('mobile')) return Colors.blue;
    if (name.contains('document')) return Colors.green;
    if (name.contains('laptop')) return Colors.purple;
    if (name.contains('electronics')) return Colors.indigo;

    return Colors.grey;
  }
}

class _PriorityBadge extends StatelessWidget {
  final String priority;

  const _PriorityBadge({required this.priority});

  @override
  Widget build(BuildContext context) {
    final color = _priorityColor(priority);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        priority,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: color,
          letterSpacing: 0.6,
        ),
      ),
    );
  }

  Color _priorityColor(String priority) {
    switch (priority) {
      case 'HIGH':
        return Colors.red;
      case 'MEDIUM':
        return Colors.orange;
      default:
        return Colors.green;
    }
  }
}

class _UserNameText extends StatelessWidget {
  final String userId;
  final String fallbackLabel;

  const _UserNameText({required this.userId, required this.fallbackLabel});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData || !snap.data!.exists) {
          return Text(
            fallbackLabel,
            style: const TextStyle(fontSize: 13, color: Colors.grey),
          );
        }

        final data = snap.data!.data() as Map<String, dynamic>;
        final name = data['firstName'] + ' ' + data['lastName'] ?? 'Unknown';

        return Text(
          name,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          overflow: TextOverflow.ellipsis,
        );
      },
    );
  }
}

class _InfoRowWidget extends StatelessWidget {
  final String label;
  final Widget child;

  const _InfoRowWidget({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}

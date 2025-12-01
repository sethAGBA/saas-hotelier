import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../data/local_database.dart';
import 'nouveau_client_screen.dart';

class FideliteScreen extends StatefulWidget {
  const FideliteScreen({super.key});

  @override
  State<FideliteScreen> createState() => _FideliteScreenState();
}

class _FideliteScreenState extends State<FideliteScreen> with SingleTickerProviderStateMixin {
  final _money = NumberFormat.currency(locale: 'fr_FR', symbol: 'FCFA', decimalDigits: 0);
  late TabController _tabController;
  String _selectedTier = 'Tous';
  late Future<List<FidelityClient>> _future;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _future = _loadClients();
  }

  Future<List<FidelityClient>> _loadClients() async {
    final clients = await LocalDatabase.instance.fetchClients();
    final reservations = await LocalDatabase.instance.fetchReservations();
    final Map<String, _FidAggregate> agg = {};

    for (final r in reservations) {
      final name = (r['guestName'] as String? ?? '').trim();
      if (name.isEmpty) continue;
      final amount = (r['amount'] as num? ?? 0).toDouble();
      final checkOutRaw = r['checkOut'] as String?;
      final checkInRaw = r['checkIn'] as String?;
      final lastStay =
          DateTime.tryParse(checkOutRaw ?? '') ?? DateTime.tryParse(checkInRaw ?? '');
      final current = agg[name];
      if (current == null) {
        agg[name] = _FidAggregate(
          stays: 1,
          total: amount,
          lastVisit: lastStay ?? DateTime.now(),
        );
      } else {
        agg[name] = _FidAggregate(
          stays: current.stays + 1,
          total: current.total + amount,
          lastVisit: (lastStay != null && lastStay.isAfter(current.lastVisit))
              ? lastStay
              : current.lastVisit,
        );
      }
    }

    final List<FidelityClient> list = [];
    for (final c in clients) {
      final name = (c['name'] as String? ?? '').trim();
      if (name.isEmpty) continue;
      final stats = agg[name];
      final stays = stats?.stays ?? 0;
      final total = stats?.total ?? 0;
      final points = (c['fidelityPoints'] as int?) ?? (total / 1000).round();
      final statusRaw = c['fidelityStatus'] as String?;
      final tier = statusRaw ?? _tierFromStays(stays);
      list.add(
        FidelityClient(
          id: c['id'] as int?,
          name: name,
          email: (c['email'] as String? ?? '').trim(),
          phone: (c['phone'] as String? ?? '').trim(),
          stays: stays,
          total: total,
          points: points,
          tier: tier,
          nextTierPoints: _nextTier(points, tier),
          benefits: _benefitsForTier(tier),
          joinDate: DateTime.tryParse(c['fidelitySince'] as String? ?? '') ?? DateTime.now(),
          raw: c,
        ),
      );
    }

    for (final entry in agg.entries) {
      final name = entry.key;
      if (list.any((c) => c.name == name)) continue;
      final stats = entry.value;
      final tier = _tierFromStays(stats.stays);
      final points = (stats.total / 1000).round();
      list.add(
        FidelityClient(
          id: null,
          name: name,
          email: '',
          phone: '',
          stays: stats.stays,
          total: stats.total,
          points: points,
          tier: tier,
          nextTierPoints: _nextTier(points, tier),
          benefits: _benefitsForTier(tier),
          joinDate: stats.lastVisit,
          raw: null,
        ),
      );
    }

    list.sort((a, b) => b.points.compareTo(a.points));
    return list;
  }

  static String _tierFromStays(int stays) {
    if (stays >= 12) return 'Gold';
    if (stays >= 6) return 'Silver';
    return 'Bronze';
  }

  static int _nextTier(int points, String tier) {
    switch (tier) {
      case 'Gold':
        return 0;
      case 'Silver':
        return (2000 - points).clamp(0, 2000);
      default:
        return (1000 - points).clamp(0, 1000);
    }
  }

  List<String> _benefitsForTier(String tier) {
    switch (tier) {
      case 'Gold':
        return ['Suite gratuite', 'Late checkout', 'Petit-déjeuner offert', 'Spa -20%'];
      case 'Silver':
        return ['Upgrade gratuit', 'Welcome drink', 'Wi-Fi premium'];
      default:
        return ['Points doublés', 'Cadeau de bienvenue'];
    }
  }

  List<FidelityClient> _filtered(List<FidelityClient> clients) {
    if (_selectedTier == 'Tous') return clients;
    return clients.where((c) => c.tier == _selectedTier).toList();
  }

  int _count(List<FidelityClient> clients, String tier) =>
      clients.where((c) => c.tier == tier).length;

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E),
      body: FutureBuilder<List<FidelityClient>>(
        future: _future,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final clients = snapshot.data ?? [];
          final filtered = _filtered(clients);
          return Column(
            children: [
              _HeaderFid(
                gold: _count(clients, 'Gold'),
                silver: _count(clients, 'Silver'),
                bronze: _count(clients, 'Bronze'),
                onTierSelected: (tier) => setState(() => _selectedTier = tier),
                onRefresh: () => setState(() => _future = _loadClients()),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _TierTabs(controller: _tabController, onChanged: (i) {
                        switch (i) {
                          case 1:
                            _selectedTier = 'Gold';
                            break;
                          case 2:
                            _selectedTier = 'Silver';
                            break;
                          case 3:
                            _selectedTier = 'Bronze';
                            break;
                          default:
                            _selectedTier = 'Tous';
                        }
                        setState(() {});
                      }),
                      const SizedBox(height: 12),
                      Expanded(
                        child: _ClientsGrid(
                          clients: filtered,
                          money: _money,
                          onUpdated: () => setState(() => _future = _loadClients()),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _FidAggregate {
  _FidAggregate({required this.stays, required this.total, required this.lastVisit});
  final int stays;
  final double total;
  final DateTime lastVisit;
}

class _HeaderFid extends StatelessWidget {
  const _HeaderFid({
    required this.gold,
    required this.silver,
    required this.bronze,
    required this.onTierSelected,
    required this.onRefresh,
  });

  final int gold;
  final int silver;
  final int bronze;
  final ValueChanged<String> onTierSelected;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 40, 16, 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF141E30), Color(0xFF243B55)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.card_giftcard, color: Colors.white, size: 28),
              const SizedBox(width: 10),
              const Text(
                'Programme Fidélité',
                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              IconButton(
                onPressed: onRefresh,
                icon: const Icon(Icons.refresh, color: Colors.white70),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _statCard('Gold', gold.toString(), const Color(0xFFFFD700))),
              Expanded(child: _statCard('Silver', silver.toString(), const Color(0xFFC0C0C0))),
              Expanded(child: _statCard('Bronze', bronze.toString(), const Color(0xFFCD7F32))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, Color color) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.workspace_premium, color: color, size: 18),
              const SizedBox(width: 6),
              Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 18)),
        ],
      ),
    );
  }
}

class _TierTabs extends StatelessWidget {
  const _TierTabs({required this.controller, required this.onChanged});

  final TabController controller;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return TabBar(
      controller: controller,
      indicatorColor: const Color(0xFF6C63FF),
      labelColor: Colors.white,
      unselectedLabelColor: Colors.white70,
      onTap: onChanged,
      tabs: const [
        Tab(text: 'Tous'),
        Tab(text: 'Gold'),
        Tab(text: 'Silver'),
        Tab(text: 'Bronze'),
      ],
    );
  }
}

class _ClientsGrid extends StatelessWidget {
  const _ClientsGrid({required this.clients, required this.money, this.onUpdated});

  final List<FidelityClient> clients;
  final NumberFormat money;
  final VoidCallback? onUpdated;

  @override
  Widget build(BuildContext context) {
    if (clients.isEmpty) {
      return const Center(
        child: Text('Aucun client', style: TextStyle(color: Colors.white70)),
      );
    }
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.5,
      ),
      itemCount: clients.length,
      itemBuilder: (context, index) {
        final c = clients[index];
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1B1B2F), Color(0xFF162447)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withOpacity(0.06)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: _tierColor(c.tier),
                    child: Text(c.name.substring(0, 1), style: const TextStyle(color: Colors.white)),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(c.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        Text(c.email, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12)),
                        Text(c.phone, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12)),
                      ],
                    ),
                  ),
                  _TierChip(label: c.tier),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  _pill('${c.points} pts', Colors.orangeAccent),
                  _pill('Séjours: ${c.stays}', Colors.greenAccent),
                  _pill('CA: ${money.format(c.total)}', Colors.purpleAccent),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Avantages: ${c.benefits.take(2).join(' • ')}',
                style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(),
              Row(
                children: [
                  Text(
                    'Prochain palier: ${c.nextTierPoints} pts',
                    style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12),
                  ),
                  const Spacer(),
                  Text(
                    'Depuis ${DateFormat('dd/MM/yyyy').format(c.joinDate)}',
                    style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 11),
                  ),
                ],
              ),
              if (c.id != null) ...[
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        backgroundColor: Colors.transparent,
                        isScrollControlled: true,
                        builder: (ctx) => Container(
                          height: MediaQuery.of(context).size.height * 0.9,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFF1A1A2E).withOpacity(0.98),
                                const Color(0xFF16213E).withOpacity(0.98),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.only(top: 24),
                            child: NouveauClientScreen(
                              showHeader: false,
                              clientId: c.id,
                              initialName: c.name,
                              initialEmail: c.email,
                              initialPhone: c.phone,
                              initialFidelity: c.tier,
                              initialVip: c.tier == 'Gold',
                              initialData: c.raw,
                              onSaved: () {
                                Navigator.pop(ctx);
                                onUpdated?.call();
                              },
                            ),
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.edit, color: Colors.white70, size: 16),
                    label: const Text('Modifier', style: TextStyle(color: Colors.white70)),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Color _tierColor(String tier) {
    switch (tier) {
      case 'Gold':
        return const Color(0xFFFFD700);
      case 'Silver':
        return const Color(0xFFC0C0C0);
      default:
        return const Color(0xFFCD7F32);
    }
  }

  Widget _pill(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }
}

class _TierChip extends StatelessWidget {
  const _TierChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (label) {
      case 'Gold':
        color = const Color(0xFFFFD700);
        break;
      case 'Silver':
        color = const Color(0xFFC0C0C0);
        break;
      default:
        color = const Color(0xFFCD7F32);
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }
}

class FidelityClient {
  FidelityClient({
    required this.name,
    required this.email,
    required this.phone,
    required this.stays,
    required this.total,
    required this.points,
    required this.tier,
    required this.nextTierPoints,
    required this.benefits,
    required this.joinDate,
    this.id,
    this.raw,
  });

  final int? id;
  final String name;
  final String email;
  final String phone;
  final int stays;
  final double total;
  final int points;
  final String tier;
  final int nextTierPoints;
  final List<String> benefits;
  final DateTime joinDate;
  final Map<String, dynamic>? raw;
}

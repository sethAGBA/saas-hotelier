import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../data/local_database.dart';
import 'clients_common.dart';

class ClientsVipScreen extends StatefulWidget {
  const ClientsVipScreen({super.key});

  @override
  State<ClientsVipScreen> createState() => _ClientsVipScreenState();
}

class _ClientsVipScreenState extends State<ClientsVipScreen> {
  late Future<List<Map<String, dynamic>>> _reservationsFuture;
  final _money = NumberFormat.currency(locale: 'fr_FR', symbol: 'FCFA', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _reservationsFuture = LocalDatabase.instance.fetchReservations();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _reservationsFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final list = _aggregate(snapshot.data ?? []).take(20).toList();
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _VipHeader(),
                const SizedBox(height: 12),
                Expanded(
                  child: list.isEmpty
                      ? const _EmptyVip()
                      : GridView.builder(
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 10,
                            crossAxisSpacing: 10,
                            childAspectRatio: 1.4,
                          ),
                          itemCount: list.length,
                          itemBuilder: (context, index) {
                            final c = list[index];
                            return _VipCard(client: c, money: _money);
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  List<ClientRow> _aggregate(List<Map<String, dynamic>> reservations) {
    final Map<String, ClientRow> map = {};
    for (final r in reservations) {
      final name = (r['guestName'] as String? ?? 'Client').trim();
      if (name.isEmpty) continue;
      final amount = (r['amount'] as num? ?? 0).toDouble();
      final stay = ClientRow(
        name: name,
        email: r['guestEmail'] as String? ?? '',
        phone: r['guestPhone'] as String? ?? '',
        stays: 1,
        total: amount,
      );
      if (map.containsKey(name)) {
        final existing = map[name]!;
        map[name] = existing.copyWith(
          stays: existing.stays + 1,
          total: existing.total + amount,
          email: existing.email.isNotEmpty ? existing.email : stay.email,
          phone: existing.phone.isNotEmpty ? existing.phone : stay.phone,
        );
      } else {
        map[name] = stay;
      }
    }
    final list = map.values.toList()
      ..sort((a, b) => b.total.compareTo(a.total));
    return list;
  }
}

class _VipHeader extends StatelessWidget {
  const _VipHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF1F1C2C), Color(0xFF928DAB)]),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.star_rounded, color: Colors.amber, size: 28),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text('Clients VIP', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              Text('Top 20 par dépenses', style: TextStyle(color: Colors.white70)),
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: const [
                Icon(Icons.emoji_events, color: Colors.white, size: 16),
                SizedBox(width: 6),
                Text('VIP Club', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VipCard extends StatelessWidget {
  const _VipCard({required this.client, required this.money});

  final ClientRow client;
  final NumberFormat money;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF20002c), Color(0xFF5f0a87)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.amber,
                child: Text(client.name.substring(0, 1), style: const TextStyle(color: Colors.white)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(client.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    Text(client.email, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12)),
                    Text(client.phone, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12)),
                  ],
                ),
              ),
              const TierChip(label: 'VIP'),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _pill('Séjours: ${client.stays}', Colors.greenAccent),
              _pill('CA: ${money.format(client.total)}', Colors.orangeAccent),
            ],
          ),
          const Spacer(),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.card_giftcard, size: 16),
              label: const Text('Offrir un avantage'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pill(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
    );
  }
}

class _EmptyVip extends StatelessWidget {
  const _EmptyVip();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.star_border_purple500_outlined, size: 72, color: Colors.white24),
          SizedBox(height: 12),
          Text('Aucun VIP', style: TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../data/local_database.dart';

class EntretienScreen extends StatefulWidget {
  const EntretienScreen({super.key});

  @override
  State<EntretienScreen> createState() => _EntretienScreenState();
}

class _EntretienScreenState extends State<EntretienScreen> {
  late Future<List<Map<String, dynamic>>> _future;
  String _filter = 'Tous';

  @override
  void initState() {
    super.initState();
    _future = LocalDatabase.instance.fetchRooms();
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'available':
      case 'propre':
        return Colors.greenAccent;
      case 'occupied':
      case 'sale':
        return Colors.redAccent;
      case 'cleaning':
        return Colors.orangeAccent;
      case 'maintenance':
        return Colors.blueGrey;
      default:
        return Colors.white54;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'available':
        return 'Disponible';
      case 'occupied':
        return 'Occupée';
      case 'cleaning':
        return 'Nettoyage';
      case 'maintenance':
        return 'Maintenance';
      case 'dirty':
        return 'Sale';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFfbc2eb), Color(0xFFa6c1ee)],
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.cleaning_services_rounded, color: Colors.white),
                  ),
                  const SizedBox(width: 14),
                  const Text(
                    'Entretien',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _filter,
                      dropdownColor: const Color(0xFF1A1A2E),
                      items: const [
                        'Tous',
                        'Disponible',
                        'Occupée',
                        'Nettoyage',
                        'Maintenance',
                        'Sale',
                      ].map((f) => DropdownMenuItem(value: f, child: Text(f, style: const TextStyle(color: Colors.white)))).toList(),
                      onChanged: (v) => setState(() => _filter = v ?? 'Tous'),
                      iconEnabledColor: Colors.white70,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: _future,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final rooms = snapshot.data ?? [];
                    final filtered = rooms.where((r) {
                      final status = (r['status'] as String? ?? '').toLowerCase();
                      switch (_filter) {
                        case 'Disponible':
                          return status == 'available';
                        case 'Occupée':
                          return status == 'occupied';
                        case 'Nettoyage':
                          return status == 'cleaning';
                        case 'Maintenance':
                          return status == 'maintenance';
                        case 'Sale':
                          return status == 'dirty';
                        default:
                          return true;
                      }
                    }).toList()
                      ..sort((a, b) => (a['number'] as String).compareTo(b['number'] as String));

                    if (filtered.isEmpty) {
                      return const Center(
                        child: Text(
                          'Aucune chambre',
                          style: TextStyle(color: Colors.white70),
                        ),
                      );
                    }

                    return ListView.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final room = filtered[index];
                        final status = room['status'] as String? ?? 'available';
                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.03),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white.withOpacity(0.08)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 10,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: _statusColor(status),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Ch. ${room['number']}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${room['type'] ?? 'Type'} • ${room['category'] ?? ''}',
                                      style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: _statusColor(status).withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  _statusLabel(status),
                                  style: TextStyle(
                                    color: _statusColor(status),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../data/local_database.dart';

class CorporateScreen extends StatefulWidget {
  const CorporateScreen({super.key});

  @override
  State<CorporateScreen> createState() => _CorporateScreenState();
}

class _CorporateScreenState extends State<CorporateScreen> {
  final _money = NumberFormat.currency(locale: 'fr_FR', symbol: 'FCFA', decimalDigits: 0);
  String _searchQuery = '';
  String _sortBy = 'revenue'; // revenue, bookings, name
  bool _showActiveOnly = false;
  late Future<List<CorporateClient>> _future;
  List<CorporateClient> _clients = [];

  @override
  void initState() {
    super.initState();
    _future = _loadClients();
  }

  Future<List<CorporateClient>> _loadClients() async {
    final clients = await LocalDatabase.instance.fetchClients();
    final reservations = await LocalDatabase.instance.fetchReservations();

    final Map<String, _CorpAggregate> agg = {};
    for (final r in reservations) {
      final name = (r['guestName'] as String? ?? '').trim();
      if (name.isEmpty) continue;
      final amount = (r['amount'] as num? ?? 0).toDouble();
      final checkOutRaw = r['checkOut'] as String?;
      final lastStay = DateTime.tryParse(checkOutRaw ?? '') ?? DateTime.tryParse(r['checkIn'] as String? ?? '');
      final current = agg[name];
      if (current == null) {
        agg[name] = _CorpAggregate(
          bookings: 1,
          revenue: amount,
          lastBooking: lastStay ?? DateTime.now(),
        );
      } else {
        agg[name] = _CorpAggregate(
          bookings: current.bookings + 1,
          revenue: current.revenue + amount,
          lastBooking: (lastStay != null && lastStay.isAfter(current.lastBooking))
              ? lastStay
              : current.lastBooking,
        );
      }
    }

    final List<CorporateClient> mapped = [];
    for (final c in clients) {
      final type = (c['clientType'] as String? ?? '').toLowerCase();
      final company = (c['company'] as String? ?? '').trim();
      if (!(type.contains('corporate') || company.isNotEmpty)) continue;
      final contactName = (c['name'] as String? ?? '').trim();
      final stats = agg[contactName];
      mapped.add(
        CorporateClient(
          companyName: company.isNotEmpty ? company : contactName,
          contactName: contactName.isNotEmpty ? contactName : 'Contact',
          email: (c['email'] as String? ?? '').trim(),
          phone: (c['phone'] as String? ?? '').trim(),
          industry: (c['profession'] as String? ?? '').trim(),
          totalBookings: stats?.bookings ?? 0,
          totalRevenue: stats?.revenue ?? 0,
          contractType: (c['reservationSource'] as String? ?? 'Direct').trim(),
          discount: 0,
          lastBooking: stats?.lastBooking ?? DateTime.now(),
          accountManager: '',
          paymentTerms: '30 jours',
          vatNumber: (c['vatNumber'] as String? ?? '').trim(),
          address: (c['address'] as String? ?? '').trim(),
          isActive: true,
          preferredRooms: const [],
        ),
      );
    }

    mapped.sort((a, b) => b.totalRevenue.compareTo(a.totalRevenue));
    _clients = mapped;
    return mapped;
  }

  List<CorporateClient> get _filteredClients {
    var filtered = _clients.where((client) {
      final q = _searchQuery.toLowerCase();
      final matchesSearch = client.companyName.toLowerCase().contains(q) ||
          client.contactName.toLowerCase().contains(q) ||
          client.industry.toLowerCase().contains(q);
      final matchesActive = !_showActiveOnly || client.isActive;
      return matchesSearch && matchesActive;
    }).toList();

    switch (_sortBy) {
      case 'revenue':
        filtered.sort((a, b) => b.totalRevenue.compareTo(a.totalRevenue));
        break;
      case 'bookings':
        filtered.sort((a, b) => b.totalBookings.compareTo(a.totalBookings));
        break;
      case 'name':
        filtered.sort((a, b) => a.companyName.compareTo(b.companyName));
        break;
    }
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E),
      body: FutureBuilder<List<CorporateClient>>(
        future: _future,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final filtered = _filteredClients;
          final totalRevenue = _clients.fold<double>(0, (sum, c) => sum + c.totalRevenue);
          final totalBookings = _clients.fold<int>(0, (sum, c) => sum + c.totalBookings);
          final activeClients = _clients.where((c) => c.isActive).length;
          final avgDiscount = _clients.isEmpty
              ? 0.0
              : _clients.fold<double>(0, (sum, c) => sum + c.discount) / _clients.length;

          return SafeArea(
            child: Column(
              children: [
                _HeaderCorporate(
                  totalRevenue: totalRevenue,
                  totalBookings: totalBookings,
                  activeClients: activeClients,
                  avgDiscount: avgDiscount,
                  onRefresh: () => setState(() => _future = _loadClients()),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _SearchBarCorporate(
                        onChanged: (v) => setState(() => _searchQuery = v),
                        showActiveOnly: _showActiveOnly,
                        onToggleActive: (v) => setState(() => _showActiveOnly = v),
                      ),
                      const SizedBox(height: 10),
                      _SortRowCorporate(
                        sortBy: _sortBy,
                        onChanged: (v) => setState(() => _sortBy = v),
                        count: filtered.length,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: filtered.isEmpty
                      ? const _EmptyState()
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final c = filtered[index];
                            return _CorporateCard(client: c, money: _money);
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
}

class _HeaderCorporate extends StatelessWidget {
  const _HeaderCorporate({
    required this.totalRevenue,
    required this.totalBookings,
    required this.activeClients,
    required this.avgDiscount,
    required this.onRefresh,
  });

  final double totalRevenue;
  final int totalBookings;
  final int activeClients;
  final double avgDiscount;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 32, 16, 16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.apartment_rounded, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Clients Corporate',
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Comptes entreprises & conditions négociées',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
              const Spacer(),
              IconButton(
                onPressed: onRefresh,
                icon: const Icon(Icons.refresh, color: Colors.white70),
                tooltip: 'Recharger',
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _statTile('CA total', _formatNumber(totalRevenue), Colors.greenAccent)),
              Expanded(child: _statTile('Réservations', '$totalBookings', Colors.blueAccent)),
              Expanded(child: _statTile('Clients actifs', '$activeClients', Colors.orangeAccent)),
              Expanded(child: _statTile('Remise moyenne', '${avgDiscount.toStringAsFixed(1)}%', Colors.purpleAccent)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statTile(String label, String value, Color color) {
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
          Text(label, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12)),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ],
      ),
    );
  }

  String _formatNumber(double value) {
    final nf = NumberFormat.compactCurrency(locale: 'fr_FR', symbol: 'FCFA');
    return nf.format(value);
  }
}

class _SearchBarCorporate extends StatelessWidget {
  const _SearchBarCorporate({
    required this.onChanged,
    required this.showActiveOnly,
    required this.onToggleActive,
  });

  final ValueChanged<String> onChanged;
  final bool showActiveOnly;
  final ValueChanged<bool> onToggleActive;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Rechercher (société, contact, secteur)...',
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
            prefixIcon: const Icon(Icons.search, color: Color(0xFF6C63FF)),
            filled: true,
            fillColor: Colors.white.withOpacity(0.04),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
            ),
            focusedBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
              borderSide: BorderSide(color: Color(0xFF6C63FF)),
            ),
          ),
          onChanged: onChanged,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Row(
                children: [
                  Switch(
                    value: showActiveOnly,
                    activeColor: const Color(0xFF6C63FF),
                    onChanged: onToggleActive,
                  ),
                  const Text('Actifs uniquement', style: TextStyle(color: Colors.white)),
                ],
              ),
            ),
            const Icon(Icons.filter_list, color: Colors.white70),
          ],
        ),
      ],
    );
  }
}

class _SortRowCorporate extends StatelessWidget {
  const _SortRowCorporate({
    required this.sortBy,
    required this.onChanged,
    required this.count,
  });

  final String sortBy;
  final ValueChanged<String> onChanged;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text('$count comptes', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        const Spacer(),
        Text('Trier par', style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12)),
        const SizedBox(width: 8),
        DropdownButton<String>(
          value: sortBy,
          dropdownColor: const Color(0xFF1A1A2E),
          underline: const SizedBox(),
          items: const [
            DropdownMenuItem(value: 'revenue', child: Text('CA')),
            DropdownMenuItem(value: 'bookings', child: Text('Réservations')),
            DropdownMenuItem(value: 'name', child: Text('Nom')),
          ],
          onChanged: (value) => value != null ? onChanged(value) : null,
        ),
      ],
    );
  }
}

class _CorporateCard extends StatelessWidget {
  const _CorporateCard({required this.client, required this.money});

  final CorporateClient client;
  final NumberFormat money;

  @override
  Widget build(BuildContext context) {
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
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.business_center, color: Colors.white),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(client.companyName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    Text(client.industry, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12)),
                    Text('${client.contactName} • ${client.phone}', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12)),
                  ],
                ),
              ),
              _pill(client.contractType, Colors.blueAccent),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _pill('Réservations: ${client.totalBookings}', Colors.greenAccent),
              _pill('CA: ${money.format(client.totalRevenue)}', Colors.orangeAccent),
              _pill('Remise: ${client.discount}%', Colors.purpleAccent),
              _pill('Paiement: ${client.paymentTerms}', Colors.cyanAccent),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Rooms: ${client.preferredRooms.join(' • ')}',
            style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.person_outline, color: Colors.white.withOpacity(0.6), size: 16),
              const SizedBox(width: 6),
              Text('Key account: ${client.accountManager}', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12)),
              const Spacer(),
              _pill(client.isActive ? 'Actif' : 'Inactif', client.isActive ? Colors.tealAccent : Colors.redAccent),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.access_time, color: Colors.white.withOpacity(0.6), size: 16),
              const SizedBox(width: 6),
              Text('Dernière résa: ${DateFormat('dd/MM/yyyy').format(client.lastBooking)}', style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12)),
              const Spacer(),
              Text('TVA: ${client.vatNumber}', style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.mail, size: 16),
                  label: const Text('Contacter'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Color(0xFF6C63FF)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.visibility, size: 16),
                  label: const Text('Détails'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C63FF),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _pill(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.business_outlined, size: 72, color: Colors.white24),
          const SizedBox(height: 12),
          const Text('Aucun compte corporate', style: TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }
}

class _CorpAggregate {
  _CorpAggregate({
    required this.bookings,
    required this.revenue,
    required this.lastBooking,
  });

  final int bookings;
  final double revenue;
  final DateTime lastBooking;
}

class CorporateClient {
  CorporateClient({
    required this.companyName,
    required this.contactName,
    required this.email,
    required this.phone,
    required this.industry,
    required this.totalBookings,
    required this.totalRevenue,
    required this.contractType,
    required this.discount,
    required this.lastBooking,
    required this.accountManager,
    required this.paymentTerms,
    required this.vatNumber,
    required this.address,
    required this.isActive,
    required this.preferredRooms,
  });

  final String companyName;
  final String contactName;
  final String email;
  final String phone;
  final String industry;
  final int totalBookings;
  final double totalRevenue;
  final String contractType;
  final double discount;
  final DateTime lastBooking;
  final String accountManager;
  final String paymentTerms;
  final String vatNumber;
  final String address;
  final bool isActive;
  final List<String> preferredRooms;
}

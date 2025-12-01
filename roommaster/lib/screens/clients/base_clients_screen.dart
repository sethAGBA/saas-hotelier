import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../data/local_database.dart';
import 'nouveau_client_screen.dart';

class BaseClientsScreen extends StatefulWidget {
  const BaseClientsScreen({super.key});

  @override
  State<BaseClientsScreen> createState() => _BaseClientsScreenState();
}

class _BaseClientsScreenState extends State<BaseClientsScreen> {
  final _money = NumberFormat.currency(locale: 'fr_FR', symbol: 'FCFA', decimalDigits: 0);
  String _searchQuery = '';
  String _filterType = 'Tous';
  String _sortBy = 'total'; // total, stays, name, recent
  String _fidelityFilter = 'Tous';
  bool _vipOnly = false;
  late Future<void> _future;
  List<ClientData> _clients = [];

  @override
  void initState() {
    super.initState();
    _future = _loadClients();
  }

  Future<void> _loadClients() async {
    final clients = await LocalDatabase.instance.fetchClients();
    final reservations = await LocalDatabase.instance.fetchReservations();
    final stats = _aggregateReservations(reservations);

    final mapped = clients.map((row) {
      final name = (row['name'] as String? ?? '').trim();
      final createdAt = DateTime.tryParse(row['createdAt'] as String? ?? '');
      final aggregated = stats[name];
      final stays = aggregated?.stays ?? 0;
      final total = aggregated?.total ?? 0;
      final lastVisit = aggregated?.lastVisit ?? createdAt ?? DateTime.now();
      final fidelityStatus =
          stays >= 12 ? 'Gold' : stays >= 6 ? 'Silver' : 'Bronze';
      final type = aggregated?.segment ?? 'Loisirs';
      final isVIP = total >= 2000000 || stays >= 10;

      return ClientData(
        id: row['id'] as int?,
        name: name.isNotEmpty ? name : 'Client',
        email: (row['email'] as String? ?? '').trim(),
        phone: (row['phone'] as String? ?? '').trim(),
        stays: stays,
        total: total,
        lastVisit: lastVisit,
        fidelityStatus: fidelityStatus,
        type: type,
        isVIP: isVIP,
      );
    }).toList()
      ..sort((a, b) => b.lastVisit.compareTo(a.lastVisit));

    final existingNames = mapped.map((c) => c.name).toSet();
    for (final entry in stats.entries) {
      if (existingNames.contains(entry.key)) continue;
      final agg = entry.value;
      mapped.add(
        ClientData(
          name: entry.key,
          email: '',
          phone: '',
          stays: agg.stays,
          total: agg.total,
          lastVisit: agg.lastVisit,
          fidelityStatus: agg.stays >= 12 ? 'Gold' : agg.stays >= 6 ? 'Silver' : 'Bronze',
          type: agg.segment ?? 'Loisirs',
          isVIP: agg.total >= 2000000 || agg.stays >= 10,
        ),
      );
    }

    mapped.sort((a, b) => b.lastVisit.compareTo(a.lastVisit));

    if (!mounted) return;
    setState(() {
      _clients = mapped;
    });
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _loadClients();
    });
  }

  Map<String, _ClientAggregate> _aggregateReservations(
    List<Map<String, dynamic>> reservations,
  ) {
    final Map<String, _ClientAggregate> aggregates = {};
    for (final r in reservations) {
      final name = (r['guestName'] as String? ?? '').trim();
      if (name.isEmpty) continue;
      final amount = (r['amount'] as num? ?? 0).toDouble();
      final checkOutRaw = r['checkOut'] as String?;
      final checkInRaw = r['checkIn'] as String?;
      final lastStay =
          DateTime.tryParse(checkOutRaw ?? '') ?? DateTime.tryParse(checkInRaw ?? '');

      final current = aggregates[name];
      if (current == null) {
        aggregates[name] = _ClientAggregate(
          stays: 1,
          total: amount,
          lastVisit: lastStay ?? DateTime.now(),
        );
      } else {
        aggregates[name] = _ClientAggregate(
          stays: current.stays + 1,
          total: current.total + amount,
          lastVisit: (lastStay != null && lastStay.isAfter(current.lastVisit))
              ? lastStay
              : current.lastVisit,
        );
      }
    }
    return aggregates;
  }

  List<ClientData> get _filteredClients {
    var filtered = _clients.where((client) {
      final matchesSearch = client.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          client.email.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          client.phone.contains(_searchQuery);
      final matchesFilter = _filterType == 'Tous' || client.type == _filterType;
      final matchesFidelity = _fidelityFilter == 'Tous' || client.fidelityStatus == _fidelityFilter;
      final matchesVip = !_vipOnly || client.isVIP;
      return matchesSearch && matchesFilter && matchesFidelity && matchesVip;
    }).toList();

    switch (_sortBy) {
      case 'total':
        filtered.sort((a, b) => b.total.compareTo(a.total));
        break;
      case 'stays':
        filtered.sort((a, b) => b.stays.compareTo(a.stays));
        break;
      case 'name':
        filtered.sort((a, b) => a.name.compareTo(b.name));
        break;
      case 'recent':
        filtered.sort((a, b) => b.lastVisit.compareTo(a.lastVisit));
        break;
    }
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E),
      body: SafeArea(
        child: FutureBuilder<void>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting && _clients.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.redAccent),
                    const SizedBox(height: 8),
                    const Text('Impossible de charger les clients', style: TextStyle(color: Colors.white)),
                    TextButton.icon(
                      onPressed: _refresh,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Réessayer'),
                    ),
                  ],
                ),
              );
            }

            final filtered = _filteredClients;
            final totalRevenue = _clients.fold<double>(0, (sum, c) => sum + c.total);
            final totalStays = _clients.fold<int>(0, (sum, c) => sum + c.stays);
            final vipCount = _clients.where((c) => c.isVIP).length;

            return Column(
              children: [
                _Header(
                  onRefresh: _refresh,
                  isLoading: snapshot.connectionState == ConnectionState.waiting,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: _GlassStats(
                    items: [
                      _Stat(label: 'Clients', value: '${_clients.length}', color: Colors.white),
                      _Stat(label: 'VIP', value: '$vipCount', color: Colors.amber),
                      _Stat(label: 'Séjours', value: '$totalStays', color: Colors.greenAccent),
                      _Stat(label: 'CA', value: _money.format(totalRevenue), color: Colors.orangeAccent),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      _SearchBar(onChanged: (v) => setState(() => _searchQuery = v)),
                      const SizedBox(height: 10),
                      _FilterRow(current: _filterType, onSelected: (v) => setState(() => _filterType = v)),
                      const SizedBox(height: 8),
                      _AdvancedFilters(
                        fidelity: _fidelityFilter,
                        vipOnly: _vipOnly,
                        onFidelityChanged: (v) => setState(() => _fidelityFilter = v),
                        onVipToggle: (v) => setState(() => _vipOnly = v),
                      ),
                      const SizedBox(height: 8),
                      _SortRow(
                        count: filtered.length,
                        sortBy: _sortBy,
                        onChanged: (v) => setState(() => _sortBy = v),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: filtered.isEmpty
                      ? const _EmptyState()
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final client = filtered[index];
                            return _ClientCard(client: client, money: _money, onSaved: _refresh);
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onRefresh, required this.isLoading});

  final VoidCallback onRefresh;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF141E30), Color(0xFF243B55)]),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.people_alt_rounded, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Base Clients',
                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              ),
              Text(
                'Vue CRM locale',
                style: TextStyle(color: Colors.white70),
              ),
            ],
          ),
          const Spacer(),
          IconButton(
            onPressed: isLoading ? null : onRefresh,
            icon: isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.refresh, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _GlassStats extends StatelessWidget {
  const _GlassStats({required this.items});

  final List<_Stat> items;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: items
          .map(
            (s) => Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 6),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.03),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.label, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12)),
                    const SizedBox(height: 6),
                    Text(
                      s.value,
                      style: TextStyle(color: s.color, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _Stat {
  const _Stat({required this.label, required this.value, required this.color});
  final String label;
  final String value;
  final Color color;
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.onChanged});

  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: 'Rechercher (nom, email, téléphone)...',
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
    );
  }
}

class _FilterRow extends StatelessWidget {
  const _FilterRow({required this.current, required this.onSelected});

  final String current;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final filters = ['Tous', 'Loisirs', 'Corporate', 'Clients fréquents'];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: filters
          .map(
            (f) => ChoiceChip(
              label: Text(f),
              selected: current == f,
              onSelected: (_) => onSelected(f),
              selectedColor: const Color(0xFF6C63FF),
              labelStyle: TextStyle(color: current == f ? Colors.white : Colors.white70),
              backgroundColor: const Color(0xFF1B1B2F),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          )
          .toList(),
    );
  }
}

class _AdvancedFilters extends StatelessWidget {
  const _AdvancedFilters({
    required this.fidelity,
    required this.vipOnly,
    required this.onFidelityChanged,
    required this.onVipToggle,
  });

  final String fidelity;
  final bool vipOnly;
  final ValueChanged<String> onFidelityChanged;
  final ValueChanged<bool> onVipToggle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<String>(
            value: fidelity,
            dropdownColor: const Color(0xFF1A1A2E),
            decoration: InputDecoration(
              labelText: 'Statut fidélité',
              labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
              filled: true,
              fillColor: Colors.white.withOpacity(0.03),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
              ),
              focusedBorder: const OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(12)),
                borderSide: BorderSide(color: Color(0xFF6C63FF)),
              ),
            ),
            items: const [
              DropdownMenuItem(value: 'Tous', child: Text('Tous')),
              DropdownMenuItem(value: 'Bronze', child: Text('Bronze')),
              DropdownMenuItem(value: 'Silver', child: Text('Silver')),
              DropdownMenuItem(value: 'Gold', child: Text('Gold')),
            ],
            onChanged: (v) => onFidelityChanged(v ?? 'Tous'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: SwitchListTile(
            value: vipOnly,
            onChanged: onVipToggle,
            activeColor: const Color(0xFF6C63FF),
            title: const Text('VIP uniquement', style: TextStyle(color: Colors.white)),
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ],
    );
  }
}

class _SortRow extends StatelessWidget {
  const _SortRow({required this.count, required this.sortBy, required this.onChanged});

  final int count;
  final String sortBy;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          '$count client(s)',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        const Spacer(),
        Text('Trier par', style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12)),
        const SizedBox(width: 8),
        DropdownButton<String>(
          value: sortBy,
          dropdownColor: const Color(0xFF1A1A2E),
          underline: const SizedBox(),
          items: const [
            DropdownMenuItem(value: 'total', child: Text('CA Total')),
            DropdownMenuItem(value: 'stays', child: Text('Séjours')),
            DropdownMenuItem(value: 'recent', child: Text('Récents')),
            DropdownMenuItem(value: 'name', child: Text('Nom')),
          ],
          onChanged: (value) => value != null ? onChanged(value) : null,
        ),
      ],
    );
  }
}

class _ClientCard extends StatelessWidget {
  const _ClientCard({required this.client, required this.money, required this.onSaved});

  final ClientData client;
  final NumberFormat money;
  final Future<void> Function() onSaved;

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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: const Color(0xFF6C63FF),
                child: Text(client.name.substring(0, 1), style: const TextStyle(color: Colors.white)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      client.name,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      client.email,
                      style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12),
                    ),
                    Text(
                      client.phone,
                      style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Icon(Icons.star, color: client.isVIP ? Colors.amber : Colors.white24),
                  const SizedBox(height: 6),
                  Text(
                    'Visite: ${DateFormat('dd/MM').format(client.lastVisit)}',
                    style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _pill(client.type, Colors.blueAccent),
              _pill(client.fidelityStatus, Colors.orangeAccent),
              _pill('Séjours: ${client.stays}', Colors.greenAccent),
              _pill('CA: ${money.format(client.total)}', Colors.purpleAccent),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.call, size: 16),
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
                  onPressed: () => _openDetail(context),
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
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Future<void> _openDetail(BuildContext context) async {
    Map<String, dynamic>? fullClient;
    if (client.id != null) {
      fullClient = await LocalDatabase.instance.fetchClientById(client.id!);
    }

    if (!context.mounted) return;

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
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Scrollbar(
                thumbVisibility: true,
                interactive: true,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Stack(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 40),
                        child: NouveauClientScreen(
                          showHeader: false,
                          clientId: client.id,
                          initialLastName: fullClient?['lastName'] as String?,
                          initialFirstName: fullClient?['firstName'] as String?,
                          initialName: fullClient?['lastName'] as String? ?? client.name,
                          initialEmail: fullClient?['email'] as String? ?? client.email,
                          initialPhone: fullClient?['phone'] as String? ?? client.phone,
                          initialPhone2: fullClient?['phone2'] as String?,
                          initialSegment: fullClient?['clientType'] as String? ?? client.type,
                          initialFidelity: fullClient?['fidelityStatus'] as String? ?? client.fidelityStatus,
                          initialVip: (fullClient?['vip'] as int?) == 1 || client.isVIP,
                          initialData: fullClient,
                          onSaved: () async {
                            Navigator.pop(ctx);
                            await onSaved();
                          },
                        ),
                      ),
                      Positioned(
                        top: 0,
                        right: 0,
                        child: IconButton(
                          onPressed: () => Navigator.pop(ctx),
                          icon: const Icon(Icons.close_rounded, color: Colors.white70),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
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
        children: const [
          Icon(Icons.person_search, size: 72, color: Colors.white24),
          SizedBox(height: 12),
          Text('Aucun client trouvé', style: TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }
}

class ClientData {
  final int? id;
  final String name;
  final String email;
  final String phone;
  final int stays;
  final double total;
  final DateTime lastVisit;
  final String fidelityStatus;
  final String type;
  final bool isVIP;

  ClientData({
    this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.stays,
    required this.total,
    required this.lastVisit,
    required this.fidelityStatus,
    required this.type,
    required this.isVIP,
  });
}

class _ClientAggregate {
  const _ClientAggregate({
    required this.stays,
    required this.total,
    required this.lastVisit,
    this.segment,
  });

  final int stays;
  final double total;
  final DateTime lastVisit;
  final String? segment;
}

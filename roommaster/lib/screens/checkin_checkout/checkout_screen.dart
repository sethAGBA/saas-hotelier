import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../data/local_database.dart';

class CheckOutScreen extends StatefulWidget {
  const CheckOutScreen({super.key});

  @override
  State<CheckOutScreen> createState() => _CheckOutScreenState();
}

class _CheckOutScreenState extends State<CheckOutScreen> {
  final _searchController = TextEditingController();
  final DateFormat _dateFormat = DateFormat('dd/MM');
  List<Map<String, dynamic>> _reservations = [];
  List<Map<String, dynamic>> _filtered = [];
  List<String> _roomFilters = ['Toutes'];
  String _selectedRoom = 'Toutes';
  final List<String> _statusFilters = [
    'Tous',
    'Confirmée',
    'En séjour',
    'Check-out',
    'Annulée',
  ];
  String _selectedStatus = 'Tous';
  bool _loading = true;

  bool _isToday(DateTime? date) {
    if (date == null) return false;
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final data = await LocalDatabase.instance.fetchReservations();
    if (!mounted) return;
    setState(() {
      _reservations = data;
      final rooms = data
          .map((r) => (r['roomNumber'] as String? ?? '').trim())
          .where((r) => r.isNotEmpty)
          .toSet()
          .toList()
        ..sort();
      _roomFilters = ['Toutes', ...rooms];
      _applyFilters();
      _loading = false;
    });
  }

  void _filter(String query) {
    _applyFilters(query);
  }

  void _applyFilters([String? query]) {
    final q = (query ?? _searchController.text).toLowerCase();
    final selectedRoom = _selectedRoom.toLowerCase();
    final selectedStatus = _selectedStatus;
    setState(() {
      final filtered = _reservations.where((r) {
        final name = (r['guestName'] as String? ?? '').toLowerCase();
        final room = (r['roomNumber'] as String? ?? '').toLowerCase();
        final status = _normalizeStatus(r['status'] as String? ?? '');
        final matchesQuery =
            q.isEmpty || name.contains(q) || room.contains(q) || status.contains(q);
        final matchesRoom =
            _selectedRoom == 'Toutes' || room == selectedRoom;
        final matchesStatus = () {
          switch (selectedStatus) {
            case 'Confirmée':
              return status == 'confirmed';
            case 'En séjour':
              return status == 'checked_in';
            case 'Check-out':
              return status == 'checked_out';
            case 'Annulée':
              return status == 'cancelled';
            default:
              return true;
          }
        }();
        return matchesQuery && matchesRoom && matchesStatus;
      }).toList();

      filtered.sort((a, b) {
        final aDate = DateTime.tryParse(a['checkOut'] as String? ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0);
        final bDate = DateTime.tryParse(b['checkOut'] as String? ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0);
        return bDate.compareTo(aDate);
      });

      _filtered = filtered;
    });
  }

  String _normalizeStatus(String value) {
    switch (value.toLowerCase()) {
      case 'confirmée':
        return 'confirmed';
      case 'checked_in':
      case 'checkin':
        return 'checked_in';
      case 'checked_out':
      case 'checkout':
        return 'checked_out';
      case 'annulée':
      case 'cancelled':
        return 'cancelled';
      default:
        return value.toLowerCase();
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'checked_out':
        return Colors.grey;
      case 'checked_in':
        return Colors.greenAccent;
      case 'confirmed':
        return Colors.blueAccent;
      case 'annulée':
      case 'cancelled':
        return Colors.redAccent;
      default:
        return Colors.white54;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'checked_out':
        return 'Check-out';
      case 'checked_in':
        return 'En séjour';
      case 'confirmed':
        return 'Confirmée';
      case 'annulée':
      case 'cancelled':
        return 'Annulée';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E),
      body: Column(
        children: [
          _buildHeader(),
          _buildSearch(),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _load,
                    color: const Color(0xFF6C63FF),
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemBuilder: (context, index) =>
                          _buildCard(_filtered[index]),
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemCount: _filtered.length,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFfbc2eb), Color(0xFFa6c1ee)],
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.logout_rounded, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Check-Out',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.4,
                ),
              ),
              Text(
                '${_filtered.length} séjours',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const Spacer(),
          IconButton(
            onPressed: _load,
            icon: const Icon(Icons.refresh, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildSearch() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          const Icon(Icons.search, color: Color(0xFF6C63FF)),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Nom, chambre, statut...',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                border: InputBorder.none,
              ),
              onChanged: _filter,
            ),
          ),
          const SizedBox(width: 12),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedStatus,
              dropdownColor: const Color(0xFF1A1A2E),
              items: _statusFilters
                  .map(
                    (status) => DropdownMenuItem(
                      value: status,
                      child: Text(
                        status,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value == null) return;
                setState(() => _selectedStatus = value);
                _applyFilters();
              },
              iconEnabledColor: Colors.white70,
            ),
          ),
          const SizedBox(width: 12),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedRoom,
              dropdownColor: const Color(0xFF1A1A2E),
              items: _roomFilters
                  .map(
                    (room) => DropdownMenuItem(
                      value: room,
                      child: Text(
                        room,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value == null) return;
                setState(() => _selectedRoom = value);
                _applyFilters();
              },
              iconEnabledColor: Colors.white70,
            ),
          ),
          if (_searchController.text.isNotEmpty)
            IconButton(
              onPressed: () {
                _searchController.clear();
                _filter('');
              },
              icon: const Icon(Icons.clear, color: Colors.white54),
            ),
        ],
      ),
    );
  }

  Widget _buildCard(Map<String, dynamic> r) {
    final status = r['status'] as String? ?? 'confirmed';
    final checkIn = DateTime.tryParse(r['checkIn'] as String? ?? '');
    final checkOut = DateTime.tryParse(r['checkOut'] as String? ?? '');

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.04),
            Colors.white.withOpacity(0.02),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _statusColor(status).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.logout, color: _statusColor(status)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r['guestName'] as String? ?? 'Client',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Ch. ${r['roomNumber'] ?? '?'} • ${r['roomType'] ?? 'Type'}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
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
          if (_isToday(checkOut)) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFf77062).withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFf77062).withOpacity(0.5)),
              ),
              child: const Text(
                'Départ aujourd\'hui',
                style: TextStyle(
                  color: Color(0xFFf77062),
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              _pill(
                Icons.login,
                checkIn != null ? _dateFormat.format(checkIn) : '?',
              ),
              const SizedBox(width: 8),
              _pill(
                Icons.logout,
                checkOut != null ? _dateFormat.format(checkOut) : '?',
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: (status != 'checked_in' ||
                        status == 'checked_out' ||
                        status == 'cancelled' ||
                        status == 'annulée' ||
                        !_isToday(checkOut))
                    ? null
                    : () {
                        LocalDatabase.instance
                            .updateReservationStatus(
                              r['id'] as int,
                              'checked_out',
                            )
                            .then((_) => _load());
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFf77062),
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.logout),
                label: const Text('Valider le départ'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _pill(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white60, size: 14),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

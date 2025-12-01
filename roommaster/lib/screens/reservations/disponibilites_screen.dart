import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../data/local_database.dart';

class DisponibilitesScreen extends StatefulWidget {
  const DisponibilitesScreen({super.key});

  @override
  State<DisponibilitesScreen> createState() => _DisponibilitesScreenState();
}

class _DisponibilitesScreenState extends State<DisponibilitesScreen> {
  final DateFormat _dateFormat = DateFormat('dd MMM');
  List<Map<String, dynamic>> _rooms = [];
  bool _loading = true;
  String _searchQuery = '';
  String _viewMode = 'grid'; // grid, list, floor

  @override
  void initState() {
    super.initState();
    _loadRooms();
  }

  Future<void> _loadRooms() async {
    setState(() => _loading = true);
    final rooms = await LocalDatabase.instance.fetchRooms();
    if (!mounted) return;
    setState(() {
      _rooms = rooms;
      _loading = false;
    });
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'available':
        return Colors.greenAccent;
      case 'occupied':
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
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadRooms,
              color: const Color(0xFF6C63FF),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 16),
                    _buildSearchBar(),
                    const SizedBox(height: 12),
                    _buildViewToggle(),
                    const SizedBox(height: 12),
                    _buildStatusChips(),
                    const SizedBox(height: 16),
                    _buildResultsByMode(_filteredRooms),
                  ],
                ),
              ),
            ),
    );
  }

  List<Map<String, dynamic>> get _filteredRooms {
    if (_searchQuery.isEmpty) return _rooms;
    final q = _searchQuery.toLowerCase();
    return _rooms.where((r) {
      final num = (r['number'] ?? '').toString().toLowerCase();
      final type = (r['type'] ?? '').toString().toLowerCase();
      final status = (r['status'] ?? '').toString().toLowerCase();
      final eq = (r['equipments'] ?? '').toString().toLowerCase();
      return num.contains(q) ||
          type.contains(q) ||
          status.contains(q) ||
          eq.contains(q);
    }).toList();
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF667eea), Color(0xFF764ba2)],
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF667eea).withOpacity(0.3),
                blurRadius: 12,
              ),
            ],
          ),
          child: const Icon(Icons.event_available_rounded, color: Colors.white),
        ),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Disponibilités',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.4,
              ),
            ),
            Text(
              '${_rooms.length} chambres',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 13,
              ),
            ),
          ],
        ),
        const Spacer(),
        IconButton(
          onPressed: _loadRooms,
          icon: const Icon(Icons.refresh, color: Colors.white70),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          const Icon(Icons.search, color: Color(0xFF6C63FF)),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Rechercher par numéro, type ou statut...',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                border: InputBorder.none,
              ),
              onChanged: (v) => setState(() => _searchQuery = v),
            ),
          ),
          if (_searchQuery.isNotEmpty)
            IconButton(
              onPressed: () => setState(() => _searchQuery = ''),
              icon: const Icon(Icons.clear, color: Colors.white54),
            ),
        ],
      ),
    );
  }

  Widget _buildViewToggle() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _viewButton(Icons.grid_view_rounded, 'grid', 'Grille'),
          const SizedBox(width: 6),
          _viewButton(Icons.view_list_rounded, 'list', 'Liste'),
          const SizedBox(width: 6),
          _viewButton(Icons.layers_rounded, 'floor', 'Statut'),
        ],
      ),
    );
  }

  Widget _viewButton(IconData icon, String mode, String label) {
    final selected = _viewMode == mode;
    return InkWell(
      onTap: () => setState(() => _viewMode = mode),
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          gradient: selected
              ? const LinearGradient(
                  colors: [Color(0xFF6C63FF), Color(0xFF5A52D5)],
                )
              : null,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected
                ? const Color(0xFF6C63FF)
                : Colors.white.withOpacity(0.12),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: selected ? Colors.white : Colors.white70,
              size: 18,
            ),
            if (selected) ...[
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChips() {
    final counts = <String, int>{};
    for (final r in _rooms) {
      final s = r['status'] as String? ?? 'available';
      counts[s] = (counts[s] ?? 0) + 1;
    }
    final statuses = [
      {'key': 'available', 'label': 'Disponibles'},
      {'key': 'occupied', 'label': 'Occupées'},
      {'key': 'cleaning', 'label': 'Nettoyage'},
      {'key': 'maintenance', 'label': 'Maintenance'},
    ];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: statuses
          .map(
            (s) => _buildChip(
              s['label'] as String,
              counts[s['key']] ?? 0,
              _statusColor(s['key'] as String),
            ),
          )
          .toList(),
    );
  }

  Widget _buildChip(String label, int value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, color: color, size: 10),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '$value',
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid(List<Map<String, dynamic>> items) {
    if (items.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(
          child: Text(
            'Aucune chambre disponible pour le moment',
            style: TextStyle(color: Colors.white70),
          ),
        ),
      );
    }
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: items
          .map((room) => SizedBox(width: 320, child: _buildRoomCard(room)))
          .toList(),
    );
  }

  Widget _buildList(List<Map<String, dynamic>> items) {
    if (items.isEmpty) return _buildGrid(items);
    return Column(
      children: items
          .map(
            (room) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _buildRoomCard(room),
            ),
          )
          .toList(),
    );
  }

  Widget _buildGroupedByStatus() {
    final items = _filteredRooms;
    if (items.isEmpty) return _buildGrid(items);
    final Map<String, List<Map<String, dynamic>>> grouped = {};
    for (final r in items) {
      final key = _statusLabel(r['status'] as String? ?? 'available');
      grouped.putIfAbsent(key, () => []).add(r);
    }
    final entries = grouped.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: entries
          .map(
            (entry) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.key,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                ...entry.value
                    .map(
                      (r) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _buildRoomCard(r),
                      ),
                    )
                    .toList(),
                const SizedBox(height: 12),
              ],
            ),
          )
          .toList(),
    );
  }

  Widget _buildResultsByMode(List<Map<String, dynamic>> items) {
    switch (_viewMode) {
      case 'list':
        return _buildList(items);
      case 'floor':
        return _buildGroupedByStatus();
      case 'grid':
      default:
        return _buildGrid(items);
    }
  }

  Widget _buildRoomCard(Map<String, dynamic> room) {
    final status = room['status'] as String? ?? 'available';
    final statusColor = _statusColor(status);

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
                  color: statusColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.meeting_room_rounded, color: statusColor),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ch. ${room['number'] ?? '?'}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    room['type'] as String? ?? 'Type',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _statusLabel(status),
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _iconText(
                Icons.payments_rounded,
                '${(room['rate'] as num?)?.toStringAsFixed(0) ?? '--'} FCFA',
              ),
              _iconText(
                Icons.group,
                '${room['capacity'] ?? 1} pers • ${room['bedType'] ?? 'Lit'}',
              ),
            ],
          ),
          const SizedBox(height: 8),
          if ((room['equipments'] as String?)?.isNotEmpty ?? false)
            Text(
              room['equipments'] as String,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 12,
              ),
            ),
          const SizedBox(height: 8),
          Row(
            children: [
              _smallTag(
                Icons.smoking_rooms,
                (room['smoking'] as int? ?? 0) == 1 ? 'Fumeur' : 'Non fumeur',
              ),
              const SizedBox(width: 6),
              _smallTag(
                Icons.accessible,
                (room['accessible'] as int? ?? 0) == 1 ? 'PMR' : 'Standard',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _iconText(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70, size: 16),
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
    );
  }

  Widget _smallTag(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white60, size: 12),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(color: Colors.white60, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

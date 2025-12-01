import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../data/local_database.dart';

class AnnulationsScreen extends StatefulWidget {
  const AnnulationsScreen({super.key});

  @override
  State<AnnulationsScreen> createState() => _AnnulationsScreenState();
}

class _AnnulationsScreenState extends State<AnnulationsScreen> {
  late Future<List<Map<String, dynamic>>> _future;
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _future = LocalDatabase.instance.fetchReservations();
  }

  Future<void> _refresh() async {
    setState(() {
      _future = LocalDatabase.instance.fetchReservations();
    });
  }

  List<Map<String, dynamic>> _filtered(List<Map<String, dynamic>> data) {
    final cancelled = data.where((r) {
      final status = (r['status'] as String? ?? '').toLowerCase();
      return status == 'cancelled' || status == 'annulée';
    }).toList();
    if (_searchQuery.isEmpty) return cancelled;
    final q = _searchQuery.toLowerCase();
    return cancelled.where((r) {
      final name = (r['guestName'] as String? ?? '').toLowerCase();
      final room = (r['roomNumber'] as String? ?? '').toLowerCase();
      final email = (r['guestEmail'] as String? ?? '').toLowerCase();
      return name.contains(q) || room.contains(q) || email.contains(q);
    }).toList();
  }

  Color _statusColor() => Colors.redAccent;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E),
      body: Column(
        children: [
          _buildHeader(),
          _buildSearchBar(),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final data = snapshot.data ?? [];
                final filtered = _filtered(data);
                if (filtered.isEmpty) {
                  return const Center(
                    child: Text(
                      'Aucune annulation',
                      style: TextStyle(color: Colors.white70),
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: _refresh,
                  color: const Color(0xFF6C63FF),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) =>
                        _buildCancellationCard(filtered[index]),
                  ),
                );
              },
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
                colors: [Color(0xFFf77062), Color(0xFFfe5196)],
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.cancel_rounded, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Annulations',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.4,
                ),
              ),
              Text(
                'Réservations annulées',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
          const Spacer(),
          IconButton(
            onPressed: _refresh,
            icon: const Icon(Icons.refresh, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
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
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Rechercher un nom, une chambre...',
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

  Widget _buildCancellationCard(Map<String, dynamic> r) {
    final checkIn = DateTime.tryParse(r['checkIn'] as String? ?? '');
    final checkOut = DateTime.tryParse(r['checkOut'] as String? ?? '');
    final reason = r['cancellationReason'] as String? ?? '';

    return Container(
      padding: const EdgeInsets.all(16),
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
                  color: _statusColor().withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.cancel_rounded, color: _statusColor()),
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
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
                  color: _statusColor().withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Annulée',
                  style: TextStyle(
                    color: _statusColor(),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _infoPill(
                Icons.login_rounded,
                checkIn != null ? _dateFormat.format(checkIn) : '?',
              ),
              const SizedBox(width: 8),
              _infoPill(
                Icons.logout_rounded,
                checkOut != null ? _dateFormat.format(checkOut) : '?',
              ),
              const Spacer(),
              _infoPill(Icons.payments, '${r['amount'] ?? '--'} FCFA'),
            ],
          ),
          const SizedBox(height: 8),
          if (reason.isNotEmpty)
            Text(
              'Motif: $reason',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          if (reason.isNotEmpty) const SizedBox(height: 6),
          if (r['notes'] != null && (r['notes'] as String).isNotEmpty)
            Text(
              r['notes'] as String,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 12,
              ),
            ),
        ],
      ),
    );
  }

  Widget _infoPill(IconData icon, String text) {
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

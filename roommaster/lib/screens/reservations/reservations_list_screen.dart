import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../data/local_database.dart';
import 'new_reservation_screen.dart';

class ReservationsListScreen extends StatefulWidget {
  const ReservationsListScreen({Key? key}) : super(key: key);

  @override
  State<ReservationsListScreen> createState() => _ReservationsListScreenState();
}

class _ReservationsListScreenState extends State<ReservationsListScreen> {
  late Future<List<Map<String, dynamic>>> _future;
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');
  final NumberFormat _moneyFormat = NumberFormat.currency(
    locale: 'fr_FR',
    symbol: 'FCFA',
    decimalDigits: 0,
  );
  String _formatTime(String? value) {
    if (value == null || value.isEmpty) return '';
    return value;
  }

  // Filtres
  String _filterStatus = 'Tous';
  String _filterSource = 'Tous';
  String _searchQuery = '';
  String _sortBy = 'date'; // date, name, room
  bool _showFilters = false;
  String _viewMode = 'grid'; // grid, list, floor

  final List<String> _statusFilters = [
    'Tous',
    'Confirmée',
    'Provisoire',
    'Arrivée',
    'Départ',
    'Annulée',
    'No-show',
  ];

  final List<String> _sourceFilters = [
    'Tous',
    'Direct',
    'Site web',
    'Booking.com',
    'Airbnb',
    'Agence voyage',
  ];

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

  String _statusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
      case 'confirmée':
        return 'Confirmée';
      case 'provisional':
      case 'provisoire':
        return 'Provisoire';
      case 'cancelled':
      case 'annulée':
        return 'Annulée';
      case 'checked_in':
      case 'arrivée':
        return 'Arrivée';
      case 'checked_out':
      case 'départ':
        return 'Départ';
      case 'no-show':
      case 'no_show':
        return 'No-show';
      case 'pending':
      case 'en attente':
        return 'En attente';
      default:
        return status;
    }
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
      case 'confirmée':
        return const Color(0xFF4CAF50);
      case 'provisional':
      case 'provisoire':
        return const Color(0xFFFFA726);
      case 'cancelled':
      case 'annulée':
        return const Color(0xFFEF5350);
      case 'checked_in':
      case 'arrivée':
        return const Color(0xFF42A5F5);
      case 'checked_out':
      case 'départ':
        return const Color(0xFF9C27B0);
      case 'no-show':
      case 'no_show':
        return const Color(0xFFFF5252);
      case 'pending':
      case 'en attente':
        return const Color(0xFFFFB74D);
      default:
        return Colors.grey;
    }
  }

  IconData _statusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
      case 'confirmée':
        return Icons.check_circle;
      case 'provisional':
      case 'provisoire':
        return Icons.schedule;
      case 'cancelled':
      case 'annulée':
        return Icons.cancel;
      case 'checked_in':
      case 'arrivée':
        return Icons.login;
      case 'checked_out':
      case 'départ':
        return Icons.logout;
      case 'no-show':
      case 'no_show':
        return Icons.person_off;
      case 'pending':
      case 'en attente':
        return Icons.hourglass_empty;
      default:
        return Icons.event;
    }
  }

  List<Map<String, dynamic>> _filterAndSortData(
    List<Map<String, dynamic>> data,
  ) {
    var filtered = data.where((r) {
      // Filtre par statut
      if (_filterStatus != 'Tous') {
        final status = _statusLabel(r['status'] as String? ?? '');
        if (status != _filterStatus) return false;
      }

      // Filtre par source
      if (_filterSource != 'Tous') {
        final source = r['source'] as String? ?? 'Direct';
        if (source != _filterSource) return false;
      }

      // Recherche
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final name = (r['guestName'] as String? ?? '').toLowerCase();
        final room = (r['roomNumber'] as String? ?? '').toLowerCase();
        final email = (r['guestEmail'] as String? ?? '').toLowerCase();
        if (!name.contains(query) &&
            !room.contains(query) &&
            !email.contains(query)) {
          return false;
        }
      }

      return true;
    }).toList();

    // Tri
    filtered.sort((a, b) {
      switch (_sortBy) {
        case 'name':
          return (a['guestName'] as String? ?? '').compareTo(
            b['guestName'] as String? ?? '',
          );
        case 'room':
          return (a['roomNumber'] as String? ?? '').compareTo(
            b['roomNumber'] as String? ?? '',
          );
        case 'date':
        default:
          final dateA = DateTime.tryParse(a['checkIn'] as String? ?? '');
          final dateB = DateTime.tryParse(b['checkIn'] as String? ?? '');
          if (dateA == null || dateB == null) return 0;
          return dateB.compareTo(dateA); // Plus récent en premier
      }
    });

    return filtered;
  }

  int _calculateNights(DateTime checkIn, DateTime checkOut) {
    return checkOut.difference(checkIn).inDays;
  }

  String _getReservationDuration(Map<String, dynamic> r) {
    final checkIn = DateTime.tryParse(r['checkIn'] as String? ?? '');
    final checkOut = DateTime.tryParse(r['checkOut'] as String? ?? '');
    if (checkIn == null || checkOut == null) return '';
    final nights = _calculateNights(checkIn, checkOut);
    return '$nights nuit${nights > 1 ? 's' : ''}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E),
      body: Column(
        children: [
          _buildAppBar(),
          _buildSearchBar(),
          if (_showFilters) _buildFilterSection(),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFF6C63FF)),
                  );
                }
                final allData = snapshot.data ?? [];
                final filteredData = _filterAndSortData(allData);

                if (allData.isEmpty) {
                  return _buildEmptyState(
                    icon: Icons.event_busy_rounded,
                    message: 'Aucune réservation',
                    subtitle: 'Créez votre première réservation',
                  );
                }

                if (filteredData.isEmpty) {
                  return _buildEmptyState(
                    icon: Icons.search_off,
                    message: 'Aucun résultat',
                    subtitle: 'Essayez d\'autres filtres',
                  );
                }

                return Column(
                  children: [
                    _buildResultsHeader(filteredData.length, allData.length),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: _buildViewModeToggle(),
                      ),
                    ),
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: _refresh,
                        color: const Color(0xFF6C63FF),
                        child: _buildResultsByMode(filteredData),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1A1A2E).withOpacity(0.95),
            const Color(0xFF16213E).withOpacity(0.95),
          ],
        ),
        border: Border(
          bottom: BorderSide(color: const Color(0xFF6C63FF).withOpacity(0.3)),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF667eea), Color(0xFF764ba2)],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF667eea).withOpacity(0.3),
                  blurRadius: 12,
                ),
              ],
            ),
            child: const Icon(Icons.list_alt_rounded, color: Colors.white),
          ),
          const SizedBox(width: 16),
          const Text(
            'Réservations',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: Icon(
              _showFilters ? Icons.filter_alt : Icons.filter_alt_outlined,
              color: _showFilters ? const Color(0xFF6C63FF) : Colors.white70,
            ),
            onPressed: () {
              setState(() => _showFilters = !_showFilters);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          const Icon(Icons.search, color: Color(0xFF6C63FF)),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Rechercher par nom, chambre, email...',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
                border: InputBorder.none,
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value);
              },
            ),
          ),
          if (_searchQuery.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear, color: Colors.white54),
              onPressed: () {
                setState(() => _searchQuery = '');
              },
            ),
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.tune, color: Color(0xFF6C63FF), size: 20),
              const SizedBox(width: 8),
              const Text(
                'Filtres',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {
                  setState(() {
                    _filterStatus = 'Tous';
                    _filterSource = 'Tous';
                    _sortBy = 'date';
                  });
                },
                child: const Text(
                  'Réinitialiser',
                  style: TextStyle(color: Color(0xFF6C63FF)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildFilterChips(
            label: 'Statut',
            options: _statusFilters,
            selected: _filterStatus,
            onSelected: (value) => setState(() => _filterStatus = value),
          ),
          const SizedBox(height: 12),
          _buildFilterChips(
            label: 'Source',
            options: _sourceFilters,
            selected: _filterSource,
            onSelected: (value) => setState(() => _filterSource = value),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                'Trier par:',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 8),
              _buildSortChip('Date', 'date'),
              const SizedBox(width: 8),
              _buildSortChip('Nom', 'name'),
              const SizedBox(width: 8),
              _buildSortChip('Chambre', 'room'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips({
    required String label,
    required List<String> options,
    required String selected,
    required ValueChanged<String> onSelected,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((option) {
            final isSelected = option == selected;
            return InkWell(
              onTap: () => onSelected(option),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF6C63FF).withOpacity(0.2)
                      : Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF6C63FF)
                        : Colors.white.withOpacity(0.1),
                  ),
                ),
                child: Text(
                  option,
                  style: TextStyle(
                    color: isSelected
                        ? const Color(0xFF6C63FF)
                        : Colors.white70,
                    fontSize: 12,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSortChip(String label, String value) {
    final isSelected = _sortBy == value;
    return InkWell(
      onTap: () => setState(() => _sortBy = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF6C63FF).withOpacity(0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF6C63FF)
                : Colors.white.withOpacity(0.2),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? const Color(0xFF6C63FF) : Colors.white70,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildResultsHeader(int filtered, int total) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Text(
            '$filtered résultat${filtered > 1 ? 's' : ''}',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 13,
            ),
          ),
          if (filtered != total)
            Text(
              ' sur $total',
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 13,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String message,
    required String subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white54, size: 64),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReservationCard(Map<String, dynamic> r) {
    final status = r['status'] as String? ?? 'confirmed';
    final checkIn = DateTime.tryParse(r['checkIn'] as String? ?? '');
    final checkOut = DateTime.tryParse(r['checkOut'] as String? ?? '');
    final amount = (r['amount'] as num?)?.toDouble() ?? 0;
    final source = r['source'] as String? ?? 'Direct';
    final roomType = r['roomType'] as String? ?? 'Standard';
    final bedType = r['bedType'] as String? ?? '';
    final lodgingType = r['lodgingType'] as String? ?? '';
    final adults = r['adults'] as int? ?? 1;
    final children = r['children'] as int? ?? 0;
    final duration = _getReservationDuration(r);
    final services = (r['services'] as String? ?? '')
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    return InkWell(
      onTap: () => _showReservationDetails(r),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.white.withOpacity(0.05),
              Colors.white.withOpacity(0.02),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _statusColor(status).withOpacity(0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: _statusColor(status).withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _statusColor(status).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _statusIcon(status),
                    color: _statusColor(status),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        r['guestName'] as String? ?? 'Client',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            Icons.meeting_room_rounded,
                            size: 14,
                            color: Colors.white.withOpacity(0.6),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              [
                                'Ch. ${r['roomNumber'] ?? '?'}',
                                if (lodgingType.isNotEmpty) lodgingType,
                                roomType,
                                if (bedType.isNotEmpty) 'Lit $bedType',
                              ].where((e) => e.isNotEmpty).join(' • '),
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 13,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _statusColor(status).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _statusColor(status).withOpacity(0.5),
                    ),
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
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.03),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoItem(
                          icon: Icons.login,
                          label: 'Arrivée',
                          value: checkIn != null
                              ? _dateFormat.format(checkIn)
                              : '?',
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 30,
                        color: Colors.white.withOpacity(0.1),
                      ),
                      Expanded(
                        child: _buildInfoItem(
                          icon: Icons.logout,
                          label: 'Départ',
                          value: checkOut != null
                              ? _dateFormat.format(checkOut)
                              : '?',
                        ),
                      ),
                    ],
                  ),
                  if (duration.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6C63FF).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.nights_stay,
                            size: 14,
                            color: Color(0xFF6C63FF),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            duration,
                            style: const TextStyle(
                              color: Color(0xFF6C63FF),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildTag(
                  icon: Icons.people,
                  text: '$adults${children > 0 ? ' + $children' : ''}',
                ),
                const SizedBox(width: 8),
                _buildTag(icon: Icons.source, text: source),
                if (services.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Flexible(
                    child: Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: services
                          .map(
                            (s) => _buildTag(
                              icon: Icons.check_circle_outline,
                              text: s,
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ],
                const Spacer(),
                if (amount > 0)
                  Text(
                    _moneyFormat.format(amount),
                    style: const TextStyle(
                      color: Color(0xFF4facfe),
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: const Color(0xFF6C63FF)),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 11,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildTag({required IconData icon, required String text}) {
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
          Icon(icon, size: 12, color: Colors.white60),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(color: Colors.white60, fontSize: 11),
          ),
        ],
      ),
    );
  }

  void _showReservationDetails(Map<String, dynamic> r) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _buildDetailsSheet(r),
    );
  }

  Widget _buildDetailsSheet(Map<String, dynamic> r) {
    final status = r['status'] as String? ?? 'confirmed';
    final checkIn = DateTime.tryParse(r['checkIn'] as String? ?? '');
    final checkOut = DateTime.tryParse(r['checkOut'] as String? ?? '');
    final amount = (r['amount'] as num?)?.toDouble() ?? 0;
    final services = (r['services'] as String? ?? '')
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    final paymentStatus = r['paymentStatus'] as String? ?? 'En attente';
    final lodgingType = r['lodgingType'] as String? ?? '';
    final bedType = r['bedType'] as String? ?? '';
    final idNumber = r['idNumber'] as String? ?? '';
    final idIssuedOn = r['idIssuedOn'] as String? ?? '';
    final idIssuedAt = r['idIssuedAt'] as String? ?? '';
    final visaNumber = r['visaNumber'] as String? ?? '';
    final visaIssuedOn = r['visaIssuedOn'] as String? ?? '';
    final visaIssuedAt = r['visaIssuedAt'] as String? ?? '';
    final nationality = r['nationality'] as String? ?? '';
    final placeOfBirth = r['placeOfBirth'] as String? ?? '';
    final dateOfBirth = r['dateOfBirth'] as String? ?? '';
    final profession = r['profession'] as String? ?? '';
    final domicile = r['domicile'] as String? ?? '';
    final travelReason = r['travelReason'] as String? ?? '';
    final comingFrom = r['comingFrom'] as String? ?? '';
    final goingTo = r['goingTo'] as String? ?? '';
    final emergencyAddress = r['emergencyAddress'] as String? ?? '';
    final breakfast = (r['breakfastIncluded'] as int? ?? 0) == 1;
    final parking = (r['parkingIncluded'] as int? ?? 0) == 1;
    final wifi = (r['wifiIncluded'] as int? ?? 1) == 1;
    final checkInTime = _formatTime(r['checkInTime'] as String?);
    final checkOutTime = _formatTime(r['checkOutTime'] as String?);

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _statusColor(status).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _statusIcon(status),
                    color: _statusColor(status),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        r['guestName'] as String? ?? 'Client',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _statusLabel(status),
                        style: TextStyle(
                          color: _statusColor(status),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white70),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                ElevatedButton.icon(
                  onPressed: () async {
                    Navigator.pop(context);
                    final updated = await showDialog<bool>(
                      context: context,
                      barrierDismissible: false,
                      builder: (context) {
                        return Dialog(
                          insetPadding: const EdgeInsets.all(24),
                          backgroundColor: Colors.transparent,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 1100),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(24),
                              child: Stack(
                                children: [
                                  Container(
                                    color: const Color(0xFF0F0F1E),
                                    child: NewReservationScreen(
                                      initialReservation: r,
                                    ),
                                  ),
                                  Positioned(
                                    top: 12,
                                    right: 12,
                                    child: IconButton(
                                      icon: const Icon(
                                        Icons.close,
                                        color: Colors.white70,
                                      ),
                                      onPressed: () {
                                        Navigator.of(context).pop(false);
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                    if (updated == true) {
                      _refresh();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C63FF),
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.edit),
                  label: const Text('Modifier'),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _showCancelDialog(r);
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                  ),
                  icon: const Icon(Icons.cancel_outlined),
                  label: const Text('Annuler'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailSection('Informations réservation', [
                    _buildDetailRow('Chambre', r['roomNumber'] ?? '?'),
                    _buildDetailRow(
                      'Type',
                      [
                        r['roomType'] ?? 'Standard',
                        if (lodgingType.isNotEmpty) lodgingType,
                        if (bedType.isNotEmpty) 'Lit $bedType',
                      ].where((e) => (e as String).isNotEmpty).join(' • '),
                    ),
                    _buildDetailRow(
                      'Arrivée',
                      checkIn != null ? _dateFormat.format(checkIn) : '?',
                    ),
                    if (checkInTime.isNotEmpty)
                      _buildDetailRow('Heure arrivée', checkInTime),
                    _buildDetailRow(
                      'Départ',
                      checkOut != null ? _dateFormat.format(checkOut) : '?',
                    ),
                    if (checkOutTime.isNotEmpty)
                      _buildDetailRow('Heure départ', checkOutTime),
                    _buildDetailRow('Durée', _getReservationDuration(r)),
                  ]),
                  const SizedBox(height: 20),
                  _buildDetailSection('Identité & voyage', [
                    _buildDetailRow(
                      'Nationalité',
                      nationality.isEmpty ? 'Non renseigné' : nationality,
                    ),
                    _buildDetailRow(
                      'Date de naissance',
                      dateOfBirth.isEmpty
                          ? 'Non renseigné'
                          : dateOfBirth.split('T').first,
                    ),
                    _buildDetailRow(
                      'Lieu de naissance',
                      placeOfBirth.isEmpty ? 'Non renseigné' : placeOfBirth,
                    ),
                    _buildDetailRow(
                      'Profession',
                      profession.isEmpty ? 'Non renseigné' : profession,
                    ),
                    _buildDetailRow(
                      'Domicile',
                      domicile.isEmpty ? 'Non renseigné' : domicile,
                    ),
                    _buildDetailRow(
                      'Motif du voyage',
                      travelReason.isEmpty ? 'Non renseigné' : travelReason,
                    ),
                    _buildDetailRow(
                      'Venant de',
                      comingFrom.isEmpty ? 'Non renseigné' : comingFrom,
                    ),
                    _buildDetailRow(
                      'Allant à',
                      goingTo.isEmpty ? 'Non renseigné' : goingTo,
                    ),
                  ]),
                  const SizedBox(height: 20),
                  _buildDetailSection('Documents', [
                    _buildDetailRow(
                      'Pièce d'
                      'identité',
                      idNumber.isEmpty ? 'Non renseigné' : idNumber,
                    ),
                    _buildDetailRow(
                      'Délivré le',
                      idIssuedOn.isEmpty
                          ? 'Non renseigné'
                          : idIssuedOn.split('T').first,
                    ),
                    _buildDetailRow(
                      'Délivré à',
                      idIssuedAt.isEmpty ? 'Non renseigné' : idIssuedAt,
                    ),
                    _buildDetailRow(
                      'Visa N°',
                      visaNumber.isEmpty ? 'Non renseigné' : visaNumber,
                    ),
                    _buildDetailRow(
                      'Visa délivré le',
                      visaIssuedOn.isEmpty
                          ? 'Non renseigné'
                          : visaIssuedOn.split('T').first,
                    ),
                    _buildDetailRow(
                      'Visa délivré à',
                      visaIssuedAt.isEmpty ? 'Non renseigné' : visaIssuedAt,
                    ),
                    _buildDetailRow(
                      'Contact d\'urgence',
                      emergencyAddress.isEmpty
                          ? 'Non renseigné'
                          : emergencyAddress,
                    ),
                  ]),
                  const SizedBox(height: 20),
                  _buildDetailSection('Contact', [
                    _buildDetailRow(
                      'Email',
                      r['guestEmail'] ?? 'Non renseigné',
                    ),
                    _buildDetailRow(
                      'Téléphone',
                      r['guestPhone'] ?? 'Non renseigné',
                    ),
                    _buildDetailRow('Adultes', '${r['adults'] ?? 1}'),
                    _buildDetailRow('Enfants', '${r['children'] ?? 0}'),
                  ]),
                  const SizedBox(height: 20),
                  _buildDetailSection('Tarification', [
                    _buildDetailRow(
                      'Montant total',
                      _moneyFormat.format(amount),
                    ),
                    _buildDetailRow('Source', r['source'] ?? 'Direct'),
                    _buildDetailRow('Statut paiement', paymentStatus),
                    _buildDetailRow(
                      'Acompte versé',
                      _moneyFormat.format(
                        (r['deposit'] as num?)?.toDouble() ?? 0,
                      ),
                    ),
                    _buildDetailRow(
                      'Solde restant',
                      _moneyFormat.format(
                        amount - ((r['deposit'] as num?)?.toDouble() ?? 0),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 20),
                  if (services.isNotEmpty)
                    _buildDetailSection(
                      'Services inclus',
                      services
                          .map(
                            (s) => Container(
                              margin: const EdgeInsets.only(bottom: 6),
                              child: _buildDetailRow('Service', s),
                            ),
                          )
                          .toList(),
                    ),
                  if (services.isNotEmpty) const SizedBox(height: 20),
                  _buildDetailSection('Options', [
                    _buildDetailRow(
                      'Petit-déjeuner',
                      breakfast ? 'Inclus' : 'Non inclus',
                    ),
                    _buildDetailRow(
                      'Parking',
                      parking ? 'Inclus' : 'Non inclus',
                    ),
                    _buildDetailRow('WiFi', wifi ? 'Inclus' : 'Non inclus'),
                  ]),
                  const SizedBox(height: 20),
                  if (r['notes'] != null && (r['notes'] as String).isNotEmpty)
                    _buildDetailSection('Notes', [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.1),
                          ),
                        ),
                        child: Text(
                          r['notes'] as String,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ]),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.03),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewModeToggle() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildViewModeButton(Icons.grid_view_rounded, 'grid', 'Grille'),
          const SizedBox(width: 6),
          _buildViewModeButton(Icons.view_list_rounded, 'list', 'Liste'),
          const SizedBox(width: 6),
          _buildViewModeButton(Icons.layers_rounded, 'floor', 'Étages'),
        ],
      ),
    );
  }

  Widget _buildViewModeButton(IconData icon, String mode, String label) {
    final isSelected = _viewMode == mode;
    return InkWell(
      onTap: () => setState(() => _viewMode = mode),
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  colors: [Color(0xFF6C63FF), Color(0xFF5A52D5)],
                )
              : null,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF6C63FF)
                : Colors.white.withOpacity(0.1),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.white70,
              size: 18,
            ),
            if (isSelected) ...[
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

  Widget _buildResultsByMode(List<Map<String, dynamic>> data) {
    switch (_viewMode) {
      case 'list':
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemBuilder: (context, index) {
            final r = data[index];
            return _buildReservationCard(r);
          },
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemCount: data.length,
        );
      case 'floor':
        return _buildGroupedByStatus(data);
      case 'grid':
      default:
        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 420,
            mainAxisSpacing: 14,
            crossAxisSpacing: 14,
            childAspectRatio: 0.95,
          ),
          itemCount: data.length,
          itemBuilder: (context, index) {
            final r = data[index];
            return _buildReservationCard(r);
          },
        );
    }
  }

  Widget _buildGroupedByStatus(List<Map<String, dynamic>> data) {
    final Map<String, List<Map<String, dynamic>>> grouped = {};
    for (final r in data) {
      final status = _statusLabel(r['status'] as String? ?? '');
      grouped.putIfAbsent(status, () => []).add(r);
    }
    final entries = grouped.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: entries.length,
      itemBuilder: (context, idx) {
        final entry = entries[idx];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              entry.key,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ...entry.value
                .map(
                  (r) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildReservationCard(r),
                  ),
                )
                .toList(),
            const SizedBox(height: 12),
          ],
        );
      },
    );
  }

  void _confirmDelete(Map<String, dynamic> r) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Supprimer la réservation',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Voulez-vous vraiment supprimer la réservation de ${r['guestName']} ?',
          style: TextStyle(color: Colors.white.withOpacity(0.8)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final id = r['id'] as int?;
              if (id != null) {
                await LocalDatabase.instance.deleteReservation(id);
              }
              _refresh();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Réservation supprimée'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  void _showCancelDialog(Map<String, dynamic> r) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Annuler la réservation',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: reasonController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Motif',
                labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                  borderSide: BorderSide(color: Color(0xFF6C63FF)),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
          ElevatedButton(
            onPressed: () async {
              final id = r['id'] as int?;
              if (id != null) {
                await LocalDatabase.instance.cancelReservation(
                  id,
                  reasonController.text.trim(),
                );
              }
              Navigator.pop(context);
              _refresh();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Réservation annulée')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Annuler'),
          ),
        ],
      ),
    );
  }
}

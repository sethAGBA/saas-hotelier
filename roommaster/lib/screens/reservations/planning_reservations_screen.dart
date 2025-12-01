import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../data/local_database.dart';

class PlanningReservationsScreen extends StatefulWidget {
  const PlanningReservationsScreen({super.key});

  @override
  State<PlanningReservationsScreen> createState() =>
      _PlanningReservationsScreenState();
}

class _PlanningReservationsScreenState
    extends State<PlanningReservationsScreen> {
  final DateFormat _monthFormat = DateFormat.yMMMM('fr_FR');
  final DateFormat _dayFormat = DateFormat.E('fr_FR');
  final DateFormat _dateFormat = DateFormat('dd/MM');
  DateTime _focusedMonth = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    1,
  );
  late final List<String> _monthLabels;
  late final List<int> _yearOptions;
  List<Map<String, dynamic>> _reservations = [];
  bool _loading = true;
  Map<String, int> _statusCounts = {};

  String _normalizeStatus(String value) {
    switch (value.toLowerCase()) {
      case 'confirmée':
        return 'confirmed';
      case 'annulée':
        return 'cancelled';
      case 'checked_in':
      case 'checkin':
        return 'checked_in';
      case 'checked_out':
      case 'checkout':
        return 'checked_out';
      default:
        return value.toLowerCase();
    }
  }

  @override
  void initState() {
    super.initState();
    _monthLabels = List.generate(
      12,
      (i) => DateFormat.MMMM('fr_FR').format(DateTime(2024, i + 1, 1)),
    );
    final currentYear = DateTime.now().year;
    _yearOptions = List.generate(6, (i) => currentYear - 2 + i);
    _loadReservations();
  }

  Future<void> _loadReservations() async {
    setState(() => _loading = true);
    final data = await LocalDatabase.instance.fetchReservations();
    if (!mounted) return;
    setState(() {
      _reservations = data
          .map(
            (r) => {
              ...r,
              'status': _normalizeStatus(r['status'] as String? ?? ''),
            },
          )
          .toList()
        ..sort((a, b) {
          final aDate = DateTime.tryParse(a['checkIn'] as String? ?? '') ??
              DateTime.fromMillisecondsSinceEpoch(0);
          final bDate = DateTime.tryParse(b['checkIn'] as String? ?? '') ??
              DateTime.fromMillisecondsSinceEpoch(0);
          return bDate.compareTo(aDate);
        });
      _statusCounts = _computeStatusCounts(_reservations);
      _loading = false;
    });
  }

  Map<String, int> _computeStatusCounts(List<Map<String, dynamic>> data) {
    final counts = <String, int>{};
    for (final r in data) {
      final s = r['status'] as String? ?? 'confirmed';
      counts[s] = (counts[s] ?? 0) + 1;
    }
    return counts;
  }

  void _changeMonth(int delta) {
    setState(() {
      _focusedMonth = DateTime(
        _focusedMonth.year,
        _focusedMonth.month + delta,
        1,
      );
    });
  }

  List<Map<String, dynamic>> _reservationsForDay(DateTime day) {
    return _reservations.where((r) {
      final checkIn = DateTime.tryParse(r['checkIn'] as String? ?? '');
      final checkOut = DateTime.tryParse(r['checkOut'] as String? ?? '');
      if (checkIn == null || checkOut == null) return false;
      final target = DateTime(day.year, day.month, day.day);
      return !target.isBefore(
            DateTime(checkIn.year, checkIn.month, checkIn.day),
          ) &&
          !target.isAfter(
            DateTime(checkOut.year, checkOut.month, checkOut.day),
          );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _loadReservations,
                    color: const Color(0xFF6C63FF),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          _buildSynoptic(),
                          const SizedBox(height: 20),
                          _buildCalendar(),
                          const SizedBox(height: 20),
                          _buildTimeline(),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
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
      child: Column(
        children: [
          Row(
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
                child: const Icon(
                  Icons.calendar_month_rounded,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Planning Réservations',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                  Text(
                    '${_reservations.length} réservations • ${_monthFormat.format(_focusedMonth)}',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              _buildMonthYearSelector(),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildStatChip(
                'Confirmées',
                _statusCounts['confirmed'] ?? 0,
                Colors.greenAccent,
              ),
              _buildStatChip(
                'Annulées',
                _statusCounts['cancelled'] ?? 0,
                Colors.redAccent,
              ),
              _buildStatChip(
                'Arrivées',
                _statusCounts['checked_in'] ?? 0,
                Colors.blueAccent,
              ),
              _buildStatChip(
                'Départs',
                _statusCounts['checked_out'] ?? 0,
                Colors.purpleAccent,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSynoptic() {
    final tiles = [
      {
        'label': 'Disponibles',
        'value': _statusCounts['available'] ?? 0,
        'color': Colors.green,
      },
      {
        'label': 'Occupées',
        'value': _statusCounts['occupied'] ?? 0,
        'color': Colors.red,
      },
      {
        'label': 'Nettoyage',
        'value': _statusCounts['cleaning'] ?? 0,
        'color': Colors.orange,
      },
      {
        'label': 'Maintenance',
        'value': _statusCounts['maintenance'] ?? 0,
        'color': Colors.grey,
      },
      {
        'label': 'Réservées',
        'value': _statusCounts['reserved'] ?? 0,
        'color': Colors.purple,
      },
      {
        'label': 'Annulées',
        'value': _statusCounts['cancelled'] ?? 0,
        'color': Colors.pinkAccent,
      },
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: tiles
            .map(
              (t) => _buildStatChip(
                '${t['label']}',
                t['value'] as int,
                t['color'] as Color,
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildCalendar() {
    final firstDayOfMonth = DateTime(
      _focusedMonth.year,
      _focusedMonth.month,
      1,
    );
    final daysInMonth = DateUtils.getDaysInMonth(
      _focusedMonth.year,
      _focusedMonth.month,
    );
    final startWeekday = firstDayOfMonth.weekday % 7; // Monday=1
    final totalCells = startWeekday + daysInMonth;
    final rows = (totalCells / 7).ceil();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (index) {
              final day = DateTime(2024, 1, 1 + index); // dummy week
              return Expanded(
                child: Center(
                  child: Text(
                    _dayFormat.format(day).toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 12),
          Column(
            children: List.generate(rows, (row) {
              return Row(
                children: List.generate(7, (col) {
                  final index = row * 7 + col;
                  final dayNumber = index - startWeekday + 1;
                  if (index < startWeekday || dayNumber > daysInMonth) {
                    return Expanded(child: Container(height: 60));
                  }
                  final day = DateTime(
                    _focusedMonth.year,
                    _focusedMonth.month,
                    dayNumber,
                  );
                  final dayReservations = _reservationsForDay(day);
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => _showDayDetails(day, dayReservations),
                      child: Container(
                        margin: const EdgeInsets.all(4),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.white.withOpacity(
                            dayReservations.isNotEmpty ? 0.08 : 0.02,
                          ),
                          border: Border.all(
                            color: dayReservations.isNotEmpty
                                ? const Color(0xFF6C63FF).withOpacity(0.4)
                                : Colors.white.withOpacity(0.05),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$dayNumber',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            if (dayReservations.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF6C63FF,
                                  ).withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${dayReservations.length} rés.',
                                  style: const TextStyle(
                                    color: Color(0xFF6C63FF),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeline() {
    final sorted = [..._reservations];
    sorted.sort((a, b) {
      final aDate =
          DateTime.tryParse(a['checkIn'] as String? ?? '') ?? DateTime(1970);
      final bDate =
          DateTime.tryParse(b['checkIn'] as String? ?? '') ?? DateTime(1970);
      return aDate.compareTo(bDate);
    });

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.timeline, color: Color(0xFF6C63FF)),
              SizedBox(width: 8),
              Text(
                'Timeline',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...sorted.map((r) => _buildTimelineTile(r)).toList(),
        ],
      ),
    );
  }

  Widget _buildTimelineTile(Map<String, dynamic> r) {
    final checkIn = DateTime.tryParse(r['checkIn'] as String? ?? '');
    final checkOut = DateTime.tryParse(r['checkOut'] as String? ?? '');
    final status = r['status'] as String? ?? 'confirmed';
    final color = _statusColor(status);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 48,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(6),
            ),
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
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Ch. ${r['roomNumber'] ?? '?'} • ${r['roomType'] ?? 'Standard'}',
                  style: TextStyle(color: Colors.white.withOpacity(0.7)),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                checkIn != null ? _dateFormat.format(checkIn) : '?',
                style: const TextStyle(color: Colors.white70),
              ),
              Text(
                checkOut != null ? _dateFormat.format(checkOut) : '?',
                style: const TextStyle(color: Colors.white38, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(String label, int value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.4)),
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

  void _showDayDetails(DateTime day, List<Map<String, dynamic>> reservations) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.5,
          decoration: const BoxDecoration(
            color: Color(0xFF1A1A2E),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
              const SizedBox(height: 16),
              Text(
                DateFormat.yMMMMEEEEd('fr_FR').format(day),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: reservations.isEmpty
                    ? const Center(
                        child: Text(
                          'Aucune réservation ce jour',
                          style: TextStyle(color: Colors.white70),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: reservations.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final r = reservations[index];
                          return _buildTimelineTile(r);
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'confirmée':
      case 'confirmed':
        return Colors.greenAccent;
      case 'annulée':
      case 'cancelled':
        return Colors.redAccent;
      case 'checked_in':
        return Colors.blueAccent;
      case 'checked_out':
        return Colors.purpleAccent;
      default:
        return Colors.white54;
    }
  }

  Widget _buildMonthYearSelector() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => _changeMonth(-1),
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.white70,
              size: 18,
            ),
          ),
          const SizedBox(width: 6),
          DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              dropdownColor: const Color(0xFF1A1A2E),
              value: _focusedMonth.month,
              items: List.generate(
                12,
                (i) => DropdownMenuItem(
                  value: i + 1,
                  child: Text(
                    _monthLabels[i],
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
              onChanged: (v) {
                if (v == null) return;
                setState(() {
                  _focusedMonth = DateTime(_focusedMonth.year, v, 1);
                });
              },
            ),
          ),
          const SizedBox(width: 6),
          DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              dropdownColor: const Color(0xFF1A1A2E),
              value: _focusedMonth.year,
              items: _yearOptions
                  .map(
                    (y) => DropdownMenuItem(
                      value: y,
                      child: Text(
                        '$y',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (v) {
                if (v == null) return;
                setState(() {
                  _focusedMonth = DateTime(v, _focusedMonth.month, 1);
                });
              },
            ),
          ),
          const SizedBox(width: 6),
          IconButton(
            onPressed: () => _changeMonth(1),
            icon: const Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.white70,
              size: 18,
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../data/local_database.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final money = NumberFormat.currency(
      locale: 'fr_FR',
      symbol: 'FCFA',
      decimalDigits: 0,
    );
    return FutureBuilder<_AnalyticsData>(
      future: _loadAnalytics(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const _AnalyticsScaffold(
            title: 'Analytics',
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final data = snapshot.data!;
        final stats = [
          _AnalyticsStat(
            'Taux d\'occupation',
            '${(data.occupation * 100).toStringAsFixed(1)}%',
            Colors.greenAccent,
          ),
          _AnalyticsStat('ADR', money.format(data.adr), Colors.blueAccent),
          _AnalyticsStat(
            'RevPAR',
            money.format(data.revpar),
            Colors.purpleAccent,
          ),
          _AnalyticsStat('No-show', '${data.noShows}', Colors.orangeAccent),
        ];
        final alerts = [
          'Arrivées du jour non check-in : ${data.arrivalsPending}',
          'Départs du jour non check-out : ${data.departuresPending}',
          'Chambres en maintenance : ${data.roomsMaintenance}',
        ];

        return _AnalyticsScaffold(
          title: 'Analytics',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _StatRow(stats: stats),
              const SizedBox(height: 16),
              _CardBlock(
                title: 'Alertes prioritaire',
                child: Column(
                  children: alerts
                      .map(
                        (a) => ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(
                            Icons.warning_amber_rounded,
                            color: Colors.orangeAccent,
                          ),
                          title: Text(
                            a,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
              const SizedBox(height: 16),
              _CardBlock(
                title: 'Top canaux de réservation',
                child: Column(
                  children: data.topSources
                      .map(
                        (s) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  s.label,
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                              Container(
                                width: 160,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: FractionallySizedBox(
                                  alignment: Alignment.centerLeft,
                                  widthFactor: s.percent / 100,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.blueAccent,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                '${s.percent.toStringAsFixed(0)}%',
                                style: const TextStyle(color: Colors.white70),
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class ReportingScreen extends StatelessWidget {
  const ReportingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final money = NumberFormat.currency(
      locale: 'fr_FR',
      symbol: 'FCFA',
      decimalDigits: 0,
    );
    return FutureBuilder<_AnalyticsData>(
      future: _loadAnalytics(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const _AnalyticsScaffold(
            title: 'Reporting',
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final data = snapshot.data!;
        final kpis = [
          _AnalyticsStat(
            'CA du mois',
            money.format(data.totalAmount),
            Colors.greenAccent,
          ),
          _AnalyticsStat('ADR', money.format(data.adr), Colors.blueAccent),
          _AnalyticsStat(
            'RevPAR',
            money.format(data.revpar),
            Colors.purpleAccent,
          ),
          _AnalyticsStat(
            'Annulations',
            '${data.cancellations}',
            Colors.redAccent,
          ),
        ];
        final rows = [
          {
            'label': 'Revenus hébergement',
            'value': money.format(data.totalAmount),
          },
          {
            'label': 'Dépôts encaissés',
            'value': money.format(data.totalDeposits),
          },
          {
            'label': 'Impayés estimés',
            'value': money.format(data.totalAmount - data.totalDeposits),
          },
        ];

        return _AnalyticsScaffold(
          title: 'Reporting',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _StatRow(stats: kpis),
              const SizedBox(height: 16),
              _CardBlock(
                title: 'Synthèse financière',
                child: Column(
                  children: rows
                      .map(
                        (r) => ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            r['label'] as String,
                            style: const TextStyle(color: Colors.white),
                          ),
                          trailing: Text(
                            r['value'] as String,
                            style: const TextStyle(
                              color: Colors.greenAccent,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
              const SizedBox(height: 16),
              _CardBlock(
                title: 'Rapports rapides',
                child: Column(
                  children: const [
                    _ReportTile(label: 'Arrivées/Départs du jour'),
                    _ReportTile(label: 'Chambres hors service'),
                    _ReportTile(label: 'Impayés & relances'),
                    _ReportTile(label: 'Performance par canal'),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AnalyticsScaffold extends StatelessWidget {
  const _AnalyticsScaffold({required this.title, required this.child});

  final String title;
  final Widget child;

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
                        colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.stacked_bar_chart_rounded,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(child: child),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({required this.stats});

  final List<_AnalyticsStat> stats;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: stats
          .map(
            (s) => Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 6),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.03),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.label,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      s.value,
                      style: TextStyle(
                        color: s.color,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
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

class _AnalyticsStat {
  _AnalyticsStat(this.label, this.value, this.color);
  final String label;
  final String value;
  final Color color;
}

class _ChannelStat {
  final String label;
  final double percent;
  _ChannelStat(this.label, this.percent);
}

class _AnalyticsData {
  final double occupation;
  final double adr;
  final double revpar;
  final double totalAmount;
  final double totalDeposits;
  final int noShows;
  final int cancellations;
  final int arrivalsPending;
  final int departuresPending;
  final int roomsMaintenance;
  final List<_ChannelStat> topSources;

  _AnalyticsData({
    required this.occupation,
    required this.adr,
    required this.revpar,
    required this.totalAmount,
    required this.totalDeposits,
    required this.noShows,
    required this.cancellations,
    required this.arrivalsPending,
    required this.departuresPending,
    required this.roomsMaintenance,
    required this.topSources,
  });
}

Future<_AnalyticsData> _loadAnalytics() async {
  final db = LocalDatabase.instance;
  final reservations = await db.fetchReservations();
  final statusMap = await db.fetchStatusOverview();
  final totalRooms = statusMap.values.fold<int>(0, (a, b) => a + b);
  final occupied = (statusMap['occupied'] ?? 0);
  final maintenanceCount = statusMap['maintenance'] ?? 0;
  final occupation = totalRooms == 0 ? 0.0 : (occupied / totalRooms.toDouble());

  double totalAmount = 0;
  double totalDeposit = 0;
  int noShow = 0;
  int cancelled = 0;
  int arrivalsToday = 0;
  int departuresToday = 0;
  final now = DateTime.now();

  final sourceCount = <String, int>{};

  for (final r in reservations) {
    final amount = (r['amount'] as num?)?.toDouble() ?? 0.0;
    final deposit = (r['deposit'] as num?)?.toDouble() ?? 0.0;
    totalAmount += amount;
    totalDeposit += deposit;
    final status = (r['status'] as String? ?? '').toLowerCase();
    if (status.contains('no_show')) noShow++;
    if (status.contains('cancel')) cancelled++;

    final source = (r['reservationSource'] as String? ?? 'Inconnu').trim();
    sourceCount[source] = (sourceCount[source] ?? 0) + 1;

    final checkIn = DateTime.tryParse(r['checkIn'] as String? ?? '');
    final checkOut = DateTime.tryParse(r['checkOut'] as String? ?? '');
    if (checkIn != null &&
        checkIn.year == now.year &&
        checkIn.month == now.month &&
        checkIn.day == now.day &&
        status.toLowerCase() != 'checked_in') {
      arrivalsToday++;
    }
    if (checkOut != null &&
        checkOut.year == now.year &&
        checkOut.month == now.month &&
        checkOut.day == now.day &&
        status.toLowerCase() != 'checked_out') {
      departuresToday++;
    }
  }

  final adr = reservations.isEmpty ? 0.0 : totalAmount / reservations.length;
  final revpar = totalRooms == 0 ? 0.0 : adr * occupation;

  final totalSource = sourceCount.values.fold<int>(0, (a, b) => a + b);
  final topSources =
      sourceCount.entries
          .map(
            (e) => _ChannelStat(
              e.key,
              totalSource == 0 ? 0 : (e.value * 100 / totalSource),
            ),
          )
          .toList()
        ..sort((a, b) => b.percent.compareTo(a.percent));

  return _AnalyticsData(
    occupation: occupation,
    adr: adr,
    revpar: revpar,
    totalAmount: totalAmount,
    totalDeposits: totalDeposit,
    noShows: noShow,
    cancellations: cancelled,
    arrivalsPending: arrivalsToday,
    departuresPending: departuresToday,
    roomsMaintenance: maintenanceCount,
    topSources: topSources.take(5).toList(),
  );
}

class _CardBlock extends StatelessWidget {
  const _CardBlock({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _ReportTile extends StatelessWidget {
  const _ReportTile({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: const Icon(
        Icons.picture_as_pdf_rounded,
        color: Colors.blueAccent,
      ),
      title: Text(label, style: const TextStyle(color: Colors.white)),
      trailing: const Icon(Icons.chevron_right, color: Colors.white70),
    );
  }
}

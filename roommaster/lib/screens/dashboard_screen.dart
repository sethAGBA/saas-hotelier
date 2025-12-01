import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/local_database.dart';
import '../widgets/futuristic_app_bar.dart';
import '../widgets/futuristic_room_status_chip.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Future<_DashboardData> _dataFuture;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    _dataFuture = _loadDashboard();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<_DashboardData> _loadDashboard() async {
    final db = LocalDatabase.instance;
    final reservations = await db.fetchReservations();
    final statusMap = await db.fetchStatusOverview();
    final totalRooms = statusMap.values.fold<int>(0, (a, b) => a + b);
    final occupied = (statusMap['occupied'] ?? 0);
    final occupation = totalRooms == 0
        ? 0.0
        : (occupied / totalRooms.toDouble());

    double totalAmount = 0;
    double totalDeposit = 0;
    double maxAmount = 0;
    int noShows = 0;
    final activities = <_ActivityItem>[];
    final now = DateTime.now();

    for (final r in reservations) {
      final amount = (r['amount'] as num?)?.toDouble() ?? 0.0;
      final deposit = (r['deposit'] as num?)?.toDouble() ?? 0.0;
      totalAmount += amount;
      totalDeposit += deposit;
      if (amount > maxAmount) maxAmount = amount;
      final status = (r['status'] as String? ?? '').toLowerCase();
      if (status == 'cancelled' || status == 'no_show') noShows++;

      // Activity feed: show last 6 items based on checkIn
      final checkIn = DateTime.tryParse(r['checkIn'] as String? ?? '');
      if (checkIn != null &&
          activities.length < 6 &&
          checkIn.isAfter(now.subtract(const Duration(days: 3)))) {
        final guest = r['guestName'] as String? ?? 'Invité';
        final room = r['roomNumber'] as String? ?? '';
        final icon = status == 'cancelled'
            ? Icons.cancel_rounded
            : Icons.login_rounded;
        final color = status == 'cancelled'
            ? Colors.redAccent
            : Colors.greenAccent;
        activities.add(
          _ActivityItem(
            icon: icon,
            title: status == 'cancelled' ? 'Annulation' : 'Check-in prévu',
            subtitle: '$guest - Chambre $room',
            time: DateFormat('dd/MM HH:mm').format(checkIn),
            color: color,
          ),
        );
      }
    }

    final double avgRevenue = reservations.isEmpty
        ? 0.0
        : totalAmount / reservations.length;

    return _DashboardData(
      occupation: occupation,
      avgRevenue: avgRevenue,
      maxRevenue: maxAmount,
      totalDeposits: totalDeposit,
      totalAmount: totalAmount,
      noShows: noShows,
      totalReservations: reservations.length,
      activities: activities,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [const Color(0xFF0F0F1E), const Color(0xFF1A1A2E)],
        ),
      ),
      child: Column(
        children: [
          buildFuturisticAppBar(context),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FutureBuilder<_DashboardData>(
                    future: _dataFuture,
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }
                      final data = snapshot.data!;
                      return LayoutBuilder(
                        builder: (context, constraints) {
                          final width = constraints.maxWidth;
                          const spacing = 24.0;
                          int columns = 4;

                          if (width >= 1200) {
                            columns = 4;
                          } else if (width >= 900) {
                            columns = 3;
                          } else if (width >= 600) {
                            columns = 2;
                          } else {
                            columns = 1;
                          }

                          final tileWidth =
                              (width - spacing * (columns - 1)) / columns;
                          const desiredTileHeight = 170.0;
                          final aspect = (tileWidth / desiredTileHeight).clamp(
                            1.0,
                            3.0,
                          );

                          return GridView(
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: columns,
                                  crossAxisSpacing: spacing,
                                  mainAxisSpacing: spacing,
                                  childAspectRatio: aspect,
                                ),
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            children: [
                              _FuturisticStatCard(
                                title: 'Taux d\'occupation',
                                value:
                                    '${(data.occupation * 100).toStringAsFixed(0)}%',
                                subtitle: 'Chambres occupées',
                                icon: Icons.hotel_rounded,
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF6C63FF),
                                    Color(0xFF5A52D5),
                                  ],
                                ),
                                percentage: data.occupation.clamp(0, 1),
                              ),
                              _FuturisticStatCard(
                                title: 'Revenu moyen',
                                value: NumberFormat.currency(
                                  locale: 'fr_FR',
                                  symbol: 'FCFA',
                                  decimalDigits: 0,
                                ).format(data.avgRevenue),
                                subtitle: 'par réservation',
                                icon: Icons.payments_rounded,
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF4facfe),
                                    Color(0xFF00f2fe),
                                  ],
                                ),
                                percentage:
                                    (data.avgRevenue > 0 && data.maxRevenue > 0)
                                    ? (data.avgRevenue / data.maxRevenue).clamp(
                                        0,
                                        1,
                                      )
                                    : 0,
                              ),
                              _FuturisticStatCard(
                                title: 'Encaissements',
                                value: NumberFormat.currency(
                                  locale: 'fr_FR',
                                  symbol: 'FCFA',
                                  decimalDigits: 0,
                                ).format(data.totalDeposits),
                                subtitle: 'dépôts reçus',
                                icon: Icons.account_balance_wallet_rounded,
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF43e97b),
                                    Color(0xFF38f9d7),
                                  ],
                                ),
                                percentage: (data.totalAmount > 0)
                                    ? (data.totalDeposits / data.totalAmount)
                                          .clamp(0, 1)
                                    : 0,
                              ),
                              _FuturisticStatCard(
                                title: 'No-shows / Annulées',
                                value: '${data.noShows}',
                                subtitle: 'Réservations',
                                icon: Icons.cancel_rounded,
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFFf093fb),
                                    Color(0xFFf5576c),
                                  ],
                                ),
                                percentage: data.totalReservations > 0
                                    ? (data.noShows / data.totalReservations)
                                          .clamp(0, 1)
                                    : 0,
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 32),
                  _buildRoomSynoptic(),
                  const SizedBox(height: 32),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 2,
                        child: FutureBuilder<_DashboardData>(
                          future: _dataFuture,
                          builder: (context, snapshot) {
                            final items = snapshot.data?.activities ?? [];
                            return _buildActivityFeed(items);
                          },
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(child: _buildQuickActions()),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoomSynoptic() {
    return FutureBuilder<Map<String, int>>(
      future: LocalDatabase.instance.fetchStatusOverview(),
      builder: (context, snapshot) {
        final counts = snapshot.data ?? {};

        Widget buildChips() {
          final tiles = [
            {
              'label': 'Disponibles',
              'value': counts['available'] ?? 0,
              'color': Colors.green,
            },
            {
              'label': 'Occupées',
              'value': counts['occupied'] ?? 0,
              'color': Colors.red,
            },
            {
              'label': 'Sales',
              'value': counts['dirty'] ?? 0,
              'color': Colors.orange,
            },
            {
              'label': 'Nettoyage',
              'value': counts['cleaning'] ?? 0,
              'color': Colors.blue,
            },
            {
              'label': 'Maintenance',
              'value': counts['maintenance'] ?? 0,
              'color': Colors.grey,
            },
            {
              'label': 'Réservées',
              'value': counts['reserved'] ?? 0,
              'color': Colors.purple,
            },
            {
              'label': 'Annulées',
              'value': counts['cancelled'] ?? 0,
              'color': Colors.pinkAccent,
            },
          ];

          return Wrap(
            spacing: 16,
            runSpacing: 16,
            children: tiles
                .map(
                  (tile) => FuturisticRoomStatusChip(
                    tile['label'] as String,
                    tile['value'] as int,
                    tile['color'] as Color,
                  ),
                )
                .toList(),
          );
        }

        return Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF1A1A2E).withOpacity(0.6),
                const Color(0xFF16213E).withOpacity(0.6),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFF6C63FF).withOpacity(0.2)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6C63FF).withOpacity(0.1),
                blurRadius: 30,
                spreadRadius: 0,
              ),
            ],
          ),
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
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF667eea).withOpacity(0.4),
                          blurRadius: 15,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.hotel_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Synoptique Chambres',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              buildChips(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActivityFeed(List<_ActivityItem> items) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1A1A2E).withOpacity(0.7),
            const Color(0xFF16213E).withOpacity(0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF6C63FF).withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6C63FF).withOpacity(0.08),
            blurRadius: 24,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF43e97b), Color(0xFF38f9d7)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF43e97b).withOpacity(0.4),
                      blurRadius: 15,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.dynamic_feed_rounded,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Activités récentes',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (items.isEmpty)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text(
                'Aucune activité récente.',
                style: TextStyle(color: Colors.white70),
              ),
            )
          else
            ...items.map(
              (item) => _ActivityItem(
                icon: item.icon,
                title: item.title,
                subtitle: item.subtitle,
                time: item.time,
                color: item.color,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1A1A2E).withOpacity(0.7),
            const Color(0xFF16213E).withOpacity(0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF6C63FF).withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6C63FF).withOpacity(0.08),
            blurRadius: 24,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFfa709a), Color(0xFFfee140)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.flash_on_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              const Text(
                'ACTIONS RAPIDES',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const _QuickActionButton(
            icon: Icons.add_circle_rounded,
            label: 'Nouvelle Réservation',
            gradient: LinearGradient(
              colors: [Color(0xFF43e97b), Color(0xFF38f9d7)],
            ),
          ),
          const SizedBox(height: 12),
          const _QuickActionButton(
            icon: Icons.login_rounded,
            label: 'Check-In Rapide',
            gradient: LinearGradient(
              colors: [Color(0xFF667eea), Color(0xFF764ba2)],
            ),
          ),
          const SizedBox(height: 12),
          const _QuickActionButton(
            icon: Icons.receipt_long_rounded,
            label: 'Nouvelle Facture',
            gradient: LinearGradient(
              colors: [Color(0xFF4facfe), Color(0xFF00f2fe)],
            ),
          ),
          const SizedBox(height: 12),
          const _QuickActionButton(
            icon: Icons.print_rounded,
            label: 'Rapport Journalier',
            gradient: LinearGradient(
              colors: [Color(0xFFf77062), Color(0xFFfe5196)],
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardData {
  final double occupation;
  final double avgRevenue;
  final double maxRevenue;
  final double totalDeposits;
  final double totalAmount;
  final int noShows;
  final int totalReservations;
  final List<_ActivityItem> activities;

  _DashboardData({
    required this.occupation,
    required this.avgRevenue,
    required this.maxRevenue,
    required this.totalDeposits,
    required this.totalAmount,
    required this.noShows,
    required this.totalReservations,
    required this.activities,
  });
}

class _QuickActionButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final Gradient gradient;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.gradient,
  });

  @override
  State<_QuickActionButton> createState() => _QuickActionButtonState();
}

class _QuickActionButtonState extends State<_QuickActionButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: _isHovered
              ? widget.gradient
              : LinearGradient(
                  colors: [
                    widget.gradient.colors.first.withOpacity(0.2),
                    widget.gradient.colors.last.withOpacity(0.2),
                  ],
                ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: widget.gradient.colors.first.withOpacity(0.5),
          ),
          boxShadow: _isHovered
              ? [
                  BoxShadow(
                    color: widget.gradient.colors.first.withOpacity(0.4),
                    blurRadius: 20,
                    spreadRadius: 0,
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Icon(widget.icon, color: Colors.white, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                widget.label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_rounded,
              color: Colors.white.withOpacity(0.7),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class _FuturisticStatCard extends StatefulWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Gradient gradient;
  final double percentage;

  const _FuturisticStatCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.gradient,
    required this.percentage,
  });

  @override
  State<_FuturisticStatCard> createState() => _FuturisticStatCardState();
}

class _FuturisticStatCardState extends State<_FuturisticStatCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _controller.forward(),
      onExit: (_) => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF1A1A2E).withOpacity(0.8),
                    const Color(0xFF16213E).withOpacity(0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: widget.gradient.colors.first.withOpacity(0.5),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: widget.gradient.colors.first.withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: widget.gradient,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: widget.gradient.colors.first.withOpacity(
                                0.5,
                              ),
                              blurRadius: 12,
                              spreadRadius: 0,
                            ),
                          ],
                        ),
                        child: Icon(widget.icon, color: Colors.white, size: 20),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: widget.gradient.colors.first.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          '+12%',
                          style: TextStyle(
                            color: widget.gradient.colors.first,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.title,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.value,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.subtitle,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: widget.percentage,
                      backgroundColor: Colors.white.withOpacity(0.1),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        widget.gradient.colors.first,
                      ),
                      minHeight: 3,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ActivityItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String time;
  final Color color;

  const _ActivityItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.time,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E).withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withOpacity(0.5)),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            time,
            style: TextStyle(
              color: Colors.white.withOpacity(0.4),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

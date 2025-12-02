import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class TimeTrackingAttendanceScreen extends StatefulWidget {
  final Animation<double> fadeAnimation;
  final Gradient gradient;

  const TimeTrackingAttendanceScreen({
    super.key,
    required this.fadeAnimation,
    required this.gradient,
  });

  @override
  State<TimeTrackingAttendanceScreen> createState() => _TimeTrackingAttendanceScreenState();
}

class _TimeTrackingAttendanceScreenState extends State<TimeTrackingAttendanceScreen>
    with TickerProviderStateMixin {
  late AnimationController _cardAnimationController;
  late AnimationController _clockAnimationController;
  late Animation<double> _cardAnimation;
  late Animation<double> _clockAnimation;
  
  String _selectedView = 'today'; // 'today', 'week', 'employees', 'reports'
  String _selectedFilter = 'all'; // 'all', 'present', 'absent', 'late'
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  bool _isClockedIn = false;
  DateTime? _clockInTime;
  Duration _workedTime = Duration.zero;

  @override
  void initState() {
    super.initState();
    _cardAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _clockAnimationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
    
    _cardAnimation = CurvedAnimation(
      parent: _cardAnimationController,
      curve: Curves.elasticOut,
    );
    _clockAnimation = CurvedAnimation(
      parent: _clockAnimationController,
      curve: Curves.linear,
    );
    
    _cardAnimationController.forward();
    
    // Simuler un temps de travail
    _workedTime = const Duration(hours: 7, minutes: 32);
  }

  @override
  void dispose() {
    _cardAnimationController.dispose();
    _clockAnimationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: widget.fadeAnimation,
      child: Container(
        color: const Color(0xFF0F172A),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Column(
            children: [
              _buildHeader(),
              _buildQuickActions(),
              _buildViewSelector(),
              if (_selectedView == 'employees') _buildSearchAndFilter(),
              Expanded(child: _buildContent()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(35),
          bottomRight: Radius.circular(35),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  gradient: widget.gradient,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.fingerprint,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(width: 20),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pointage & Présences',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'Suivi du temps & Assiduité',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              _buildCurrentTime(),
            ],
          ),
          const SizedBox(height: 20),
          _buildTodayStats(),
        ],
      ),
    );
  }

  Widget _buildCurrentTime() {
    return AnimatedBuilder(
      animation: _clockAnimation,
      builder: (context, child) {
        final now = DateTime.now();
        return Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.blue.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              Icon(
                Icons.access_time,
                color: Colors.blue,
                size: 24,
              ),
              const SizedBox(height: 5),
              Text(
                '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              Text(
                'Maintenant',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.blue.withOpacity(0.8),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTodayStats() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Temps Travaillé',
            '${_workedTime.inHours}h ${_workedTime.inMinutes.remainder(60)}m',
            Icons.schedule,
            Colors.green,
            '+15m',
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: _buildStatCard(
            'Présents',
            '${_getPresentEmployees()}/${_getAllEmployees()}',
            Icons.group,
            Colors.blue,
            '+2',
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: _buildStatCard(
            'Retards',
            '${_getLateEmployees()}',
            Icons.schedule_outlined,
            Colors.orange,
            '=',
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, String change) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 20),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: change == '=' ? Colors.grey : (change.startsWith('+') ? Colors.green : Colors.red),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  change,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: color.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
      child: Row(
        children: [
          Expanded(
            child: _buildClockButton(),
          ),
          const SizedBox(width: 15),
          _buildActionButton(Icons.pause, 'Pause', Colors.orange, _takePause),
          const SizedBox(width: 15),
          _buildActionButton(Icons.event_note, 'Rapport', Colors.purple, _generateReport),
        ],
      ),
    );
  }

  Widget _buildClockButton() {
    return GestureDetector(
      onTap: _toggleClock,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          gradient: _isClockedIn ? 
            LinearGradient(colors: [Colors.red[400]!, Colors.red[600]!]) : 
            widget.gradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _isClockedIn ? Icons.logout : Icons.login,
              color: Colors.white,
              size: 28,
            ),
            const SizedBox(width: 10),
            Text(
              _isClockedIn ? 'Pointer Sortie' : 'Pointer Entrée',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 5),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildViewSelector() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildViewButton('today', Icons.today, 'Aujourd\'hui'),
          _buildViewButton('week', Icons.view_week, 'Semaine'),
          _buildViewButton('employees', Icons.group, 'Employés'),
          _buildViewButton('reports', Icons.assessment, 'Rapports'),
        ],
      ),
    );
  }

  Widget _buildViewButton(String view, IconData icon, String label) {
    final bool isSelected = _selectedView == view;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedView = view),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            gradient: isSelected ? widget.gradient : null,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : Colors.white70,
                size: 16,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white70,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 10,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Rechercher un employé...',
                  hintStyle: TextStyle(color: Colors.white54),
                  prefixIcon: Icon(Icons.search, color: Colors.white54),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(15)),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Color(0xFF1E293B),
                ),
                onChanged: (value) => setState(() => _searchQuery = value),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedFilter,
                onChanged: (value) => setState(() => _selectedFilter = value!),
                style: const TextStyle(color: Colors.white),
                dropdownColor: const Color(0xFF1E293B),
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('Tous')),
                  DropdownMenuItem(value: 'present', child: Text('Présents')),
                  DropdownMenuItem(value: 'absent', child: Text('Absents')),
                  DropdownMenuItem(value: 'late', child: Text('Retards')),
                ],
                icon: const Icon(Icons.filter_list, color: Colors.white70),
                borderRadius: BorderRadius.circular(15),
                padding: const EdgeInsets.symmetric(horizontal: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    switch (_selectedView) {
      case 'week':
        return _buildWeekView();
      case 'employees':
        return _buildEmployeesView();
      case 'reports':
        return _buildReportsView();
      default:
        return _buildTodayView();
    }
  }

  Widget _buildTodayView() {
    return AnimatedBuilder(
      animation: _cardAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _cardAnimation.value,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(25),
            child: Column(
              children: [
                _buildMyTimeCard(),
                const SizedBox(height: 20),
                _buildTodayActivity(),
                const SizedBox(height: 20),
                _buildTeamStatus(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMyTimeCard() {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  gradient: widget.gradient,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.person,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 15),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mon Temps Aujourd\'hui',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Suivi personnel',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _isClockedIn ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _isClockedIn ? Colors.green.withOpacity(0.3) : Colors.grey.withOpacity(0.3),
                  ),
                ),
                child: Text(
                  _isClockedIn ? 'Actif' : 'Inactif',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: _isClockedIn ? Colors.green : Colors.grey,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildTimeMetric(
                  'Arrivée',
                  _clockInTime != null ? 
                    '${_clockInTime!.hour.toString().padLeft(2, '0')}:${_clockInTime!.minute.toString().padLeft(2, '0')}' : 
                    '--:--',
                  Icons.login,
                  Colors.blue,
                ),
              ),
              Expanded(
                child: _buildTimeMetric(
                  'Départ',
                  '--:--',
                  Icons.logout,
                  Colors.orange,
                ),
              ),
              Expanded(
                child: _buildTimeMetric(
                  'Pause',
                  '30m',
                  Icons.pause,
                  Colors.purple,
                ),
              ),
              Expanded(
                child: _buildTimeMetric(
                  'Total',
                  '${_workedTime.inHours}h${_workedTime.inMinutes.remainder(60)}m',
                  Icons.schedule,
                  Colors.green,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimeMetric(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(15),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: color.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodayActivity() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Activité d\'Aujourd\'hui',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 15),
          ...(_getTodayActivities().map((activity) => _buildActivityItem(activity))),
        ],
      ),
    );
  }

  Widget _buildActivityItem(Map<String, dynamic> activity) {
    final color = _getActivityColor(activity['type']);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFF334155),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getActivityIcon(activity['type']),
              color: Colors.white,
              size: 16,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity['description'],
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                Text(
                  activity['time'],
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamStatus() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Statut de l\'Équipe',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              _buildTeamStatCard('Présents', '${_getPresentEmployees()}', Colors.green, Icons.check_circle),
              const SizedBox(width: 10),
              _buildTeamStatCard('Absents', '${_getAbsentEmployees()}', Colors.red, Icons.cancel),
              const SizedBox(width: 10),
              _buildTeamStatCard('Retards', '${_getLateEmployees()}', Colors.orange, Icons.schedule),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTeamStatCard(String label, String value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: color.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeekView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(25),
      child: Column(
        children: [
          _buildWeeklyChart(),
          const SizedBox(height: 20),
          _buildWeeklyStats(),
        ],
      ),
    );
  }

  Widget _buildWeeklyChart() {
    return Container(
      height: 300,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Temps de Travail Hebdomadaire',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 10,
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        const days = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
                        return Text(
                          days[value.toInt()],
                          style: const TextStyle(fontSize: 12, color: Colors.white70),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        return Text('${value.toInt()}h', style: const TextStyle(color: Colors.white70));
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                barGroups: [
                  BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: 8.5, color: Colors.blue)]),
                  BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: 8.0, color: Colors.blue)]),
                  BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: 7.5, color: Colors.blue)]),
                  BarChartGroupData(x: 3, barRods: [BarChartRodData(toY: 8.2, color: Colors.blue)]),
                  BarChartGroupData(x: 4, barRods: [BarChartRodData(toY: 7.8, color: Colors.blue)]),
                  BarChartGroupData(x: 5, barRods: [BarChartRodData(toY: 0, color: Colors.grey)]),
                  BarChartGroupData(x: 6, barRods: [BarChartRodData(toY: 0, color: Colors.grey)]),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyStats() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Statistiques de la Semaine',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(child: _buildWeekStatMetric('Total', '40h', Colors.blue)),
              Expanded(child: _buildWeekStatMetric('Moyenne/jour', '8h', Colors.green)),
              Expanded(child: _buildWeekStatMetric('Heures sup', '2h', Colors.orange)),
              Expanded(child: _buildWeekStatMetric('Congés', '5j', Colors.purple)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeekStatMetric(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: color.withOpacity(0.8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmployeesView() {
    final employees = _getFilteredEmployees();
    return ListView.builder(
      padding: const EdgeInsets.all(25),
      itemCount: employees.length,
      itemBuilder: (context, index) {
        return _buildEmployeeCard(employees[index]);
      },
    );
  }

  Widget _buildEmployeeCard(Map<String, dynamic> employee) {
    final statusColor = _getEmployeeStatusColor(employee['status']);
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              gradient: widget.gradient,
              borderRadius: BorderRadius.circular(25),
            ),
            child: Center(
              child: Text(
                employee['name'].substring(0, 1).toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  employee['name'],
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  employee['department'],
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white70,
                  ),
                ),
                if (employee['clockIn'] != null)
                  Text(
                    'Arrivé à ${employee['clockIn']}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.green,
                    ),
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: statusColor.withOpacity(0.3)),
                ),
                child: Text(
                  employee['status'],
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ),
              if (employee['workTime'] != null)
                Padding(
                  padding: const EdgeInsets.only(top: 5),
                  child: Text(
                    '${employee['workTime']}h',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReportsView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(25),
      child: Column(
        children: [
          _buildReportCard(
            'Rapport Mensuel',
            'Analyse complète du mois',
            Icons.calendar_month,
            Colors.blue,
            _generateMonthlyReport,
          ),
          const SizedBox(height: 15),
          _buildReportCard(
            'Rapport des Retards',
            'Suivi des retards de l\'équipe',
            Icons.schedule_outlined,
            Colors.orange,
            _generateLateReport,
          ),
          const SizedBox(height: 15),
          _buildReportCard(
            'Rapport des Absences',
            'Analyse des absences',
            Icons.event_busy,
            Colors.red,
            _generateAbsenceReport,
          ),
          const SizedBox(height: 15),
          _buildReportCard(
            'Heures Supplémentaires',
            'Suivi des heures sup',
            Icons.access_time_filled,
            Colors.purple,
            _generateOvertimeReport,
          ),
        ],
      ),
    );
  }

  Widget _buildReportCard(String title, String description, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(icon, color: color, size: 30),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.white.withOpacity(0.5),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  // Méthodes utilitaires et logique métier
  void _toggleClock() {
    setState(() {
      _isClockedIn = !_isClockedIn;
      if (_isClockedIn) {
        _clockInTime = DateTime.now();
      } else {
        _clockInTime = null;
        _workedTime = const Duration(hours: 8, minutes: 15);
      }
    });
  }

  void _takePause() {
    // Logique pour la pause
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Pause démarrée')),
    );
  }

  void _generateReport() {
    // Logique pour générer un rapport
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Génération du rapport...')),
    );
  }

  void _generateMonthlyReport() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Génération du rapport mensuel...')),
    );
  }

  void _generateLateReport() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Génération du rapport des retards...')),
    );
  }

  void _generateAbsenceReport() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Génération du rapport des absences...')),
    );
  }

  void _generateOvertimeReport() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Génération du rapport des heures sup...')),
    );
  }

  int _getPresentEmployees() => 12;
  int _getAllEmployees() => 15;
  int _getAbsentEmployees() => 3;
  int _getLateEmployees() => 2;

  List<Map<String, dynamic>> _getTodayActivities() {
    return [
      {
        'type': 'clock_in',
        'description': 'Pointage d\'entrée',
        'time': '08:30',
      },
      {
        'type': 'break',
        'description': 'Pause déjeuner',
        'time': '12:15',
      },
      {
        'type': 'meeting',
        'description': 'Réunion équipe',
        'time': '14:00',
      },
    ];
  }

  Color _getActivityColor(String type) {
    switch (type) {
      case 'clock_in':
        return Colors.green;
      case 'clock_out':
        return Colors.red;
      case 'break':
        return Colors.orange;
      case 'meeting':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData _getActivityIcon(String type) {
    switch (type) {
      case 'clock_in':
        return Icons.login;
      case 'clock_out':
        return Icons.logout;
      case 'break':
        return Icons.pause;
      case 'meeting':
        return Icons.group;
      default:
        return Icons.event;
    }
  }

  List<Map<String, dynamic>> _getFilteredEmployees() {
    List<Map<String, dynamic>> employees = [
      {
        'name': 'Alice Dubois',
        'department': 'Développement',
        'status': 'Présent',
        'clockIn': '08:45',
        'workTime': 7.5,
      },
      {
        'name': 'Bob Martin',
        'department': 'Design',
        'status': 'Retard',
        'clockIn': '09:15',
        'workTime': 7.2,
      },
      {
        'name': 'Claire Laurent',
        'department': 'Marketing',
        'status': 'Absent',
        'clockIn': null,
        'workTime': 0,
      },
      {
        'name': 'David Rousseau',
        'department': 'Ventes',
        'status': 'Présent',
        'clockIn': '08:30',
        'workTime': 8.0,
      },
      {
        'name': 'Emma Moreau',
        'department': 'RH',
        'status': 'Présent',
        'clockIn': '08:00',
        'workTime': 8.3,
      },
    ];

    // Filtrer par recherche
    if (_searchQuery.isNotEmpty) {
      employees = employees
          .where((emp) => emp['name']
              .toString()
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()))
          .toList();
    }

    // Filtrer par statut
    if (_selectedFilter != 'all') {
      employees = employees
          .where((emp) => emp['status']
              .toString()
              .toLowerCase()
              .contains(_selectedFilter == 'present' ? 'présent' : 
                       _selectedFilter == 'absent' ? 'absent' : 'retard'))
          .toList();
    }

    return employees;
  }

  Color _getEmployeeStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'présent':
        return Colors.green;
      case 'absent':
        return Colors.red;
      case 'retard':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}
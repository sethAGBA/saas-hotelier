import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class LeaveManagementScreen extends StatefulWidget {
  final Animation<double> fadeAnimation;
  final Gradient gradient;

  const LeaveManagementScreen({
    super.key,
    required this.fadeAnimation,
    required this.gradient,
  });

  @override
  State<LeaveManagementScreen> createState() => _LeaveManagementScreenState();
}

class _LeaveManagementScreenState extends State<LeaveManagementScreen>
    with TickerProviderStateMixin {
  late AnimationController _cardAnimationController;
  late AnimationController _listAnimationController;
  late Animation<double> _cardAnimation;
  late Animation<double> _listAnimation;
  
  String _selectedView = 'requests'; // 'requests', 'calendar', 'analytics', 'balance'
  String _selectedFilter = 'all'; // 'all', 'pending', 'approved', 'rejected'
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cardAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _listAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _cardAnimation = CurvedAnimation(
      parent: _cardAnimationController,
      curve: Curves.elasticOut,
    );
    _listAnimation = CurvedAnimation(
      parent: _listAnimationController,
      curve: Curves.easeInOut,
    );
    
    _cardAnimationController.forward();
    _listAnimationController.forward();
  }

  @override
  void dispose() {
    _cardAnimationController.dispose();
    _listAnimationController.dispose();
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
              _buildViewSelector(),
              if (_selectedView == 'requests') _buildSearchAndFilter(),
              Expanded(child: _buildContent()),
            ],
          ),
          floatingActionButton: _buildFloatingActionButton(),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(35),
          bottomRight: Radius.circular(35),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
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
                  Icons.beach_access,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Gestion des Congés',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'Demandes & Planification',
                      style: TextStyle(
                        fontSize: 16,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              _buildQuickStats(),
            ],
          ),
          const SizedBox(height: 20),
          _buildSummaryCards(),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    return Row(
      children: [
        _buildStatCard('${_leaveRequests.length}', 'Demandes', Colors.blue, Icons.event_note),
        const SizedBox(width: 10),
        _buildStatCard('${_getPendingRequests()}', 'En attente', Colors.orange, Icons.hourglass_empty),
      ],
    );
  }

  Widget _buildStatCard(String value, String label, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 3),
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
              fontSize: 10,
              color: color.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            'Taux d\'Approbation',
            '${(((_getApprovedRequests()) / _leaveRequests.length) * 100).toInt()}%',
            Icons.check_circle,
            Colors.green,
            '+5%',
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: _buildSummaryCard(
            'Jours Pris',
            '${_getTotalDaysTaken()}',
            Icons.calendar_today,
            Colors.purple,
            '+12',
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: _buildSummaryCard(
            'Ce mois',
            '${_getCurrentMonthRequests()}',
            Icons.date_range,
            Colors.blue,
            '+3',
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color, String change) {
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
                  color: change.startsWith('+') ? Colors.green : Colors.red,
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

  Widget _buildViewSelector() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
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
          _buildViewButton('requests', Icons.list_alt, 'Demandes'),
          _buildViewButton('calendar', Icons.calendar_month, 'Calendrier'),
          _buildViewButton('balance', Icons.account_balance_wallet, 'Soldes'),
          _buildViewButton('analytics', Icons.analytics, 'Analytics'),
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
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          decoration: BoxDecoration(
            gradient: isSelected ? widget.gradient : null,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isSelected
                    ? Colors.white
                    : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: isSelected
                      ? Colors.white
                      : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 25),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
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
                decoration: InputDecoration(
                  hintText: 'Rechercher une demande...',
                  hintStyle: const TextStyle(color: Colors.white70),
                  prefixIcon: const Icon(Icons.search, color: Colors.white70),
                  border: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(15)),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Theme.of(context).cardColor,
                ),
                onChanged: (value) => setState(() => _searchQuery = value),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
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
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('Toutes')),
                  DropdownMenuItem(value: 'pending', child: Text('En attente')),
                  DropdownMenuItem(value: 'approved', child: Text('Approuvées')),
                  DropdownMenuItem(value: 'rejected', child: Text('Rejetées')),
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
      case 'calendar':
        return _buildCalendarView();
      case 'balance':
        return _buildBalanceView();
      case 'analytics':
        return _buildAnalyticsView();
      default:
        return _buildRequestsView();
    }
  }

  Widget _buildRequestsView() {
    final filteredRequests = _getFilteredRequests();
    
    return AnimatedBuilder(
      animation: _cardAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _cardAnimation.value,
          child: ListView.builder(
            padding: const EdgeInsets.all(25),
            itemCount: filteredRequests.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 15),
                child: _buildLeaveRequestCard(filteredRequests[index]),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildLeaveRequestCard(Map<String, dynamic> request) {
    final statusColor = _getStatusColor(request['status']);
    
    return GestureDetector(
      onTap: () => _showRequestDetails(request),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          _getLeaveTypeColor(request['type']),
                          _getLeaveTypeColor(request['type']).withOpacity(0.7),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Icon(
                      _getLeaveTypeIcon(request['type']),
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          request['employee'],
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          request['type'],
                          style: TextStyle(
                            fontSize: 14,
                            color: _getLeaveTypeColor(request['type']),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: statusColor.withOpacity(0.3)),
                    ),
                    child: Text(
                      request['status'],
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) => _handleRequestAction(value, request),
                    itemBuilder: (context) => [
                      if (request['status'] == 'En attente') ...[
                        const PopupMenuItem(value: 'approve', child: Text('Approuver')),
                        const PopupMenuItem(value: 'reject', child: Text('Rejeter')),
                      ],
                      const PopupMenuItem(value: 'details', child: Text('Détails')),
                      const PopupMenuItem(value: 'edit', child: Text('Modifier')),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 15),
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        _buildInfoChip('Du', request['startDate'], Colors.blue),
                        const SizedBox(width: 10),
                        _buildInfoChip('Au', request['endDate'], Colors.blue),
                        const SizedBox(width: 10),
                        _buildInfoChip('Durée', '${request['days']} jours', Colors.purple),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(Icons.description, size: 16, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            request['reason'] ?? 'Aucune raison spécifiée',
                            style: TextStyle(
                              fontSize: 13,
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.schedule, size: 16, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
                        const SizedBox(width: 5),
                        Text(
                          'Demandé le ${request['requestDate']}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 11,
              color: color.withOpacity(0.8),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarView() {
    return Container(
      padding: const EdgeInsets.all(25),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
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
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: widget.gradient,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.calendar_month, color: Colors.white),
                      SizedBox(width: 10),
                      Text(
                        'Calendrier des Congés - Septembre 2025',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    'Vue calendrier avec les congés planifiés à implémenter',
                    style: TextStyle(
                      fontSize: 16,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(25),
      child: Column(
        children: [
          _buildEmployeeBalanceCard('Jean Dupont', 25, 5, 8),
          const SizedBox(height: 15),
          _buildEmployeeBalanceCard('Marie Martin', 30, 12, 3),
          const SizedBox(height: 15),
          _buildEmployeeBalanceCard('Pierre Durand', 22, 8, 5),
          const SizedBox(height: 15),
          _buildEmployeeBalanceCard('Sophie Bernard', 28, 10, 2),
        ],
      ),
    );
  }

  Widget _buildEmployeeBalanceCard(String name, int total, int used, int pending) {
    final remaining = total - used;
    final usagePercentage = (used / total * 100).toInt();
    
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: widget.gradient,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: const Icon(
                    Icons.person,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Text(
                    name,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
                Text(
                  '$usagePercentage% utilisé',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: usagePercentage > 80 ? Colors.red : Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            Row(
              children: [
                Expanded(child: _buildBalanceMetric('Total', '$total', Colors.blue)),
                Expanded(child: _buildBalanceMetric('Utilisé', '$used', Colors.blue)),
                Expanded(child: _buildBalanceMetric('Restant', '$remaining', Colors.green)),
                Expanded(child: _buildBalanceMetric('En attente', '$pending', Colors.purple)),
              ],
            ),
            const SizedBox(height: 10),
            LinearProgressIndicator(
              value: used / total,
              backgroundColor: Theme.of(context).dividerColor.withOpacity(0.25),
              valueColor: AlwaysStoppedAnimation<Color>(
                usagePercentage > 80 ? Colors.red : Colors.green,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceMetric(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
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
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(25),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildLeaveTypesChart()),
              const SizedBox(width: 20),
              Expanded(child: _buildMonthlyTrends()),
            ],
          ),
          const SizedBox(height: 30),
          _buildDepartmentAnalysis(),
        ],
      ),
    );
  }

  Widget _buildLeaveTypesChart() {
    return Container(
      height: 250,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
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
          Text(
            'Types de Congés',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 50,
                sections: [
                  PieChartSectionData(
                    color: Colors.blue,
                    value: 45,
                    title: 'Vacances\n45%',
                    titleStyle: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  PieChartSectionData(
                    color: Colors.green,
                    value: 25,
                    title: 'RTT\n25%',
                    titleStyle: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  PieChartSectionData(
                    color: Colors.orange,
                    value: 20,
                    title: 'Maladie\n20%',
                    titleStyle: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  PieChartSectionData(
                    color: Colors.purple,
                    value: 10,
                    title: 'Autres\n10%',
                    titleStyle: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyTrends() {
    return Container(
      height: 250,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
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
          Text(
            'Tendances Mensuelles',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: true),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        const months = ['Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Jun'];
                        if (value.toInt() < months.length) {
                          return Text(months[value.toInt()], style: const TextStyle(fontSize: 10));
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        return Text('${value.toInt()}');
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: true),
                lineBarsData: [
                  LineChartBarData(
                    spots: const [
                      FlSpot(0, 15),
                      FlSpot(1, 18),
                      FlSpot(2, 12),
                      FlSpot(3, 22),
                      FlSpot(4, 19),
                      FlSpot(5, 25),
                    ],
                    isCurved: true,
                    color: Colors.blue,
                    barWidth: 3,
                    belowBarData: BarAreaData(
                      show: true,
                      color: Colors.blue.withOpacity(0.3),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDepartmentAnalysis() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
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
          Text(
            'Analyse par Département',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 20),
          _buildDepartmentRow('IT', 45, 12, 8),
          const SizedBox(height: 15),
          _buildDepartmentRow('RH', 35, 18, 5),
          const SizedBox(height: 15),
          _buildDepartmentRow('Marketing', 28, 15, 3),
          const SizedBox(height: 15),
          _buildDepartmentRow('Finance', 22, 8, 4),
        ],
      ),
    );
  }

  Widget _buildDepartmentRow(String department, int total, int used, int pending) {
    final remaining = total - used;
    final percentage = (used / total * 100).toInt();
    
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              department,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
          Expanded(
            child: _buildMetricColumn('Total', '$total', Colors.blue),
          ),
          Expanded(
            child: _buildMetricColumn('Utilisé', '$used', Colors.blue),
          ),
          Expanded(
            child: _buildMetricColumn('Restant', '$remaining', Colors.green),
          ),
          Expanded(
            child: _buildMetricColumn('En attente', '$pending', Colors.purple),
          ),
          Container(
            width: 60,
            height: 8,
            decoration: BoxDecoration(
              color: Theme.of(context).dividerColor.withOpacity(0.3),
              borderRadius: BorderRadius.circular(4),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: used / total,
              child: Container(
                decoration: BoxDecoration(
                  color: percentage > 80 ? Colors.red : Colors.green,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '$percentage%',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: percentage > 80 ? Colors.red : Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricColumn(String label, String value, Color color) {
    return Column(
      children: [
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
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton.extended(
      onPressed: _showNewRequestDialog,
      backgroundColor: Colors.transparent,
      elevation: 0,
      label: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          gradient: widget.gradient,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add, color: Colors.white),
            SizedBox(width: 8),
            Text(
              'Nouvelle Demande',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      icon: const SizedBox.shrink(), // No icon needed as it's part of the label
    );
  }

  // Méthodes utilitaires
  List<Map<String, dynamic>> _getFilteredRequests() {
    var requests = List<Map<String, dynamic>>.from(_leaveRequests);
    
    if (_selectedFilter != 'all') {
      requests = requests.where((r) => r['status'].toLowerCase().contains(_selectedFilter == 'pending' ? 'attente' : _selectedFilter)).toList();
    }
    
    if (_searchQuery.isNotEmpty) {
      requests = requests.where((r) => 
        r['employee'].toLowerCase().contains(_searchQuery.toLowerCase()) ||
        r['type'].toLowerCase().contains(_searchQuery.toLowerCase())
      ).toList();
    }
    
    return requests;
  }

  int _getPendingRequests() {
    return _leaveRequests.where((r) => r['status'] == 'En attente').length;
  }

  int _getApprovedRequests() {
    return _leaveRequests.where((r) => r['status'] == 'Approuvé').length;
  }

  int _getTotalDaysTaken() {
    return _leaveRequests
        .where((r) => r['status'] == 'Approuvé')
        .fold(0, (sum, r) => sum + (r['days'] as int));
  }

  int _getCurrentMonthRequests() {
    final now = DateTime.now();
    return _leaveRequests.where((r) {
      final requestDate = DateTime.tryParse(r['requestDate'].split('/').reversed.join('-'));
      return requestDate?.month == now.month && requestDate?.year == now.year;
    }).length;
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Approuvé':
        return Colors.green;
      case 'Rejeté':
        return Colors.red;
      case 'En attente':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  Color _getLeaveTypeColor(String type) {
    switch (type) {
      case 'Vacances':
        return Colors.blue;
      case 'Congé maladie':
        return Colors.red;
      case 'RTT':
        return Colors.green;
      case 'Congé parental':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  IconData _getLeaveTypeIcon(String type) {
    switch (type) {
      case 'Vacances':
        return Icons.beach_access;
      case 'Congé maladie':
        return Icons.local_hospital;
      case 'RTT':
        return Icons.schedule;
      case 'Congé parental':
        return Icons.family_restroom;
      default:
        return Icons.event;
    }
  }

  void _handleRequestAction(String action, Map<String, dynamic> request) {
    switch (action) {
      case 'approve':
        setState(() {
          request['status'] = 'Approuvé';
        });
        _showSnackBar('Demande approuvée', Colors.green);
        break;
      case 'reject':
        setState(() {
          request['status'] = 'Rejeté';
        });
        _showSnackBar('Demande rejetée', Colors.red);
        break;
      case 'details':
        _showRequestDetails(request);
        break;
      case 'edit':
        _showEditRequestDialog(request);
        break;
    }
  }

  void _showRequestDetails(Map<String, dynamic> request) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Détails de la demande'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Employé', request['employee']),
            _buildDetailRow('Type', request['type']),
            _buildDetailRow('Du', request['startDate']),
            _buildDetailRow('Au', request['endDate']),
            _buildDetailRow('Durée', '${request['days']} jours'),
            _buildDetailRow('Statut', request['status']),
            _buildDetailRow('Raison', request['reason'] ?? 'Non spécifiée'),
            _buildDetailRow('Demandé le', request['requestDate']),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  void _showNewRequestDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Nouvelle demande de congé'),
        content: const Text('Interface de création de demande à implémenter'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showSnackBar('Fonctionnalité à implémenter', Colors.blue);
            },
            child: const Text('Créer'),
          ),
        ],
      ),
    );
  }

  void _showEditRequestDialog(Map<String, dynamic> request) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Modifier la demande'),
        content: Text('Modification de la demande de ${request['employee']}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showSnackBar('Fonctionnalité à implémenter', Colors.blue);
            },
            child: const Text('Modifier'),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // Données d'exemple
  final List<Map<String, dynamic>> _leaveRequests = [
    {
      'employee': 'Jean Dupont',
      'type': 'Vacances',
      'startDate': '15/09/2025',
      'endDate': '22/09/2025',
      'days': 6,
      'status': 'En attente',
      'reason': 'Voyage familial prévu depuis longtemps',
      'requestDate': '01/09/2025',
    },
    {
      'employee': 'Marie Martin',
      'type': 'Congé maladie',
      'startDate': '10/09/2025',
      'endDate': '12/09/2025',
      'days': 3,
      'status': 'Approuvé',
      'reason': 'Grippe saisonnière',
      'requestDate': '09/09/2025',
    },
    {
      'employee': 'Pierre Durand',
      'type': 'RTT',
      'startDate': '20/09/2025',
      'endDate': '20/09/2025',
      'days': 1,
      'status': 'En attente',
      'reason': 'Rendez-vous médical',
      'requestDate': '05/09/2025',
    },
    {
      'employee': 'Sophie Bernard',
      'type': 'Congé parental',
      'startDate': '25/09/2025',
      'endDate': '29/09/2025',
      'days': 5,
      'status': 'Approuvé',
      'reason': 'Naissance de mon enfant',
      'requestDate': '15/08/2025',
    },
    {
      'employee': 'Lucas Moreau',
      'type': 'Vacances',
      'startDate': '05/10/2025',
      'endDate': '12/10/2025',
      'days': 6,
      'status': 'Rejeté',
      'reason': 'Période de forte activité',
      'requestDate': '28/08/2025',
    },
  ];
}

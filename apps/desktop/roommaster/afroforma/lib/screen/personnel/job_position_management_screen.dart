import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class JobPositionManagementScreen extends StatefulWidget {
  final Animation<double> fadeAnimation;
  final Gradient gradient;

  const JobPositionManagementScreen({
    super.key,
    required this.fadeAnimation,
    required this.gradient,
  });

  @override
  State<JobPositionManagementScreen> createState() => _JobPositionManagementScreenState();
}

class _JobPositionManagementScreenState extends State<JobPositionManagementScreen>
    with TickerProviderStateMixin {
  late AnimationController _cardAnimationController;
  late AnimationController _listAnimationController;
  late Animation<double> _cardAnimation;
  late Animation<double> _listAnimation;
  
  String _selectedView = 'positions'; // 'positions', 'hierarchy', 'analytics'
  String _selectedFilter = 'all'; // 'all', 'vacant', 'occupied', 'new'
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
              if (_selectedView == 'positions') _buildSearchAndFilter(),
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
                  Icons.work,
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
                      'Gestion des Postes',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'Organisation & Affectations',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
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
        _buildStatCard('${_positions.length}', 'Postes', Colors.blue, Icons.work_outline),
        const SizedBox(width: 10),
        _buildStatCard('${_getVacantPositions()}', 'Vacants', Colors.orange, Icons.person_add_alt),
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
            'Taux d\'Occupation',
            '${(((_positions.length - _getVacantPositions()) / _positions.length) * 100).toInt()}%',
            Icons.groups,
            Colors.green,
            '+3%',
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: _buildSummaryCard(
            'Postes Cadres',
            '${_positions.where((p) => p['level'] == 'Cadre').length}',
            Icons.trending_up,
            Colors.purple,
            '+2',
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: _buildSummaryCard(
            'Nouveau ce mois',
            '${_positions.where((p) => p['isNew'] == true).length}',
            Icons.fiber_new,
            Colors.blue,
            '+5',
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
          _buildViewButton('positions', Icons.work_outline, 'Postes'),
          _buildViewButton('hierarchy', Icons.account_tree, 'Hiérarchie'),
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
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            gradient: isSelected ? widget.gradient : null,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : Colors.white70,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white70,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 12,
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
                  hintText: 'Rechercher un poste...',
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
                  DropdownMenuItem(value: 'vacant', child: Text('Vacants')),
                  DropdownMenuItem(value: 'occupied', child: Text('Occupés')),
                  DropdownMenuItem(value: 'new', child: Text('Nouveaux')),
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
      case 'hierarchy':
        return _buildHierarchyView();
      case 'analytics':
        return _buildAnalyticsView();
      default:
        return _buildPositionsView();
    }
  }

  Widget _buildPositionsView() {
    final filteredPositions = _getFilteredPositions();
    
    return AnimatedBuilder(
      animation: _cardAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _cardAnimation.value,
          child: ListView.builder(
            padding: const EdgeInsets.all(25),
            itemCount: filteredPositions.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 15),
                child: _buildPositionCard(filteredPositions[index]),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildPositionCard(Map<String, dynamic> position) {
    final bool isVacant = position['assignedTo'] == null;
    
    return GestureDetector(
      onTap: () => _showPositionDetails(position),
      child: Container(
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
                          _getLevelColor(position['level']),
                          _getLevelColor(position['level']).withOpacity(0.7),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Icon(
                      _getPositionIcon(position['category']),
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                position['title'],
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            if (position['isNew'])
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  'NOUVEAU',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        Text(
                          position['department'],
                          style: TextStyle(
                            fontSize: 14,
                            color: _getLevelColor(position['level']),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, color: Colors.white70),
                    onSelected: (value) => _handlePositionAction(value, position),
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'edit', child: Text('Modifier')),
                      const PopupMenuItem(value: 'assign', child: Text('Assigner')),
                      const PopupMenuItem(value: 'duplicate', child: Text('Dupliquer')),
                      const PopupMenuItem(value: 'delete', child: Text('Supprimer')),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 15),
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        _buildInfoChip('Niveau', position['level'], _getLevelColor(position['level'])),
                        const SizedBox(width: 10),
                        _buildInfoChip('Salaire', '${position['salary']}K', Colors.green),
                        const SizedBox(width: 10),
                        _buildInfoChip(
                          'Statut', 
                          isVacant ? 'VACANT' : 'OCCUPÉ', 
                          isVacant ? Colors.orange : Colors.blue,
                        ),
                      ],
                    ),
                    if (!isVacant) ...[
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Icon(Icons.person, size: 16, color: Colors.white70),
                          const SizedBox(width: 5),
                          Text(
                            'Assigné à: ${position['assignedTo']}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(Icons.description, size: 16, color: Colors.white70),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            position['description'],
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white.withOpacity(0.8),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
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

  Widget _buildHierarchyView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(25),
      child: Column(
        children: [
          // Direction
          _buildHierarchyLevel('Direction', Colors.purple, [
            _positions.where((p) => p['level'] == 'Direction').toList(),
          ]),
          const SizedBox(height: 30),
          // Cadres
          _buildHierarchyLevel('Cadres', Colors.blue, [
            _positions.where((p) => p['level'] == 'Cadre').toList(),
          ]),
          const SizedBox(height: 30),
          // Employés
          _buildHierarchyLevel('Employés', Colors.green, [
            _positions.where((p) => p['level'] == 'Employé').toList(),
          ]),
        ],
      ),
    );
  }

  Widget _buildHierarchyLevel(String levelName, Color color, List<List<Map<String, dynamic>>> positionGroups) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [color, color.withOpacity(0.7)]),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            levelName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 15),
        Wrap(
          spacing: 15,
          runSpacing: 15,
          children: positionGroups.first.map((position) {
            return _buildHierarchyNode(position, color);
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildHierarchyNode(Map<String, dynamic> position, Color color) {
    final bool isVacant = position['assignedTo'] == null;
    
    return Container(
      width: 200,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            _getPositionIcon(position['category']),
            color: color,
            size: 32,
          ),
          const SizedBox(height: 10),
          Text(
            position['title'],
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 5),
          Text(
            position['department'],
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isVacant ? Colors.orange.withOpacity(0.1) : Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              isVacant ? 'VACANT' : position['assignedTo'],
              style: TextStyle(
                fontSize: 10,
                color: isVacant ? Colors.orange : Colors.green,
                fontWeight: FontWeight.bold,
              ),
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
              Expanded(child: _buildOccupancyChart()),
              const SizedBox(width: 20),
              Expanded(child: _buildLevelDistribution()),
            ],
          ),
          const SizedBox(height: 30),
          _buildDepartmentAnalysis(),
          const SizedBox(height: 30),
          _buildSalaryAnalysis(),
        ],
      ),
    );
  }

  Widget _buildOccupancyChart() {
    final vacant = _getVacantPositions();
    final occupied = _positions.length - vacant;
    
    return Container(
      height: 250,
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
            'Taux d\'Occupation',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
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
                    value: occupied.toDouble(),
                    title: 'Occupés\n$occupied',
                    titleStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  PieChartSectionData(
                    color: Colors.orange,
                    value: vacant.toDouble(),
                    title: 'Vacants\n$vacant',
                    titleStyle: const TextStyle(
                      fontSize: 12,
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

  Widget _buildLevelDistribution() {
    final levels = ['Direction', 'Cadre', 'Employé'];
    final data = levels.map((level) {
      return _positions.where((p) => p['level'] == level).length;
    }).toList();
    
    return Container(
      height: 250,
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
            'Distribution par Niveau',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: data.reduce((a, b) => a > b ? a : b).toDouble() + 2,
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() < levels.length) {
                          return Text(
                            levels[value.toInt()],
                            style: const TextStyle(fontSize: 10, color: Colors.white70),
                          );
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
                        return Text('${value.toInt()}', style: const TextStyle(color: Colors.white70));
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                barGroups: data.asMap().entries.map((entry) {
                  return BarChartGroupData(
                    x: entry.key,
                    barRods: [
                      BarChartRodData(
                        toY: entry.value.toDouble(),
                        color: _getLevelColor(levels[entry.key]),
                        width: 30,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(4),
                          topRight: Radius.circular(4),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDepartmentAnalysis() {
    final departments = _positions.map((p) => p['department']).toSet().toList();
    
    return Container(
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
                Icon(Icons.analytics, color: Colors.white),
                SizedBox(width: 10),
                Text(
                  'Analyse par Département',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),)
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: departments.map((dept) {
                final deptPositions = _positions.where((p) => p['department'] == dept).toList();
                final vacant = deptPositions.where((p) => p['assignedTo'] == null).length;
                final total = deptPositions.length;
                final occupancy = total > 0 ? ((total - vacant) / total * 100).toInt() : 0;
                
                return Padding(
                  padding: const EdgeInsets.only(bottom: 15),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(
                          dept,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text('$total postes', style: const TextStyle(color: Colors.white70)),
                      ),
                      Expanded(
                        child: Text('$vacant vacants', style: const TextStyle(color: Colors.white70)),
                      ),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: occupancy >= 80 ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$occupancy%',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: occupancy >= 80 ? Colors.green : Colors.orange,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSalaryAnalysis() {
    final avgSalary = _positions.isNotEmpty ? _positions.map((p) => p['salary']).reduce((a, b) => a + b) / _positions.length : 0;
    final minSalary = _positions.isNotEmpty ? _positions.map((p) => p['salary']).reduce((a, b) => a < b ? a : b) : 0;
    final maxSalary = _positions.isNotEmpty ? _positions.map((p) => p['salary']).reduce((a, b) => a > b ? a : b) : 0;
    
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
            'Analyse Salariale',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildSalaryMetric('Moyenne', '${avgSalary.toInt()}K', Colors.blue),
              ),
              Expanded(
                child: _buildSalaryMetric('Minimum', '${minSalary}K', Colors.orange),
              ),
              Expanded(
                child: _buildSalaryMetric('Maximum', '${maxSalary}K', Colors.green),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSalaryMetric(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(15),
      margin: const EdgeInsets.symmetric(horizontal: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton.extended(
      onPressed: _showAddPositionDialog,
      backgroundColor: const Color(0xFF1E293B),
      foregroundColor: Colors.white,
      icon: const Icon(Icons.add),
      label: const Text('Nouveau Poste'),
      elevation: 8,
    );
  }

  // Méthodes utilitaires et de données
  List<Map<String, dynamic>> get _positions => [
    {
      'id': '1',
      'title': 'Directeur Général',
      'department': 'Direction',
      'level': 'Direction',
      'category': 'management',
      'salary': 150,
      'assignedTo': 'Jean Dupont',
      'description': 'Supervision générale de l\'entreprise et prise de décisions stratégiques',
      'isNew': false,
    },
    {
      'id': '2',
      'title': 'Chef de Projet IT',
      'department': 'Informatique',
      'level': 'Cadre',
      'category': 'technical',
      'salary': 80,
      'assignedTo': null,
      'description': 'Gestion des projets informatiques et coordination des équipes techniques',
      'isNew': true,
    },
    {
      'id': '3',
      'title': 'Développeur Senior',
      'department': 'Informatique',
      'level': 'Cadre',
      'category': 'technical',
      'salary': 70,
      'assignedTo': 'Marie Martin',
      'description': 'Développement d\'applications et encadrement des développeurs juniors',
      'isNew': false,
    },
    {
      'id': '4',
      'title': 'Comptable',
      'department': 'Finance',
      'level': 'Employé',
      'category': 'administrative',
      'salary': 45,
      'assignedTo': 'Pierre Durand',
      'description': 'Gestion de la comptabilité générale et des déclarations fiscales',
      'isNew': false,
    },
    {
      'id': '5',
      'title': 'Responsable RH',
      'department': 'Ressources Humaines',
      'level': 'Cadre',
      'category': 'management',
      'salary': 65,
      'assignedTo': null,
      'description': 'Gestion du personnel et des politiques RH',
      'isNew': true,
    },
    {
      'id': '6',
      'title': 'Commercial',
      'department': 'Ventes',
      'level': 'Employé',
      'category': 'sales',
      'salary': 40,
      'assignedTo': 'Sophie Bernard',
      'description': 'Prospection clientèle et développement commercial',
      'isNew': false,
    },
    {
      'id': '7',
      'title': 'Assistant de Direction',
      'department': 'Direction',
      'level': 'Employé',
      'category': 'administrative',
      'salary': 35,
      'assignedTo': null,
      'description': 'Support administratif à la direction générale',
      'isNew': true,
    },
  ];

  int _getVacantPositions() {
    return _positions.where((p) => p['assignedTo'] == null).length;
  }

  List<Map<String, dynamic>> _getFilteredPositions() {
    var filtered = _positions;
    
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((p) =>
        p['title'].toLowerCase().contains(_searchQuery.toLowerCase()) ||
        p['department'].toLowerCase().contains(_searchQuery.toLowerCase())
      ).toList();
    }
    
    switch (_selectedFilter) {
      case 'vacant':
        return filtered.where((p) => p['assignedTo'] == null).toList();
      case 'occupied':
        return filtered.where((p) => p['assignedTo'] != null).toList();
      case 'new':
        return filtered.where((p) => p['isNew'] == true).toList();
      default:
        return filtered;
    }
  }

  Color _getLevelColor(String level) {
    switch (level) {
      case 'Direction':
        return Colors.purple;
      case 'Cadre':
        return Colors.blue;
      case 'Employé':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getPositionIcon(String category) {
    switch (category) {
      case 'management':
        return Icons.supervisor_account;
      case 'technical':
        return Icons.computer;
      case 'administrative':
        return Icons.description;
      case 'sales':
        return Icons.trending_up;
      default:
        return Icons.work;
    }
  }

  void _showPositionDetails(Map<String, dynamic> position) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(position['title'], style: const TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Département: ${position['department']}', style: const TextStyle(color: Colors.white70)),
            Text('Niveau: ${position['level']}', style: const TextStyle(color: Colors.white70)),
            Text('Salaire: ${position['salary']}K', style: const TextStyle(color: Colors.white70)),
            if (position['assignedTo'] != null)
              Text('Assigné à: ${position['assignedTo']}', style: const TextStyle(color: Colors.white70))
            else
              const Text('Poste vacant', style: TextStyle(color: Colors.orange)),
            const SizedBox(height: 10),
            Text(position['description'], style: const TextStyle(color: Colors.white70)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer', style: TextStyle(color: Colors.white)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _showEditPositionDialog(position);
            },
            child: const Text('Modifier'),
          ),
        ],
      ),
    );
  }

  void _handlePositionAction(String action, Map<String, dynamic> position) {
    switch (action) {
      case 'edit':
        _showEditPositionDialog(position);
        break;
      case 'assign':
        _showAssignPositionDialog(position);
        break;
      case 'duplicate':
        _duplicatePosition(position);
        break;
      case 'delete':
        _deletePosition(position);
        break;
    }
  }

  void _showAddPositionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Nouveau Poste', style: TextStyle(color: Colors.white)),
        content: const Text('Formulaire d\'ajout de poste à implémenter', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler', style: TextStyle(color: Colors.white)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Créer'),
          ),
        ],
      ),
    );
  }

  void _showEditPositionDialog(Map<String, dynamic> position) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Modifier le Poste', style: TextStyle(color: Colors.white)),
        content: const Text('Formulaire de modification à implémenter', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler', style: TextStyle(color: Colors.white)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Sauvegarder'),
          ),
        ],
      ),
    );
  }

  void _showAssignPositionDialog(Map<String, dynamic> position) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Assigner le Poste', style: TextStyle(color: Colors.white)),
        content: const Text('Liste des employés disponibles à implémenter', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler', style: TextStyle(color: Colors.white)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Assigner'),
          ),
        ],
      ),
    );
  }

  void _duplicatePosition(Map<String, dynamic> position) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Poste "${position['title']}" dupliqué'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _deletePosition(Map<String, dynamic> position) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Supprimer le Poste', style: TextStyle(color: Colors.white)),
        content: Text('Êtes-vous sûr de vouloir supprimer le poste "${position['title']}" ?', style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler', style: TextStyle(color: Colors.white)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Poste "${position['title']}" supprimé'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
}
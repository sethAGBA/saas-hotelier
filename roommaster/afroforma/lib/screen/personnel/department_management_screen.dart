import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class DepartmentManagementScreen extends StatefulWidget {
  final Animation<double> fadeAnimation;
  final Gradient gradient;

  const DepartmentManagementScreen({
    super.key,
    required this.fadeAnimation,
    required this.gradient,
  });

  @override
  State<DepartmentManagementScreen> createState() => _DepartmentManagementScreenState();
}

class _DepartmentManagementScreenState extends State<DepartmentManagementScreen>
    with TickerProviderStateMixin {
  late AnimationController _cardAnimationController;
  late AnimationController _chartAnimationController;
  late Animation<double> _cardAnimation;
  late Animation<double> _chartAnimation;
  
  String _selectedView = 'cards'; // 'cards', 'hierarchy', 'analytics'
  int _selectedDepartmentIndex = -1;
  // Minimal departments sample data to avoid undefined getter errors.
  final List<Map<String, dynamic>> _departments = [
    {
      'name': 'Direction Générale',
      'manager': 'Marie DUPONT',
      'employees': 3,
      'budget': 12.0,
      'performance': 95,
      'turnover': 1,
      'color': Colors.purple,
      'icon': Icons.business_center,
    },
    {
      'name': 'Administration',
      'manager': 'Paul MARTIN',
      'employees': 8,
      'budget': 6.5,
      'performance': 78,
      'turnover': 4,
      'color': Colors.blue,
      'icon': Icons.admin_panel_settings,
    },
    {
      'name': 'Pédagogie',
      'manager': 'Sophie DURAND',
      'employees': 12,
      'budget': 10.0,
      'performance': 85,
      'turnover': 2,
      'color': Colors.green,
      'icon': Icons.school,
    },
    {
      'name': 'Commercial',
      'manager': 'Jean MICHEL',
      'employees': 9,
      'budget': 8.0,
      'performance': 82,
      'turnover': 6,
      'color': Colors.orange,
      'icon': Icons.sell,
    },
    {
      'name': 'Technique',
      'manager': 'Ahmed ALI',
      'employees': 5,
      'budget': 5.0,
      'performance': 90,
      'turnover': 3,
      'color': Colors.red,
      'icon': Icons.settings,
    },
  ];

  void _handleDepartmentAction(String action, Map<String, dynamic> department) {
    if (action == 'edit') {
      // show edit dialog or route
      _showEditDepartmentDialog(department);
    } else if (action == 'budget') {
      // budget action
    } else if (action == 'report') {
      // report action
    }
  }

  Widget _buildActionChip(String label, IconData icon, VoidCallback onTap) {
    return ActionChip(
      avatar: Icon(icon, size: 16),
      label: Text(label),
      onPressed: onTap,
      backgroundColor: Colors.grey[100],
    );
  }

  void _showAddDepartmentDialog() {
    showDialog(
      context: context,
      builder: (context) {
        final _nameController = TextEditingController();
        return AlertDialog(
          title: const Text('Nouveau Département'),
          content: TextField(
            controller: _nameController,
            decoration: const InputDecoration(hintText: 'Nom du département'),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
            TextButton(
              onPressed: () {
                if (_nameController.text.trim().isNotEmpty) {
                  setState(() {
                    _departments.add({
                      'name': _nameController.text.trim(),
                      'manager': '',
                      'employees': 0,
                      'budget': 0.0,
                      'performance': 0,
                      'turnover': 0,
                      'color': Colors.grey,
                      'icon': Icons.business,
                    });
                  });
                }
                Navigator.pop(context);
              },
              child: const Text('Ajouter'),
            ),
          ],
        );
      },
    );
  }

  void _showEditDepartmentDialog(Map<String, dynamic> department) {
    // Simple placeholder edit dialog
    showDialog(
      context: context,
      builder: (context) {
        final _managerController = TextEditingController(text: department['manager']);
        return AlertDialog(
          title: Text('Modifier ${department['name']}'),
          content: TextField(controller: _managerController, decoration: const InputDecoration(hintText: 'Manager')),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
            TextButton(
              onPressed: () {
                setState(() {
                  department['manager'] = _managerController.text.trim();
                });
                Navigator.pop(context);
              },
              child: const Text('Enregistrer'),
            ),
          ],
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _cardAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _chartAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _cardAnimation = CurvedAnimation(
      parent: _cardAnimationController,
      curve: Curves.elasticOut,
    );
    _chartAnimation = CurvedAnimation(
      parent: _chartAnimationController,
      curve: Curves.easeInOut,
    );
    
    _cardAnimationController.forward();
    _chartAnimationController.forward();
  }

  @override
  void dispose() {
    _cardAnimationController.dispose();
    _chartAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: widget.fadeAnimation,
      child: Container(
        decoration: BoxDecoration(gradient: widget.gradient),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Column(
            children: [
              _buildHeader(),
              _buildViewSelector(),
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
        color: Colors.white.withOpacity(0.95),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(35),
          bottomRight: Radius.circular(35),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
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
                  Icons.business,
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
                      'Gestion des Départements',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'Organisation & Performance',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
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
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        children: [
          const Icon(Icons.people, color: Colors.blue, size: 24),
          const SizedBox(height: 5),
          const Text(
            '45',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
          Text(
            'Employés',
            style: TextStyle(
              fontSize: 12,
              color: Colors.blue[700],
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
            'Budget Total',
            '45 500 000 FCFA',
            Icons.attach_money,
            Colors.green,
            '+12%',
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: _buildSummaryCard(
            'Productivité',
            '87%',
            Icons.trending_up,
            Colors.blue,
            '+5%',
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: _buildSummaryCard(
            'Taux Absentéisme',
            '3.2%',
            Icons.person_off,
            Colors.orange,
            '-1.5%',
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
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildViewButton('cards', Icons.view_module, 'Vue Cartes'),
          _buildViewButton('hierarchy', Icons.account_tree, 'Hiérarchie'),
          _buildViewButton('analytics', Icons.analytics, 'Analyses'),
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
                color: isSelected ? Colors.white : Colors.grey[600],
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey[600],
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

  Widget _buildContent() {
    switch (_selectedView) {
      case 'hierarchy':
        return _buildHierarchyView();
      case 'analytics':
        return _buildAnalyticsView();
      default:
        return _buildCardsView();
    }
  }

  Widget _buildCardsView() {
    return AnimatedBuilder(
      animation: _cardAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _cardAnimation.value,
          child: GridView.builder(
            padding: const EdgeInsets.all(25),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.1,
              crossAxisSpacing: 20,
              mainAxisSpacing: 20,
            ),
            itemCount: _departments.length,
            itemBuilder: (context, index) {
              return _buildDepartmentCard(_departments[index], index);
            },
          ),
        );
      },
    );
  }

  Widget _buildDepartmentCard(Map<String, dynamic> department, int index) {
    return GestureDetector(
      onTap: () => _showDepartmentDetails(department),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Background gradient
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    department['color'].withOpacity(0.1),
                    department['color'].withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(25),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: department['color'],
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: department['color'].withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Icon(
                          department['icon'],
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const Spacer(),
                      PopupMenuButton<String>(
                        icon: Icon(Icons.more_vert, color: Colors.grey[600]),
                        onSelected: (value) => _handleDepartmentAction(value, department),
                        itemBuilder: (context) => [
                          const PopupMenuItem(value: 'edit', child: Text('Modifier')),
                          const PopupMenuItem(value: 'budget', child: Text('Budget')),
                          const PopupMenuItem(value: 'report', child: Text('Rapport')),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  Text(
                    department['name'],
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    department['manager'],
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      _buildDepartmentStat(
                        Icons.people,
                        '${department['employees']}',
                        'Employés',
                        department['color'],
                      ),
                      const SizedBox(width: 15),
                      _buildDepartmentStat(
                        Icons.attach_money,
                        '${department['budget']}M',
                        'Budget',
                        department['color'],
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Performance indicator
                  Row(
                    children: [
                      Text(
                        'Performance: ',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      Expanded(
                        child: LinearProgressIndicator(
                          value: department['performance'] / 100,
                          backgroundColor: Colors.grey[200],
                          valueColor: AlwaysStoppedAnimation<Color>(department['color']),
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        '${department['performance']}%',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: department['color'],
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
    );
  }

  Widget _buildDepartmentStat(IconData icon, String value, String label, Color color) {
    return Column(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(height: 2),
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
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildHierarchyView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(25),
      child: Column(
        children: [
          // Direction Générale
          _buildHierarchyNode(
            'Direction Générale',
            'Marie DUPONT',
            'Directrice Générale',
            Icons.business_center,
            Colors.purple,
            0,
            isRoot: true,
          ),
          const SizedBox(height: 30),
          // Départements niveau 1
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildHierarchyNode(
                'Administration',
                'Paul MARTIN',
                'Responsable RH',
                Icons.admin_panel_settings,
                Colors.blue,
                1,
              ),
              _buildHierarchyNode(
                'Pédagogie',
                'Sophie DURAND',
                'Dir. Pédagogique',
                Icons.school,
                Colors.green,
                1,
              ),
            ],
          ),
          const SizedBox(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildHierarchyNode(
                'Commercial',
                'Jean MICHEL',
                'Dir. Commercial',
                Icons.sell,
                Colors.orange,
                1,
              ),
              _buildHierarchyNode(
                'Technique',
                'Ahmed ALI',
                'Resp. Technique',
                Icons.settings,
                Colors.red,
                1,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHierarchyNode(
    String department,
    String manager,
    String position,
    IconData icon,
    Color color,
    int level, {
    bool isRoot = false,
  }) {
    return Container(
      width: isRoot ? 250 : 180,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isRoot ? color : color.withOpacity(0.5),
          width: isRoot ? 3 : 2,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color, color.withOpacity(0.7)],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: isRoot ? 32 : 24),
          ),
          const SizedBox(height: 15),
          Text(
            department,
            style: TextStyle(
              fontSize: isRoot ? 16 : 14,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 5),
          Text(
            manager,
            style: TextStyle(
              fontSize: isRoot ? 14 : 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            position,
            style: TextStyle(
              fontSize: isRoot ? 12 : 10,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          if (!isRoot) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Text(
                '${_departments.firstWhere((d) => d['name'] == department)['employees']} employés',
                style: TextStyle(
                  fontSize: 10,
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAnalyticsView() {
    return AnimatedBuilder(
      animation: _chartAnimation,
      builder: (context, child) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(25),
          child: Column(
            children: [
              _buildBudgetChart(),
              const SizedBox(height: 30),
              _buildPerformanceChart(),
              const SizedBox(height: 30),
              _buildComparisonTable(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBudgetChart() {
    return Container(
      height: 300,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Répartition Budget par Département',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 60,
                sections: _buildPieChartSections(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<PieChartSectionData> _buildPieChartSections() {
    return _departments.map((department) {
      final double percentage = (department['budget'] / 45.5) * 100;
      return PieChartSectionData(
        color: department['color'],
        value: department['budget'].toDouble(),
        title: '${percentage.toStringAsFixed(1)}%',
        radius: 80,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  Widget _buildPerformanceChart() {
    return Container(
      height: 300,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Performance par Département',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 100,
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < _departments.length) {
                          return Text(
                            _departments[index]['name'].toString().substring(0, 3),
                            style: const TextStyle(fontSize: 10),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text('${value.toInt()}%');
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                barGroups: _buildBarGroups(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<BarChartGroupData> _buildBarGroups() {
    return _departments.asMap().entries.map((entry) {
      final index = entry.key;
      final department = entry.value;
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: department['performance'].toDouble(),
            color: department['color'],
            width: 30,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(6),
              topRight: Radius.circular(6),
            ),
          ),
        ],
      );
    }).toList();
  }

  Widget _buildComparisonTable() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
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
                topLeft: Radius.circular(25),
                topRight: Radius.circular(25),
              ),
            ),
            child: const Row(
              children: [
                Icon(Icons.table_chart, color: Colors.white),
                SizedBox(width: 10),
                Text(
                  'Tableau Comparatif des Départements',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: const [
                DataColumn(label: Text('Département')),
                DataColumn(label: Text('Manager')),
                DataColumn(label: Text('Employés')),
                DataColumn(label: Text('Budget (M)')),
                DataColumn(label: Text('Performance')),
                DataColumn(label: Text('Turnover')),
              ],
              rows: _departments.map((dept) {
                return DataRow(
                  cells: [
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: dept['color'],
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(dept['name']),
                        ],
                      ),
                    ),
                    DataCell(Text(dept['manager'])),
                    DataCell(Text('${dept['employees']}')),
                    DataCell(Text('${dept['budget']}')),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: dept['performance'] >= 80 ? Colors.green[100] : 
                                 dept['performance'] >= 60 ? Colors.orange[100] : Colors.red[100],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${dept['performance']}%',
                          style: TextStyle(
                            color: dept['performance'] >= 80 ? Colors.green[700] : 
                                   dept['performance'] >= 60 ? Colors.orange[700] : Colors.red[700],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    DataCell(Text('${dept['turnover']}%')),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton.extended(
      onPressed: _showAddDepartmentDialog,
      backgroundColor: Colors.white,
      foregroundColor: Colors.black87,
      icon: const Icon(Icons.add),
      label: const Text('Nouveau Département'),
    );
  }

  void _showDepartmentDetails(Map<String, dynamic> department) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(department['icon'], color: department['color']),
            const SizedBox(width: 10),
            Text(department['name']),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Manager', department['manager']),
            _buildDetailRow('Employés', '${department['employees']}'),
            _buildDetailRow('Budget', '${department['budget']}M FCFA'),
            _buildDetailRow('Performance', '${department['performance']}%'),
            _buildDetailRow('Turnover', '${department['turnover']}%'),
            const SizedBox(height: 15),
            const Text(
              'Actions disponibles:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              children: [
                _buildActionChip('Modifier budget', Icons.edit, () {}),
                _buildActionChip('Voir équipe', Icons.people, () {}),
                _buildActionChip('Rapport', Icons.assessment, () {}),
              ],
            ),
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$label:',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          Text(value),
        ],
      ),
    );  }
    }
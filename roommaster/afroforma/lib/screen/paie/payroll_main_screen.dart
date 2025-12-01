import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:fl_chart/fl_chart.dart';
import 'package:afroforma/services/database_service.dart';

class PayrollMainScreen extends StatefulWidget {
  final Animation<double> fadeAnimation;
  final Gradient gradient;

  const PayrollMainScreen({
    super.key,
    required this.fadeAnimation,
    required this.gradient,
  });

  @override
  State<PayrollMainScreen> createState() => _PayrollMainScreenState();
}

class _PayrollMainScreenState extends State<PayrollMainScreen>
    with TickerProviderStateMixin {
  late AnimationController _cardAnimationController;
  late AnimationController _chartAnimationController;
  late Animation<double> _cardAnimation;
  late Animation<double> _chartAnimation;
  
  String _selectedPeriod = 'current'; // 'current', 'previous', 'annual'
  String _selectedView = 'overview'; // 'overview', 'employees', 'reports', 'settings'
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

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
      curve: Curves.easeOutCubic,
    );
    
    _cardAnimationController.forward();
    _chartAnimationController.forward();
  }

  @override
  void dispose() {
    _cardAnimationController.dispose();
    _chartAnimationController.dispose();
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
              if (_selectedView == 'employees') _buildSearchBar(),
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
                  Icons.payments_rounded,
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
                      'Gestion de la Paie',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'Salaires & Avantages',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              _buildPeriodSelector(),
            ],
          ),
          const SizedBox(height: 20),
          _buildPayrollSummary(),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedPeriod,
          onChanged: (value) => setState(() => _selectedPeriod = value!),
          items: const [
            DropdownMenuItem(value: 'current', child: Text('Mois Actuel')),
            DropdownMenuItem(value: 'previous', child: Text('Mois Précédent')),
            DropdownMenuItem(value: 'annual', child: Text('Annuel')),
          ],
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
          dropdownColor: const Color(0xFF1E293B),
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white70),
        ),
      ),
    );
  }

  Widget _buildPayrollSummary() {
    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            'Masse Salariale',
            '425,850 FCFA',
            Icons.euro,
            Colors.green,
            '+3.2%',
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: _buildSummaryCard(
            'Employés Payés',
            '156/160',
            Icons.group,
            Colors.blue,
            '97.5%',
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: _buildSummaryCard(
            'Charges Sociales',
            '127,755 FCFA',
            Icons.account_balance,
            Colors.orange,
            '30%',
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color, String indicator) {
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
                  color: color,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  indicator,
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
            child: _buildActionButton(
              Icons.calculate,
              'Calculer Paie',
              Colors.blue,
              _calculatePayroll,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: _buildActionButton(
              Icons.file_download,
              'Exporter',
              Colors.green,
              _exportPayroll,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: _buildActionButton(
              Icons.send,
              'Envoyer Fiches',
              Colors.purple,
              _sendPayslips,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: _buildActionButton(
              Icons.settings,
              'Paramètres',
              Colors.orange,
              _openSettings,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(15),
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
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
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
          _buildViewButton('overview', Icons.dashboard, 'Vue d\'ensemble'),
          _buildViewButton('employees', Icons.people, 'Employés'),
          _buildViewButton('reports', Icons.assessment, 'Rapports'),
          _buildViewButton('settings', Icons.tune, 'Paramètres'),
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

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
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
    );
  }

  Widget _buildContent() {
    switch (_selectedView) {
      case 'employees':
        return _buildEmployeesView();
      case 'reports':
        return _buildReportsView();
      case 'settings':
        return _buildSettingsView();
      default:
        return _buildOverviewView();
    }
  }

  Widget _buildOverviewView() {
    return AnimatedBuilder(
      animation: _cardAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _cardAnimation.value,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(25),
            child: Column(
              children: [
                _buildPayrollChart(),
                const SizedBox(height: 20),
                _buildPayrollBreakdown(),
                const SizedBox(height: 20),
                _buildRecentTransactions(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPayrollChart() {
    return Container(
      height: 300,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Évolution Masse Salariale (6 mois)',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: AnimatedBuilder(
              animation: _chartAnimation,
              builder: (context, child) {
                return LineChart(
                  LineChartData(
                    lineBarsData: [
                      LineChartBarData(
                        spots: [
                          FlSpot(0, 380000 * _chartAnimation.value),
                          FlSpot(1, 385000 * _chartAnimation.value),
                          FlSpot(2, 395000 * _chartAnimation.value),
                          FlSpot(3, 410000 * _chartAnimation.value),
                          FlSpot(4, 415000 * _chartAnimation.value),
                          FlSpot(5, 425850 * _chartAnimation.value),
                        ],
                        isCurved: true,
                        color: Colors.blue,
                        barWidth: 3,
                        dotData: const FlDotData(show: true),
                        belowBarData: BarAreaData(
                          show: true,
                          color: Colors.blue.withOpacity(0.2),
                        ),
                      ),
                    ],
                    titlesData: FlTitlesData(
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            const months = ['Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Juin'];
                            return Text(months[value.toInt()]);
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 60,
                          getTitlesWidget: (value, meta) {
                            return Text('${(value / 1000).toInt()}kFCFA');
                          },
                        ),
                      ),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    borderData: FlBorderData(show: false),
                    minX: 0,
                    maxX: 5,
                    minY: 350000,
                    maxY: 450000,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPayrollBreakdown() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Répartition des Coûts',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 15),
          _buildBreakdownItem('Salaires Bruts', '425,850 FCFA', 70.0, Colors.blue),
          _buildBreakdownItem('Charges Patronales', '127,755 FCFA', 21.0, Colors.orange),
          _buildBreakdownItem('Avantages', '36,415 FCFA', 6.0, Colors.green),
          _buildBreakdownItem('Primes', '18,205 FCFA', 3.0, Colors.purple),
        ],
      ),
    );
  }

  Widget _buildBreakdownItem(String label, String amount, double percentage, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: percentage / 100,
                  backgroundColor: Theme.of(context).dividerColor.withOpacity(0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ],
            ),
          ),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                amount,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                '${percentage.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecentTransactions() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Dernières Transactions',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              TextButton(
                onPressed: () {},
                child: const Text('Voir tout'),
              ),
            ],
          ),
          const SizedBox(height: 15),
          ..._getRecentTransactions().map((transaction) => _buildTransactionItem(transaction)),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(Map<String, dynamic> transaction) {
    final color = _getTransactionColor(transaction['type']);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
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
              _getTransactionIcon(transaction['type']),
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
                  transaction['description'],
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                Text(
                  transaction['date'],
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          Text(
            transaction['amount'],
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
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
        return _buildEmployeePayrollCard(employees[index]);
      },
    );
  }

  Widget _buildEmployeePayrollCard(Map<String, dynamic> employee) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
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
                      ),
                    ),
                Text(
                  employee['position'],
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${employee['salary']} FCFA',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: employee['status'] == 'Payé' ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      employee['status'],
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: employee['status'] == 'Payé' ? Colors.green : Colors.orange,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(child: _buildPayrollMetric('Brut', '${employee['grossSalary']} FCFA', Colors.blue)),
              Expanded(child: _buildPayrollMetric('Net', '${employee['netSalary']} FCFA', Colors.green)),
              Expanded(child: _buildPayrollMetric('Charges', '${employee['charges']} FCFA', Colors.orange)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPayrollMetric(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
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

  Widget _buildReportsView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(25),
      child: Column(
        children: [
          _buildReportCard(
            'Bulletin de Paie',
            'Générer les bulletins mensuels',
            Icons.receipt_long,
            Colors.blue,
            _generatePayslips,
          ),
          const SizedBox(height: 15),
          _buildReportCard(
            'Déclarations Sociales',
            'CNSS, IRPP (OTR), mutuelle',
            Icons.account_balance,
            Colors.orange,
            _generateSocialDeclarations,
          ),
          const SizedBox(height: 15),
          _buildReportCard(
            'Livre de Paie',
            'Registre légal des salaires',
            Icons.book,
            Colors.green,
            _generatePayrollBook,
          ),
          const SizedBox(height: 15),
          _buildReportCard(
            'Charges Sociales',
            'Analyse des cotisations',
            Icons.pie_chart,
            Colors.purple,
            _generateChargesReport,
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
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
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
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(25),
      child: Column(
        children: [
          _buildSettingCard(
            'Paramètres de Paie',
            'Configuration des salaires de base',
            Icons.settings,
            Colors.blue,
            () {},
          ),
          const SizedBox(height: 15),
          _buildSettingCard(
            'Taux de Cotisations',
            'CNSS, IRPP (OTR), mutuelle',
            Icons.percent,
            Colors.green,
            _openTogoSettingsDialog,
          ),
          const SizedBox(height: 15),
          _buildSettingCard(
            'Conventions Collectives',
            'Grilles salariales et accords',
            Icons.gavel,
            Colors.purple,
            () {},),
          const SizedBox(height: 15),
          _buildSettingCard(
            'Modèles de Bulletins',
            'Personnalisation des fiches de paie',
            Icons.description,
            Colors.orange,
            () {},
          ),
          const SizedBox(height: 15),
          _buildSettingCard(
            'Notifications',
            'Alertes et rappels de paie',
            Icons.notifications,
            Colors.red,
            () {},
          ),
        ],
      ),
    );
  }

  Widget _buildSettingCard(String title, String description, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
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
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  // Méthodes pour les données
  List<Map<String, dynamic>> _getRecentTransactions() {
    return [
      {
        'type': 'payment',
        'description': 'Virement masse salariale',
        'date': 'Aujourd\'hui',
        'amount': '425,850 FCFA',
      },
      {
        'type': 'charges',
        'description': 'Charges CNSS',
        'date': 'Hier',
        'amount': '85,170 FCFA',
      },
      {
        'type': 'bonus',
        'description': 'Primes équipe commerciale',
        'date': '2 jours',
        'amount': '12,500 FCFA',
      },
      {
        'type': 'expense',
        'description': 'Remboursements frais',
        'date': '3 jours',
        'amount': '3,250 FCFA',
      },
    ];
  }

  Color _getTransactionColor(String type) {
    switch (type) {
      case 'payment':
        return Colors.green;
      case 'charges':
        return Colors.orange;
      case 'bonus':
        return Colors.purple;
      case 'expense':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData _getTransactionIcon(String type) {
    switch (type) {
      case 'payment':
        return Icons.payments;
      case 'charges':
        return Icons.account_balance;
      case 'bonus':
        return Icons.card_giftcard;
      case 'expense':
        return Icons.receipt;
      default:
        return Icons.help;
    }
  }

  List<Map<String, dynamic>> _getEmployees() {
    return [
      {
        'name': 'Marie Dubois',
        'position': 'Directrice Marketing',
        'salary': 4500,
        'grossSalary': 4500,
        'netSalary': 3465,
        'charges': 1035,
        'status': 'Payé',
      },
      {
        'name': 'Jean Martin',
        'position': 'Développeur Senior',
        'salary': 3800,
        'grossSalary': 3800,
        'netSalary': 2926,
        'charges': 874,
        'status': 'En attente',
      },
      {
        'name': 'Sophie Laurent',
        'position': 'Chef de projet',
        'salary': 3200,
        'grossSalary': 3200,
        'netSalary': 2464,
        'charges': 736,
        'status': 'Payé',
      },
      {
        'name': 'Pierre Durand',
        'position': 'Commercial',
        'salary': 2800,
        'grossSalary': 2800,
        'netSalary': 2156,
        'charges': 644,
        'status': 'Payé',
      },
      {
        'name': 'Amélie Robert',
        'position': 'Comptable',
        'salary': 2600,
        'grossSalary': 2600,
        'netSalary': 2002,
        'charges': 598,
        'status': 'En attente',
      },
    ];
  }

  List<Map<String, dynamic>> _getFilteredEmployees() {
    final employees = _getEmployees();
    if (_searchQuery.isEmpty) {
      return employees;
    }
    return employees.where((employee) {
      return employee['name'].toLowerCase().contains(_searchQuery.toLowerCase()) ||
             employee['position'].toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  // Méthodes d'action
  void _calculatePayroll() {
    // Logique de calcul de la paie
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Calcul de la paie en cours...'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _exportPayroll() {
    // Logique d'export
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Export des données de paie...'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _sendPayslips() {
    // Logique d'envoi des fiches de paie
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Envoi des fiches de paie...'),
        backgroundColor: Colors.purple,
      ),
    );
  }

  void _openSettings() {
    // Logique d'ouverture des paramètres
    setState(() => _selectedView = 'settings');
  }

  Future<void> _openTogoSettingsDialog() async {
    // Load existing settings or defaults
    final raw = await DatabaseService().getPref('payroll_tg_settings');
    double cnssEmp = 4.0; // défaut indicatif
    double cnssEr = 17.5; // défaut indicatif
    double cnssCeiling = 400000; // défaut indicatif (FCFA)
    final thresholds = <double>[0, 50000, 130000, 250000, 400000];
    final rates = <double>[0, 5, 10, 15, 25];
    bool mutEnabled = false;
    double mutRate = 0.0;

    try {
      if (raw != null && raw.isNotEmpty) {
        final data = json.decode(raw) as Map<String, dynamic>;
        final cnss = (data['cnss'] as Map?) ?? {};
        cnssEmp = (cnss['employeeRate'] as num?)?.toDouble() ?? cnssEmp;
        cnssEr = (cnss['employerRate'] as num?)?.toDouble() ?? cnssEr;
        cnssCeiling = (cnss['ceiling'] as num?)?.toDouble() ?? cnssCeiling;
        final irpp = (data['irpp'] as List?) ?? [];
        for (int i = 0; i < irpp.length && i < thresholds.length; i++) {
          thresholds[i] = (irpp[i]['threshold'] as num?)?.toDouble() ?? thresholds[i];
          rates[i] = (irpp[i]['rate'] as num?)?.toDouble() ?? rates[i];
        }
        final mut = (data['mutuelle'] as Map?) ?? {};
        mutEnabled = (mut['enabled'] ?? false) == true;
        mutRate = (mut['rate'] as num?)?.toDouble() ?? mutRate;
      }
    } catch (_) {}

    final cnssEmpCtrl = TextEditingController(text: cnssEmp.toString());
    final cnssErCtrl = TextEditingController(text: cnssEr.toString());
    final cnssCeilingCtrl = TextEditingController(text: cnssCeiling.toStringAsFixed(0));
    final thrCtrls = List.generate(thresholds.length, (i) => TextEditingController(text: thresholds[i].toStringAsFixed(0)));
    final rateCtrls = List.generate(rates.length, (i) => TextEditingController(text: rates[i].toString()));
    final mutRateCtrl = TextEditingController(text: mutRate.toString());

    await showDialog(
      context: context,
      builder: (ctx) {
        bool enabledLocal = mutEnabled;
        return StatefulBuilder(
          builder: (ctx, setStateDialog) {
            return AlertDialog(
              backgroundColor: Theme.of(context).cardColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text('Paramètres Paie — Togo'),
              content: SizedBox(
                width: 600,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _dialogSectionHeader(Icons.badge, 'CNSS'),
                      const SizedBox(height: 8),
                      _dialogNumberField('Taux salarié (%)', cnssEmpCtrl),
                      const SizedBox(height: 8),
                      _dialogNumberField('Taux employeur (%)', cnssErCtrl),
                      const SizedBox(height: 8),
                      _dialogNumberField('Plafond base (FCFA)', cnssCeilingCtrl),
                      const SizedBox(height: 16),
                      _dialogSectionHeader(Icons.account_balance, 'IRPP (OTR) — Tranches (exemple, à valider)'),
                      const SizedBox(height: 8),
                      for (int i = 0; i < thrCtrls.length; i++) ...[
                        Row(
                          children: [
                            Expanded(child: _dialogNumberField('Seuil ${i + 1} (FCFA)', thrCtrls[i])),
                            const SizedBox(width: 8),
                            Expanded(child: _dialogNumberField('Taux ${i + 1} (%)', rateCtrls[i])),
                          ],
                        ),
                        const SizedBox(height: 8),
                      ],
                      const SizedBox(height: 8),
                      _dialogSectionHeader(Icons.health_and_safety, 'Mutuelle'),
                      const SizedBox(height: 8),
                      SwitchListTile(
                        value: enabledLocal,
                        onChanged: (v) => setStateDialog(() => enabledLocal = v),
                        title: const Text('Activer la mutuelle'),
                        contentPadding: EdgeInsets.zero,
                      ),
                      if (enabledLocal) _dialogNumberField('Taux mutuelle (%)', mutRateCtrl),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Annuler'),
                ),
                ElevatedButton.icon(
                  onPressed: () async {
                    final data = json.encode({
                      'cnss': {
                        'employeeRate': double.tryParse(cnssEmpCtrl.text) ?? 0.0,
                        'employerRate': double.tryParse(cnssErCtrl.text) ?? 0.0,
                        'ceiling': double.tryParse(cnssCeilingCtrl.text) ?? 0.0,
                      },
                      'irpp': List.generate(thrCtrls.length, (i) => {
                        'threshold': double.tryParse(thrCtrls[i].text) ?? 0.0,
                        'rate': double.tryParse(rateCtrls[i].text) ?? 0.0,
                      }),
                      'mutuelle': {
                        'enabled': enabledLocal,
                        'rate': double.tryParse(mutRateCtrl.text) ?? 0.0,
                      },
                    });
                    await DatabaseService().setPref('payroll_tg_settings', data);
                    if (context.mounted) {
                      Navigator.of(ctx).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Paramètres paie (Togo) enregistrés')),
                      );
                    }
                  },
                  icon: const Icon(Icons.save),
                  label: const Text('Enregistrer'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _dialogSectionHeader(IconData icon, String title) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(gradient: widget.gradient, borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: Colors.white, size: 18),
        ),
        const SizedBox(width: 8),
        Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
      ],
    );
  }

  Widget _dialogNumberField(String label, TextEditingController ctrl) {
    return TextField(
      controller: ctrl,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.2),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
      ),
    );
  }

  void _generatePayslips() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Génération des bulletins de paie...'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _generateSocialDeclarations() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Génération des déclarations sociales...'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _generatePayrollBook() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Génération du livre de paie...'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _generateChargesReport() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Génération du rapport des charges...'),
        backgroundColor: Colors.purple,
      ),
    );
  }
}

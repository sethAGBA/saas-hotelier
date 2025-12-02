import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class InventoryResourcesScreen extends StatefulWidget {
  final Animation<double> fadeAnimation;
  final Gradient gradient;

  const InventoryResourcesScreen({
    super.key,
    required this.fadeAnimation,
    required this.gradient,
  });

  @override
  State<InventoryResourcesScreen> createState() => _InventoryResourcesScreenState();
}

class _InventoryResourcesScreenState extends State<InventoryResourcesScreen>
    with TickerProviderStateMixin {
  late AnimationController _cardAnimationController;
  late AnimationController _chartAnimationController;
  late Animation<double> _cardAnimation;
  late Animation<double> _chartAnimation;
  
  String _selectedView = 'overview'; // 'overview', 'stock', 'resources', 'reports'
  String _selectedCategory = 'all'; // 'all', 'equipment', 'supplies', 'materials'
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
        decoration: BoxDecoration(gradient: widget.gradient),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Column(
            children: [
              _buildHeader(),
              _buildQuickActions(),
              _buildViewSelector(),
              if (_selectedView == 'stock') _buildFilters(),
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
                  Icons.inventory_2_rounded,
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
                      'Inventaire & Ressources',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'Gestion du matériel et des stocks',
                      style: TextStyle(
                        fontSize: 16,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              _buildAlertButton(),
            ],
          ),
          const SizedBox(height: 20),
          _buildInventorySummary(),
        ],
      ),
    );
  }

  Widget _buildAlertButton() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: IconButton(
        onPressed: _showAlerts,
        icon: Stack(
          children: [
            const Icon(Icons.notifications, color: Colors.red, size: 24),
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Text(
                    '3',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInventorySummary() {
    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            'Articles Total',
            '1,247',
            Icons.inventory,
            Colors.blue,
            '+15',
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: _buildSummaryCard(
            'Stock Bas',
            '23',
            Icons.warning,
            Colors.orange,
            'Alerte',
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: _buildSummaryCard(
            'Valeur Stock',
            '485,950 FCFA',
            Icons.euro,
            Colors.green,
            '+2.8%',
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
              Icons.add_box,
              'Ajouter Article',
              Colors.blue,
              _addItem,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: _buildActionButton(
              Icons.qr_code_scanner,
              'Scanner',
              Colors.purple,
              _scanCode,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: _buildActionButton(
              Icons.sync,
              'Inventaire',
              Colors.green,
              _performInventory,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: _buildActionButton(
              Icons.file_download,
              'Export',
              Colors.orange,
              _exportData,
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
          _buildViewButton('overview', Icons.dashboard, 'Aperçu'),
          _buildViewButton('stock', Icons.inventory_2, 'Stock'),
          _buildViewButton('resources', Icons.build, 'Ressources'),
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
                color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                size: 16,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
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

  Widget _buildFilters() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Rechercher un article...',
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
          const SizedBox(width: 15),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
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
                value: _selectedCategory,
                onChanged: (value) => setState(() => _selectedCategory = value!),
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('Tous')),
                  DropdownMenuItem(value: 'equipment', child: Text('Équipements')),
                  DropdownMenuItem(value: 'supplies', child: Text('Fournitures')),
                  DropdownMenuItem(value: 'materials', child: Text('Matériaux')),
                ],
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
                dropdownColor: const Color(0xFF1E293B),
                icon: const Icon(Icons.filter_list, color: Colors.white70),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    switch (_selectedView) {
      case 'stock':
        return _buildStockView();
      case 'resources':
        return _buildResourcesView();
      case 'reports':
        return _buildReportsView();
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
                _buildStockChart(),
                const SizedBox(height: 20),
                _buildCategoryBreakdown(),
                const SizedBox(height: 20),
                _buildRecentMovements(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStockChart() {
    return Container(
      height: 300,
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
            'Évolution du Stock (6 mois)',
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
                          FlSpot(0, 1200 * _chartAnimation.value),
                          FlSpot(1, 1180 * _chartAnimation.value),
                          FlSpot(2, 1220 * _chartAnimation.value),
                          FlSpot(3, 1190 * _chartAnimation.value),
                          FlSpot(4, 1235 * _chartAnimation.value),
                          FlSpot(5, 1247 * _chartAnimation.value),
                        ],
                        isCurved: true,
                        color: Colors.purple,
                        barWidth: 3,
                        dotData: const FlDotData(show: true),
                        belowBarData: BarAreaData(
                          show: true,
                          color: Colors.purple.withOpacity(0.2),
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
                          reservedSize: 50,
                          getTitlesWidget: (value, meta) {
                            return Text('${value.toInt()}');
                          },
                        ),
                      ),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    borderData: FlBorderData(show: false),
                    minX: 0,
                    maxX: 5,
                    minY: 1100,
                    maxY: 1300,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryBreakdown() {
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
            'Répartition par Catégorie',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 15),
          _buildBreakdownItem('Équipements', '456', 36.5, Colors.blue),
          _buildBreakdownItem('Fournitures', '523', 42.0, Colors.green),
          _buildBreakdownItem('Matériaux', '268', 21.5, Colors.orange),
        ],
      ),
    );
  }

  Widget _buildBreakdownItem(String label, String count, double percentage, Color color) {
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
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: percentage / 100,
                  backgroundColor: Colors.grey[200],
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
                count,
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
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecentMovements() {
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Mouvements Récents',
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
          ..._getRecentMovements().map((movement) => _buildMovementItem(movement)),
        ],
      ),
    );
  }

  Widget _buildMovementItem(Map<String, dynamic> movement) {
    final color = _getMovementColor(movement['type']);
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
              _getMovementIcon(movement['type']),
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
                  movement['item'],
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${movement['type']} - ${movement['date']}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          Text(
            movement['quantity'],
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

  Widget _buildStockView() {
    final items = _getFilteredItems();
    return ListView.builder(
      padding: const EdgeInsets.all(25),
      itemCount: items.length,
      itemBuilder: (context, index) {
        return _buildInventoryCard(items[index]);
      },
    );
  }

  Widget _buildInventoryCard(Map<String, dynamic> item) {
    final stockStatus = _getStockStatus(item['stock'], item['minStock']);
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
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
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _getCategoryIcon(item['category']),
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
                      item['name'],
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      item['category'],
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
                    '${item['stock']}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: stockStatus['color'],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: stockStatus['color'].withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      stockStatus['label'],
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: stockStatus['color'],
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
              Expanded(child: _buildStockMetric('Prix Unitaire', '${item['price']} FCFA', Colors.blue)),
              Expanded(child: _buildStockMetric('Stock Min.', '${item['minStock']}', Colors.purple)),
              Expanded(child: _buildStockMetric('Valeur', '${item['value']} FCFA', Colors.green)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStockMetric(String label, String value, Color color) {
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

  Widget _buildResourcesView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(25),
      child: Column(
        children: [
          _buildResourceCard(
            'Équipements IT',
            'Ordinateurs, serveurs, imprimantes',
            Icons.computer,
            Colors.blue,
            '145 articles',
          ),
          const SizedBox(height: 15),
          _buildResourceCard(
            'Mobilier de Bureau',
            'Bureaux, chaises, armoires',
            Icons.chair,
            Colors.green,
            '89 articles',
          ),
          const SizedBox(height: 15),
          _buildResourceCard(
            'Outils et Machines',
            'Perceuses, scies, équipements',
            Icons.build,
            Colors.orange,
            '234 articles',
          ),
          const SizedBox(height: 15),
          _buildResourceCard(
            'Véhicules',
            'Voitures, camions, utilitaires',
            Icons.local_shipping,
            Colors.purple,
            '12 véhicules',
          ),
        ],
      ),
    );
  }

  Widget _buildResourceCard(String title, String description, IconData icon, Color color, String count) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
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
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(count,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                  size: 16,
                ),
              ],
            ),
          ],
        ),
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
            'Analyse complète des mouvements',
            Icons.bar_chart,
            Colors.blue,
            'Générer PDF',
          ),
          const SizedBox(height: 15),
          _buildReportCard(
            'Analyse des Coûts',
            'Évolution des prix et dépenses',
            Icons.trending_up,
            Colors.green,
            'Voir détails',
          ),
          const SizedBox(height: 15),
          _buildReportCard(
            'Stock Critique',
            'Articles nécessitant un réapprovisionnement',
            Icons.warning,
            Colors.orange,
            '23 articles',
          ),
          const SizedBox(height: 15),
          _buildReportCard(
            'Performance Fournisseurs',
            'Évaluation des délais et qualité',
            Icons.assessment,
            Colors.purple,
            'Analyser',
          ),
        ],
      ),
    );
  }

  Widget _buildReportCard(String title, String description, IconData icon, Color color, String action) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
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
            ],
          ),
          const SizedBox(height: 15),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                action,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Méthodes utilitaires
  List<Map<String, dynamic>> _getRecentMovements() {
    return [
      {
        'item': 'Ordinateur portable Dell',
        'type': 'Entrée',
        'quantity': '+5',
        'date': 'Aujourd\'hui',
      },
      {
        'item': 'Papier A4',
        'type': 'Sortie',
        'quantity': '-20',
        'date': 'Hier',
      },
      {
        'item': 'Chaise de bureau',
        'type': 'Entrée',
        'quantity': '+3',
        'date': 'Il y a 2 jours',
      },
      {
        'item': 'Cartouches d\'encre',
        'type': 'Sortie',
        'quantity': '-8',
        'date': 'Il y a 3 jours',
      },
    ];
  }

  Color _getMovementColor(String type) {
    switch (type) {
      case 'Entrée':
        return Colors.green;
      case 'Sortie':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  IconData _getMovementIcon(String type) {
    switch (type) {
      case 'Entrée':
        return Icons.add;
      case 'Sortie':
        return Icons.remove;
      default:
        return Icons.swap_horiz;
    }
  }

  List<Map<String, dynamic>> _getFilteredItems() {
    List<Map<String, dynamic>> items = [
      {
        'name': 'Ordinateur portable Dell XPS',
        'category': 'Équipements',
        'stock': 15,
        'minStock': 5,
        'price': 1200,
        'value': 18000,
      },
      {
        'name': 'Papier A4 500 feuilles',
        'category': 'Fournitures',
        'stock': 3,
        'minStock': 10,
        'price': 8.50,
        'value': 25.50,
      },
      {
        'name': 'Chaise de bureau ergonomique',
        'category': 'Mobilier',
        'stock': 25,
        'minStock': 8,
        'price': 350,
        'value': 8750,
      },
      {
        'name': 'Perceuse sans fil Bosch',
        'category': 'Outils',
        'stock': 8,
        'minStock': 3,
        'price': 180,
        'value': 1440,
      },
      {
        'name': 'Cartouches d\'encre HP',
        'category': 'Fournitures',
        'stock': 2,
        'minStock': 15,
        'price': 45,
        'value': 90,
      },
    ];

    // Filtrer par catégorie
    if (_selectedCategory != 'all') {
      items = items.where((item) {
        switch (_selectedCategory) {
          case 'equipment':
            return item['category'] == 'Équipements';
          case 'supplies':
            return item['category'] == 'Fournitures';
          case 'materials':
            return item['category'] == 'Matériaux' || item['category'] == 'Outils';
          default:
            return true;
        }
      }).toList();
    }

    // Filtrer par recherche
    if (_searchQuery.isNotEmpty) {
      items = items.where((item) =>
          item['name'].toString().toLowerCase().contains(_searchQuery.toLowerCase())).toList();
    }

    return items;
  }

  Map<String, dynamic> _getStockStatus(int stock, int minStock) {
    if (stock <= minStock) {
      return {
        'label': 'CRITIQUE',
        'color': Colors.red,
      };
    } else if (stock <= minStock * 1.5) {
      return {
        'label': 'BAS',
        'color': Colors.orange,
      };
    } else {
      return {
        'label': 'NORMAL',
        'color': Colors.green,
      };
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Équipements':
        return Icons.computer;
      case 'Fournitures':
        return Icons.inventory_2;
      case 'Mobilier':
        return Icons.chair;
      case 'Outils':
        return Icons.build;
      default:
        return Icons.category;
    }
  }

  // Méthodes d'action
  void _showAlerts() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Alertes Stock'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildAlertItem('Papier A4', 'Stock critique: 3 restants'),
            _buildAlertItem('Cartouches HP', 'Stock critique: 2 restants'),
            _buildAlertItem('Toner laser', 'Rupture de stock'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Action pour commander
            },
            child: const Text('Commander'),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertItem(String item, String message) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning, color: Colors.red, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  message,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _addItem() {
    // Navigation vers l'écran d'ajout d'article
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Fonctionnalité d\'ajout d\'article')),
    );
  }

  void _scanCode() {
    // Lancement du scanner QR/Code-barres
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Scanner de codes-barres')),
    );
  }

  void _performInventory() {
    // Démarrage d'un inventaire
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Inventaire en cours...')),
    );
  }

  void _exportData() {
    // Export des données
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exporter les données'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.picture_as_pdf),
              title: const Text('PDF'),
              onTap: () {
                Navigator.pop(context);
                // Export PDF
              },
            ),
            ListTile(
              leading: const Icon(Icons.table_chart),
              title: const Text('Excel'),
              onTap: () {
                Navigator.pop(context);
                // Export Excel
              },
            ),
            ListTile(
              leading: const Icon(Icons.code),
              title: const Text('CSV'),
              onTap: () {
                Navigator.pop(context);
                // Export CSV
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
        ],
      ),
    );
  }
}

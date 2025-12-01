import 'package:flutter/material.dart';

class EmployeeListScreen extends StatefulWidget {
  final Animation<double> fadeAnimation;
  final Gradient gradient;

  const EmployeeListScreen({
    super.key,
    required this.fadeAnimation,
    required this.gradient,
  });

  @override
  State<EmployeeListScreen> createState() => _EmployeeListScreenState();
}

class _EmployeeListScreenState extends State<EmployeeListScreen>
    with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  String _selectedDepartment = 'Tous';
  String _selectedContractType = 'Tous';
  String _selectedStatus = 'Tous';
  bool _showOrgChart = false;
  late AnimationController _listAnimationController;
  late Animation<double> _listAnimation;

  @override
  void initState() {
    super.initState();
    _listAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _listAnimation = CurvedAnimation(
      parent: _listAnimationController,
      curve: Curves.elasticOut,
    );
    _listAnimationController.forward();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _listAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: widget.fadeAnimation,
      child: Container(
        color: const Color(0xFF0F172A), // Applying the dark background color
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Column(
            children: [
              _buildHeader(),
              _buildFiltersSection(),
              if (_showOrgChart) _buildOrgChart() else _buildEmployeeList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B), // Dark background for header
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
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
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: widget.gradient,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.people,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 15),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Gestion du Personnel',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white, // Light text
                    ),
                  ),
                  Text(
                    'Effectif actuel : 45 employés',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white70, // Light text
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Row(
                children: [
                  _buildViewToggle(),
                  const SizedBox(width: 10),
                  _buildStatsCards(),
                ],
              ),
            ],
          ),
          const SizedBox(height: 15),
          _buildSearchBar(),
        ],
      ),
    );
  }

  Widget _buildViewToggle() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A), // Dark background
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildToggleButton(
            icon: Icons.list,
            isSelected: !_showOrgChart,
            onTap: () => setState(() => _showOrgChart = false),
            tooltip: 'Vue Liste',
          ),
          _buildToggleButton(
            icon: Icons.account_tree,
            isSelected: _showOrgChart,
            onTap: () => setState(() => _showOrgChart = true),
            tooltip: 'Organigramme',
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton({
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            gradient: isSelected ? widget.gradient : null,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(
            icon,
            color: isSelected ? Colors.white : Colors.white60, // Light icon color
            size: 20,
          ),
        ),
      ),
    );
  }

  Widget _buildStatsCards() {
    return Row(
      children: [
        _buildMiniStatCard('Présents', '42', Icons.check_circle, Colors.green),
        const SizedBox(width: 8),
        _buildMiniStatCard('Congés', '3', Icons.beach_access, Colors.orange),
        const SizedBox(width: 8),
        _buildMiniStatCard('Absents', '2', Icons.cancel, Colors.red),
      ],
    );
  }

  Widget _buildMiniStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
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
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A), // Dark background
        borderRadius: BorderRadius.circular(25),
      ),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(color: Colors.white), // Light text
        decoration: const InputDecoration(
          hintText: 'Rechercher un employé (nom, poste, département)...',
          prefixIcon: Icon(Icons.search, color: Colors.white54), // Light icon
          hintStyle: TextStyle(color: Colors.white54), // Light hint text
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        ),
        onChanged: (value) => setState(() {}),
      ),
    );
  }

  Widget _buildFiltersSection() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B), // Dark background
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.filter_list, color: Colors.white70), // Light icon
              const SizedBox(width: 10),
              const Text(
                'Filtres',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white, // Light text
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () => _showBulkActions(),
                icon: const Icon(Icons.checklist, size: 18, color: Colors.white70), // Light icon
                label: const Text('Actions en lot', style: TextStyle(color: Colors.white70)), // Light text
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildFilterDropdown(
                  'Département',
                  _selectedDepartment,
                  ['Tous', 'Administration', 'Pédagogie', 'Commercial', 'Technique'],
                  (value) => setState(() => _selectedDepartment = value!),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildFilterDropdown(
                  'Type de contrat',
                  _selectedContractType,
                  ['Tous', 'CDI', 'CDD', 'Consultant', 'Stage'],
                  (value) => setState(() => _selectedContractType = value!),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildFilterDropdown(
                  'Statut',
                  _selectedStatus,
                  ['Tous', 'Actif', 'Congés', 'Absent', 'Suspendu'],
                  (value) => setState(() => _selectedStatus = value!),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown(
    String label,
    String value,
    List<String> items,
    Function(String?) onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A), // Dark background
        border: Border.all(color: Colors.white.withOpacity(0.2)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          hint: Text(label, style: const TextStyle(color: Colors.white70)),
          style: const TextStyle(color: Colors.white),
          dropdownColor: const Color(0xFF1E293B),
          icon: const Icon(Icons.arrow_drop_down, color: Colors.white70),
          items: items.map((item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(item),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildOrgChart() {
    return Expanded(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildOrgChartNode('Direction Générale', 'Marie DUPONT', 'DG', 1),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildOrgChartNode('RH', 'Paul MARTIN', 'Responsable RH', 2),
                _buildOrgChartNode('Pédagogie', 'Sophie DURAND', 'Dir. Pédagogique', 2),
                _buildOrgChartNode('Commercial', 'Jean MICHEL', 'Dir. Commercial', 2),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrgChartNode(String department, String name, String position, int level) {
    return Container(
      width: level == 1 ? 200 : 150,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: level == 1 ? Colors.blue : Colors.white.withOpacity(0.2),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: level == 1 ? 30 : 25,
            backgroundColor: Colors.grey[700],
            child: Text(
              name.split(' ').map((e) => e[0]).join(''),
              style: TextStyle(
                fontSize: level == 1 ? 18 : 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            name,
            style: TextStyle(
              fontSize: level == 1 ? 16 : 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            position,
            style: TextStyle(
              fontSize: level == 1 ? 12 : 10,
              color: Colors.white70,
            ),
            textAlign: TextAlign.center,
          ),
          if (level > 1) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                department,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.blue[300],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmployeeList() {
    return Expanded(
      child: AnimatedBuilder(
        animation: _listAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _listAnimation.value,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _employees.length,
              itemBuilder: (context, index) {
                final employee = _employees[index];
                return _buildEmployeeCard(employee, index);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmployeeCard(Map<String, dynamic> employee, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(15),
        leading: Stack(
          children: [
            CircleAvatar(
              radius: 25,
              backgroundColor: Colors.grey[700],
              backgroundImage: employee['photo'] != null
                  ? NetworkImage(employee['photo'])
                  : null,
              child: employee['photo'] == null
                  ? Text(
                      employee['name'].split(' ').map((e) => e[0]).join(''),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    )
                  : null,
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: _getStatusColor(employee['status']),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF1E293B), width: 2),
                ),
              ),
            ),
          ],
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                employee['name'],
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getContractColor(employee['contractType']).withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                employee['contractType'],
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: _getContractColor(employee['contractType']),
                ),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 5),
            Row(
              children: [
                Icon(Icons.work, size: 14, color: Colors.white70),
                const SizedBox(width: 5),
                Text(employee['position'], style: const TextStyle(color: Colors.white70)),
                const SizedBox(width: 15),
                Icon(Icons.business, size: 14, color: Colors.white70),
                const SizedBox(width: 5),
                Text(employee['department'], style: const TextStyle(color: Colors.white70)),
              ],
            ),
            const SizedBox(height: 5),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 14, color: Colors.white70),
                const SizedBox(width: 5),
                Text('Ancienneté: ${employee['seniority']}', style: const TextStyle(color: Colors.white70)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getStatusColor(employee['status']).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    employee['status'],
                    style: TextStyle(
                      fontSize: 10,
                      color: _getStatusColor(employee['status']),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: Colors.white70),
          onSelected: (value) => _handleEmployeeAction(value, employee),
          itemBuilder: (BuildContext context) => [
            const PopupMenuItem(
              value: 'view',
              child: ListTile(
                leading: Icon(Icons.visibility, size: 20),
                title: Text('Voir le profil'),
                dense: true,
              ),
            ),
            const PopupMenuItem(
              value: 'edit',
              child: ListTile(
                leading: Icon(Icons.edit, size: 20),
                title: Text('Modifier'),
                dense: true,
              ),
            ),
            const PopupMenuItem(
              value: 'payroll',
              child: ListTile(
                leading: Icon(Icons.payment, size: 20),
                title: Text('Bulletin de paie'),
                dense: true,
              ),
            ),
            const PopupMenuItem(
              value: 'schedule',
              child: ListTile(
                leading: Icon(Icons.schedule, size: 20),
                title: Text('Planning'),
                dense: true,
              ),
            ),
            const PopupMenuItem(
              value: 'contact',
              child: ListTile(
                leading: Icon(Icons.phone, size: 20),
                title: Text('Contacter'),
                dense: true,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'présent':
      case 'actif':
        return Colors.green;
      case 'congés':
        return Colors.orange;
      case 'absent':
        return Colors.red;
      case 'suspendu':
        return Colors.grey;
      default:
        return Colors.blue;
    }
  }

  Color _getContractColor(String contractType) {
    switch (contractType.toLowerCase()) {
      case 'cdi':
        return Colors.green;
      case 'cdd':
        return Colors.orange;
      case 'consultant':
        return Colors.blue;
      case 'stage':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  void _handleEmployeeAction(String action, Map<String, dynamic> employee) {
    switch (action) {
      case 'view':
        _showEmployeeDetails(employee);
        break;
      case 'edit':
        _editEmployee(employee);
        break;
      case 'payroll':
        _showPayrollInfo(employee);
        break;
      case 'schedule':
        _showSchedule(employee);
        break;
      case 'contact':
        _contactEmployee(employee);
        break;
    }
  }

  void _showEmployeeDetails(Map<String, dynamic> employee) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Profil de ${employee['name']}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Poste: ${employee['position']}'),
            Text('Département: ${employee['department']}'),
            Text('Type de contrat: ${employee['contractType']}'),
            Text('Ancienneté: ${employee['seniority']}'),
            Text('Statut: ${employee['status']}'),
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
              // Navigation vers l'écran de détail complet
            },
            child: const Text('Voir détails'),
          ),
        ],
      ),
    );
  }

  void _editEmployee(Map<String, dynamic> employee) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Modification de ${employee['name']}')),
    );
  }

  void _showPayrollInfo(Map<String, dynamic> employee) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Bulletin de paie de ${employee['name']}')),
    );
  }

  void _showSchedule(Map<String, dynamic> employee) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Planning de ${employee['name']}')),
    );
  }

  void _contactEmployee(Map<String, dynamic> employee) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Contacter ${employee['name']}')),
    );
  }

  void _showBulkActions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Actions en lot',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.email),
              title: const Text('Envoyer bulletins de paie'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.description),
              title: const Text('Générer attestations'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.notifications),
              title: const Text('Envoyer notifications'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.file_download),
              title: const Text('Exporter données'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  // Données d'exemple des employés
  final List<Map<String, dynamic>> _employees = [
    {
      'name': 'Marie DUPONT',
      'position': 'Directrice Générale',
      'department': 'Direction',
      'contractType': 'CDI',
      'seniority': '8 ans',
      'status': 'Présent',
      'photo': null,
    },
    {
      'name': 'Paul MARTIN',
      'position': 'Responsable RH',
      'department': 'Administration',
      'contractType': 'CDI',
      'seniority': '5 ans',
      'status': 'Congés',
      'photo': null,
    },
    {
      'name': 'Sophie DURAND',
      'position': 'Directrice Pédagogique',
      'department': 'Pédagogie',
      'contractType': 'CDI',
      'seniority': '6 ans',
      'status': 'Présent',
      'photo': null,
    },
    {
      'name': 'Jean MICHEL',
      'position': 'Directeur Commercial',
      'department': 'Commercial',
      'contractType': 'CDI',
      'seniority': '4 ans',
      'status': 'Présent',
      'photo': null,
    },
    {
      'name': 'Aminata TRAORE',
      'position': 'Formatrice Senior',
      'department': 'Pédagogie',
      'contractType': 'CDI',
      'seniority': '3 ans',
      'status': 'Présent',
      'photo': null,
    },
    {
      'name': 'Moussa KONE',
      'position': 'Commercial Junior',
      'department': 'Commercial',
      'contractType': 'CDD',
      'seniority': '1 an',
      'status': 'Absent',
      'photo': null,
    },
    {
      'name': 'Fatou DIALLO',
      'position': 'Secrétaire',
      'department': 'Administration',
      'contractType': 'CDI',
      'seniority': '2 ans',
      'status': 'Présent',
      'photo': null,
    },
    {
      'name': 'Ibrahim SAWADOGO',
      'position': 'Technicien IT',
      'department': 'Technique',
      'contractType': 'Consultant',
      'seniority': '6 mois',
      'status': 'Présent',
      'photo': null,
    },
  ];
}
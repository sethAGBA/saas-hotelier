// main.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

void main() {
  runApp(const HotelManagementApp());
}

class HotelManagementApp extends StatelessWidget {
  const HotelManagementApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gestion Hôtelière',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
      ),
      home: const MainScreen(),
    );
  }
}

// ============================================================================
// ÉCRAN PRINCIPAL AVEC NAVIGATION
// ============================================================================
class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  bool _isExpanded = true;

  final List<NavigationItem> _navItems = [
    NavigationItem(
      icon: Icons.dashboard,
      label: 'Tableau de Bord',
      screen: const DashboardScreen(),
    ),
    NavigationItem(
      icon: Icons.calendar_today,
      label: 'Réservations',
      screen: const ReservationsScreen(),
    ),
    NavigationItem(
      icon: Icons.meeting_room,
      label: 'Chambres',
      screen: const ChambresScreen(),
    ),
    NavigationItem(
      icon: Icons.people,
      label: 'Clients',
      screen: const ClientsScreen(),
    ),
    NavigationItem(
      icon: Icons.login,
      label: 'Check-In / Check-Out',
      screen: const CheckInOutScreen(),
    ),
    NavigationItem(
      icon: Icons.receipt_long,
      label: 'Facturation',
      screen: const FacturationScreen(),
    ),
    NavigationItem(
      icon: Icons.cleaning_services,
      label: 'Entretien',
      screen: const HousekeepingScreen(),
    ),
    NavigationItem(
      icon: Icons.bar_chart,
      label: 'Reporting',
      screen: const ReportingScreen(),
    ),
    NavigationItem(
      icon: Icons.settings,
      label: 'Paramètres',
      screen: const SettingsScreen(),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // SIDEBAR
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: _isExpanded ? 250 : 70,
            child: NavigationRail(
              extended: _isExpanded,
              selectedIndex: _selectedIndex,
              onDestinationSelected: (index) {
                setState(() => _selectedIndex = index);
              },
              leading: Column(
                children: [
                  const SizedBox(height: 20),
                  _isExpanded
                      ? const Text(
                          'HÔTEL SAAS',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : const Icon(Icons.hotel, size: 32),
                  const SizedBox(height: 20),
                  IconButton(
                    icon: Icon(
                      _isExpanded ? Icons.chevron_left : Icons.chevron_right,
                    ),
                    onPressed: () {
                      setState(() => _isExpanded = !_isExpanded);
                    },
                  ),
                  const Divider(),
                ],
              ),
              destinations: _navItems
                  .map(
                    (item) => NavigationRailDestination(
                      icon: Icon(item.icon),
                      label: Text(item.label),
                    ),
                  )
                  .toList(),
            ),
          ),
          const VerticalDivider(thickness: 1, width: 1),

          // CONTENU PRINCIPAL
          Expanded(child: _navItems[_selectedIndex].screen),
        ],
      ),
    );
  }
}

class NavigationItem {
  final IconData icon;
  final String label;
  final Widget screen;

  NavigationItem({
    required this.icon,
    required this.label,
    required this.screen,
  });
}

// ============================================================================
// TABLEAU DE BORD
// ============================================================================
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // APP BAR
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border(
              bottom: BorderSide(color: Theme.of(context).dividerColor),
            ),
          ),
          child: Row(
            children: [
              const Text(
                'Tableau de Bord',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Text(
                DateFormat('EEEE d MMMM yyyy', 'fr_FR').format(DateTime.now()),
              ),
              const SizedBox(width: 16),
              IconButton(
                icon: const Icon(Icons.notifications),
                onPressed: () {},
              ),
              const SizedBox(width: 8),
              const CircleAvatar(child: Icon(Icons.person)),
            ],
          ),
        ),

        // CONTENU
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // STATISTIQUES PRINCIPALES
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        title: 'Taux d\'Occupation',
                        value: '78%',
                        icon: Icons.hotel,
                        color: Colors.blue,
                        subtitle: '42 chambres occupées',
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _StatCard(
                        title: 'Chiffre d\'Affaires',
                        value: '2.4M FCFA',
                        icon: Icons.attach_money,
                        color: Colors.green,
                        subtitle: 'Aujourd\'hui',
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _StatCard(
                        title: 'Arrivées du Jour',
                        value: '12',
                        icon: Icons.flight_land,
                        color: Colors.orange,
                        subtitle: '8 déjà check-in',
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _StatCard(
                        title: 'Départs du Jour',
                        value: '9',
                        icon: Icons.flight_takeoff,
                        color: Colors.red,
                        subtitle: '6 déjà check-out',
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // SYNOPTIQUE CHAMBRES
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'État des Chambres',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            _RoomStatusChip('Disponibles', 12, Colors.green),
                            _RoomStatusChip('Occupées', 42, Colors.red),
                            _RoomStatusChip('Sales', 8, Colors.orange),
                            _RoomStatusChip('En Nettoyage', 4, Colors.blue),
                            _RoomStatusChip('Maintenance', 2, Colors.grey),
                            _RoomStatusChip('Réservées', 6, Colors.purple),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ARRIVÉES DU JOUR
                    Expanded(
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.flight_land,
                                    color: Colors.blue,
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Arrivées du Jour',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              ...[
                                _ArrivalItem(
                                  'Jean Dupont',
                                  '101',
                                  '14h00',
                                  true,
                                ),
                                _ArrivalItem(
                                  'Marie Martin',
                                  '205',
                                  '15h30',
                                  true,
                                ),
                                _ArrivalItem(
                                  'Ahmed Diallo',
                                  '312',
                                  '16h00',
                                  false,
                                ),
                                _ArrivalItem(
                                  'Sophie Koné',
                                  '108',
                                  '17h00',
                                  false,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 16),

                    // ALERTES
                    Expanded(
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.warning,
                                    color: Colors.orange,
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Alertes',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              _AlertItem(
                                'Impayé',
                                'Client Ch. 405 - Facture en attente',
                                Colors.red,
                              ),
                              _AlertItem(
                                'Maintenance',
                                'Climatisation Ch. 210 en panne',
                                Colors.orange,
                              ),
                              _AlertItem(
                                'Stock',
                                'Stock minibar bas (< 20%)',
                                Colors.amber,
                              ),
                              _AlertItem(
                                'Overbooking',
                                'Risque sur catégorie Deluxe',
                                Colors.red,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String subtitle;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const Spacer(),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoomStatusChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _RoomStatusChip(this.label, this.count, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            '$label ($count)',
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _ArrivalItem extends StatelessWidget {
  final String name;
  final String room;
  final String time;
  final bool checkedIn;

  const _ArrivalItem(this.name, this.room, this.time, this.checkedIn);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Row(
        children: [
          Icon(
            checkedIn ? Icons.check_circle : Icons.schedule,
            color: checkedIn ? Colors.green : Colors.grey,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(
                  'Ch. $room - $time',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AlertItem extends StatelessWidget {
  final String title;
  final String description;
  final Color color;

  const _AlertItem(this.title, this.description, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.warning, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontWeight: FontWeight.bold, color: color),
                ),
                Text(description, style: const TextStyle(fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// ÉCRAN RÉSERVATIONS
// ============================================================================
class ReservationsScreen extends StatelessWidget {
  const ReservationsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildAppBar(context, 'Réservations'),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // FILTRES ET RECHERCHE
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Rechercher par nom, numéro...',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    FilterChip(
                      label: const Text('Aujourd\'hui'),
                      onSelected: (value) {},
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: const Text('Cette semaine'),
                      onSelected: (value) {},
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: const Text('Confirmées'),
                      selected: true,
                      onSelected: (value) {},
                    ),
                    const Spacer(),
                    ElevatedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.add),
                      label: const Text('Nouvelle Réservation'),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // TABLEAU RÉSERVATIONS
                Expanded(
                  child: Card(
                    child: SingleChildScrollView(
                      child: DataTable(
                        columns: const [
                          DataColumn(label: Text('N° Réservation')),
                          DataColumn(label: Text('Client')),
                          DataColumn(label: Text('Arrivée')),
                          DataColumn(label: Text('Départ')),
                          DataColumn(label: Text('Chambre')),
                          DataColumn(label: Text('Statut')),
                          DataColumn(label: Text('Montant')),
                          DataColumn(label: Text('Actions')),
                        ],
                        rows: [
                          _buildReservationRow(
                            'RES-2024-001',
                            'Jean Dupont',
                            '06/10/2024',
                            '08/10/2024',
                            '101 - Standard',
                            'Confirmée',
                            '45 000 FCFA',
                          ),
                          _buildReservationRow(
                            'RES-2024-002',
                            'Marie Martin',
                            '06/10/2024',
                            '10/10/2024',
                            '205 - Deluxe',
                            'Confirmée',
                            '120 000 FCFA',
                          ),
                          _buildReservationRow(
                            'RES-2024-003',
                            'Ahmed Diallo',
                            '07/10/2024',
                            '09/10/2024',
                            '312 - Suite',
                            'Provisoire',
                            '80 000 FCFA',
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  DataRow _buildReservationRow(
    String numero,
    String client,
    String arrivee,
    String depart,
    String chambre,
    String statut,
    String montant,
  ) {
    Color statusColor = statut == 'Confirmée' ? Colors.green : Colors.orange;

    return DataRow(
      cells: [
        DataCell(Text(numero)),
        DataCell(Text(client)),
        DataCell(Text(arrivee)),
        DataCell(Text(depart)),
        DataCell(Text(chambre)),
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              statut,
              style: TextStyle(color: statusColor, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        DataCell(Text(montant)),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.visibility, size: 20),
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(Icons.edit, size: 20),
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                onPressed: () {},
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// ÉCRAN CHAMBRES
// ============================================================================
class ChambresScreen extends StatelessWidget {
  const ChambresScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildAppBar(context, 'Gestion des Chambres'),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                childAspectRatio: 1.2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: 20,
              itemBuilder: (context, index) {
                return _RoomCard(
                  roomNumber: '${100 + index}',
                  category: index % 3 == 0 ? 'Deluxe' : 'Standard',
                  status: _getRoomStatus(index),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  String _getRoomStatus(int index) {
    switch (index % 6) {
      case 0:
        return 'Disponible';
      case 1:
      case 2:
        return 'Occupée';
      case 3:
        return 'Sale';
      case 4:
        return 'Nettoyage';
      default:
        return 'Maintenance';
    }
  }
}

class _RoomCard extends StatelessWidget {
  final String roomNumber;
  final String category;
  final String status;

  const _RoomCard({
    required this.roomNumber,
    required this.category,
    required this.status,
  });

  Color _getStatusColor() {
    switch (status) {
      case 'Disponible':
        return Colors.green;
      case 'Occupée':
        return Colors.red;
      case 'Sale':
        return Colors.orange;
      case 'Nettoyage':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon() {
    switch (status) {
      case 'Disponible':
        return Icons.check_circle;
      case 'Occupée':
        return Icons.person;
      case 'Sale':
        return Icons.cleaning_services;
      case 'Nettoyage':
        return Icons.refresh;
      default:
        return Icons.build;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor();

    return Card(
      elevation: 2,
      child: InkWell(
        onTap: () {},
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border(left: BorderSide(color: statusColor, width: 4)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Ch. $roomNumber',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Icon(_getStatusIcon(), color: statusColor),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category,
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// AUTRES ÉCRANS (PLACEHOLDERS)
// ============================================================================
class ClientsScreen extends StatelessWidget {
  const ClientsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildAppBar(context, 'Gestion des Clients'),
        const Expanded(
          child: Center(child: Text('Module Clients en développement')),
        ),
      ],
    );
  }
}

class CheckInOutScreen extends StatelessWidget {
  const CheckInOutScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildAppBar(context, 'Check-In / Check-Out'),
        const Expanded(
          child: Center(child: Text('Module Check-In/Out en développement')),
        ),
      ],
    );
  }
}

class FacturationScreen extends StatelessWidget {
  const FacturationScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildAppBar(context, 'Facturation & Caisse'),
        const Expanded(
          child: Center(child: Text('Module Facturation en développement')),
        ),
      ],
    );
  }
}

class HousekeepingScreen extends StatelessWidget {
  const HousekeepingScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildAppBar(context, 'Entretien & Housekeeping'),
        const Expanded(
          child: Center(child: Text('Module Housekeeping en développement')),
        ),
      ],
    );
  }
}

class ReportingScreen extends StatelessWidget {
  const ReportingScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildAppBar(context, 'Reporting & Analyses'),
        const Expanded(
          child: Center(child: Text('Module Reporting en développement')),
        ),
      ],
    );
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildAppBar(context, 'Paramètres'),
        const Expanded(
          child: Center(child: Text('Module Paramètres en développement')),
        ),
      ],
    );
  }
}

// ============================================================================
// COMPOSANTS RÉUTILISABLES
// ============================================================================
Widget _buildAppBar(BuildContext context, String title) {
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor)),
    ),
    child: Row(
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const Spacer(),
        Text(DateFormat('EEEE d MMMM yyyy', 'fr_FR').format(DateTime.now())),
        const SizedBox(width: 16),
        IconButton(icon: const Icon(Icons.notifications), onPressed: () {}),
        const SizedBox(width: 8),
        const CircleAvatar(child: Icon(Icons.person)),
      ],
    ),
  );
}

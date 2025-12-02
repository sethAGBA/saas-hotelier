import 'package:flutter/material.dart';

import '../data/local_database.dart';
import 'reservations/new_reservation_screen.dart';
import 'reservations/reservations_list_screen.dart';
import 'reservations/planning_reservations_screen.dart';
import 'reservations/disponibilites_screen.dart';
import 'reservations/annulations_screen.dart';
import 'checkin_checkout/checkin_screen.dart';
import 'checkin_checkout/checkout_screen.dart';
import 'analytics/analytics_screen.dart';
import 'front_office/changements_screen.dart';
import 'services/services_screens.dart';
import 'settings/parametres_screen.dart';
import 'maintenance/maintenance_screen.dart';
import 'finance/finance_screens.dart';
import 'clients/base_clients_screen.dart';
import 'clients/nouveau_client_screen.dart';
import 'clients/fidelite_screen.dart';
import 'clients/clients_vip_screen.dart';
import 'clients/corporate_screen.dart';
import 'housekeeping/entretien_screen.dart';
import '../navigation/navigation_models.dart';
import '../widgets/futuristic_app_bar.dart';
import '../widgets/futuristic_room_status_chip.dart';
import 'chambres/chambres_screen.dart';
import 'placeholder_screen.dart';
import 'dashboard_screen.dart';
import 'logout_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with TickerProviderStateMixin {
  int _selectedIndex = 0;
  bool _isExpanded = true;
  late AnimationController _glowController;

  final List<NavigationSection> _sections = [
    NavigationSection(
      title: 'DASHBOARD',
      items: [
        NavigationItem(
          icon: Icons.dashboard_rounded,
          label: 'Vue d\'ensemble',
          screen: const DashboardScreen(),
          gradient: const LinearGradient(
            colors: [Color(0xFF667eea), Color(0xFF764ba2)],
          ),
        ),
        NavigationItem(
          icon: Icons.insights_rounded,
          label: 'Analytics',
          screen: const AnalyticsScreen(),
          gradient: const LinearGradient(
            colors: [Color(0xFFf093fb), Color(0xFff5576c)],
          ),
        ),
        NavigationItem(
          icon: Icons.bar_chart_rounded,
          label: 'Reporting',
          screen: const ReportingScreen(),
          gradient: const LinearGradient(
            colors: [Color(0xFFf093fb), Color(0xFff5576c)],
          ),
        ),
      ],
    ),
    NavigationSection(
      title: 'RÉSERVATIONS',
      items: [
        NavigationItem(
          icon: Icons.calendar_today_rounded,
          label: 'Planning',
          screen: const PlanningReservationsScreen(),
          gradient: const LinearGradient(
            colors: [Color(0xFF4facfe), Color(0xFF00f2fe)],
          ),
        ),
        NavigationItem(
          icon: Icons.add_circle_rounded,
          label: 'Nouvelle Réservation',
          screen: const NewReservationScreen(),
          gradient: const LinearGradient(
            colors: [Color(0xFF43e97b), Color(0xFF38f9d7)],
          ),
        ),
        NavigationItem(
          icon: Icons.list_alt_rounded,
          label: 'Liste Réservations',
          screen: const ReservationsListScreen(),
          gradient: const LinearGradient(
            colors: [Color(0xFFfa709a), Color(0xFFfee140)],
          ),
        ),
        NavigationItem(
          icon: Icons.event_available_rounded,
          label: 'Disponibilités',
          screen: const DisponibilitesScreen(),
          gradient: const LinearGradient(
            colors: [Color(0xFF30cfd0), Color(0xFF330867)],
          ),
        ),
        NavigationItem(
          icon: Icons.cancel_rounded,
          label: 'Annulations',
          screen: const AnnulationsScreen(),
          gradient: const LinearGradient(
            colors: [Color(0xFFa8edea), Color(0xFFfed6e3)],
          ),
        ),
      ],
    ),
    NavigationSection(
      title: 'FRONT OFFICE',
      items: [
        NavigationItem(
          icon: Icons.login_rounded,
          label: 'Check-In',
          screen: const CheckInScreen(),
          gradient: const LinearGradient(
            colors: [Color(0xFFff9a9e), Color(0xFFfecfef)],
          ),
        ),
        NavigationItem(
          icon: Icons.logout_rounded,
          label: 'Check-Out',
          screen: const CheckOutScreen(),
          gradient: const LinearGradient(
            colors: [Color(0xFFffecd2), Color(0xFFfcb69f)],
          ),
        ),
        NavigationItem(
          icon: Icons.meeting_room_rounded,
          label: 'Gestion Chambres',
          screen: const ChambresScreen(),
          gradient: const LinearGradient(
            colors: [Color(0xFFa1c4fd), Color(0xFFc2e9fb)],
          ),
        ),
        NavigationItem(
          icon: Icons.swap_horiz_rounded,
          label: 'Changements',
          screen: const ChangementsScreen(),
          gradient: const LinearGradient(
            colors: [Color(0xFFd299c2), Color(0xFFfef9d7)],
          ),
        ),
        NavigationItem(
          icon: Icons.vpn_key_rounded,
          label: 'Gestion Clés',
          screen: const GestionClesScreen(),
          gradient: const LinearGradient(
            colors: [Color(0xFFfbc2eb), Color(0xFFa6c1ee)],
          ),
        ),
      ],
    ),
    NavigationSection(
      title: 'CLIENTS',
      items: [
        NavigationItem(
          icon: Icons.people_rounded,
          label: 'Base Clients',
          screen: const BaseClientsScreen(),
          gradient: const LinearGradient(
            colors: [Color(0xFFfdcbf1), Color(0xFFe6dee9)],
          ),
        ),
        NavigationItem(
          icon: Icons.person_add_rounded,
          label: 'Nouveau Client',
          screen: const NouveauClientScreen(),
          gradient: const LinearGradient(
            colors: [Color(0xFFa1ffce), Color(0xFFfaffd1)],
          ),
        ),
        NavigationItem(
          icon: Icons.card_giftcard_rounded,
          label: 'Fidélité',
          screen: const FideliteScreen(),
          gradient: const LinearGradient(
            colors: [Color(0xFFffd3a5), Color(0xFFfd6585)],
          ),
        ),
        NavigationItem(
          icon: Icons.star_rounded,
          label: 'Clients VIP',
          screen: const ClientsVipScreen(),
          gradient: const LinearGradient(
            colors: [Color(0xFFffe985), Color(0xFFfa742b)],
          ),
        ),
        NavigationItem(
          icon: Icons.business_rounded,
          label: 'Corporate',
          screen: const CorporateScreen(),
          gradient: const LinearGradient(
            colors: [Color(0xFFffeaa7), Color(0xFFef5350)],
          ),
        ),
      ],
    ),
    NavigationSection(
      title: 'FINANCE',
      items: [
        NavigationItem(
          icon: Icons.receipt_long_rounded,
          label: 'Facturation',
          screen: const FacturationScreen(),
          gradient: const LinearGradient(
            colors: [Color(0xFF89f7fe), Color(0xFF66a6ff)],
          ),
        ),
        NavigationItem(
          icon: Icons.point_of_sale_rounded,
          label: 'Caisse',
          screen: const CaisseScreen(),
          gradient: const LinearGradient(
            colors: [Color(0xFFfddb92), Color(0xFFd1fdff)],
          ),
        ),
        NavigationItem(
          icon: Icons.payments_rounded,
          label: 'Encaissements',
          screen: const EncaissementsScreen(),
          gradient: const LinearGradient(
            colors: [Color(0xFF9890e3), Color(0xFFb1f4cf)],
          ),
        ),
        NavigationItem(
          icon: Icons.account_balance_rounded,
          label: 'Comptabilité',
          screen: const ComptabiliteScreen(),
          gradient: const LinearGradient(
            colors: [Color(0xFFebc0fd), Color(0xFFd9ded8)],
          ),
        ),
        NavigationItem(
          icon: Icons.warning_rounded,
          label: 'Impayés',
          screen: const ImpayesScreen(),
          gradient: const LinearGradient(
            colors: [Color(0xFFf77062), Color(0xFFfe5196)],
          ),
        ),
        NavigationItem(
          icon: Icons.account_balance_wallet_rounded,
          label: 'Dépenses',
          screen: const DepensesScreen(),
          gradient: const LinearGradient(
            colors: [Color(0xFFc471f5), Color(0xFFfa71cd)],
          ),
        ),
      ],
    ),
    NavigationSection(
      title: 'SERVICES',
      items: [
        NavigationItem(
          icon: Icons.restaurant_rounded,
          label: 'Restaurant',
          screen: const RestaurantScreen(),
          gradient: const LinearGradient(
            colors: [Color(0xFF7F7FD5), Color(0xFF91EAE4)],
          ),
        ),
        NavigationItem(
          icon: Icons.local_bar_rounded,
          label: 'Bar',
          screen: const BarScreen(),
          gradient: const LinearGradient(
            colors: [Color(0xFFe14fad), Color(0xFFf9d423)],
          ),
        ),
        NavigationItem(
          icon: Icons.room_service_rounded,
          label: 'Room Service',
          screen: const RoomServiceScreen(),
          gradient: const LinearGradient(
            colors: [Color(0xFF734b6d), Color(0xFF42275a)],
          ),
        ),
        NavigationItem(
          icon: Icons.cleaning_services_rounded,
          label: 'Entretien',
          screen: const EntretienScreen(),
          gradient: const LinearGradient(
            colors: [Color(0xFF89f7fe), Color(0xFF66a6ff)],
          ),
        ),
      ],
    ),
    NavigationSection(
      title: 'MAINTENANCE',
      items: [
        NavigationItem(
          icon: Icons.build_rounded,
          label: 'Maintenance',
          screen: const MaintenanceScreen(),
          gradient: const LinearGradient(
            colors: [Color(0xFFff9a9e), Color(0xFFfecfef)],
          ),
        ),
        NavigationItem(
          icon: Icons.inventory_2_rounded,
          label: 'Inventaire',
          screen: const InventoryScreen(),
          gradient: const LinearGradient(
            colors: [Color(0xFFa18cd1), Color(0xFFfbc2eb)],
          ),
        ),
      ],
    ),
    NavigationSection(
      title: 'PARAMÈTRES',
      items: [
        NavigationItem(
          icon: Icons.settings_rounded,
          label: 'Paramètres',
          screen: const ParametresScreen(),
          gradient: const LinearGradient(
            colors: [Color(0xFFa1ffce), Color(0xFFfaffd1)],
          ),
        ),
      ],
    ),
    NavigationSection(
      title: 'COMPTE',
      items: [
        NavigationItem(
          icon: Icons.logout_rounded,
          label: 'Déconnexion',
          screen: const LogoutScreen(),
          gradient: const LinearGradient(
            colors: [Color(0xFFff758c), Color(0xFFff7eb3)],
          ),
        ),
      ],
    ),
  ];

  List<NavigationItem> get _flattenedItems {
    return _sections.expand((section) => section.items).toList();
  }

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E),
      body: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            width: _isExpanded ? 300 : 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF1A1A2E).withOpacity(0.95),
                  const Color(0xFF16213E).withOpacity(0.95),
                ],
              ),
              border: Border(
                right: BorderSide(
                  color: const Color(0xFF6C63FF).withOpacity(0.3),
                  width: 1,
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6C63FF).withOpacity(0.1),
                  blurRadius: 30,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  height: 100,
                  padding: const EdgeInsets.all(20),
                  child: AnimatedBuilder(
                    animation: _glowController,
                    builder: (context, child) {
                      return Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: LinearGradient(
                            colors: [
                              Color(
                                0xFF6C63FF,
                              ).withOpacity(0.3 + _glowController.value * 0.3),
                              Color(
                                0xFF5A52D5,
                              ).withOpacity(0.2 + _glowController.value * 0.2),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xFF6C63FF,
                              ).withOpacity(0.3 * _glowController.value),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Center(
                          child: _isExpanded
                              ? Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: const Color(
                                            0xFF6C63FF,
                                          ).withOpacity(0.8),
                                          width: 2,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(
                                              0xFF6C63FF,
                                            ).withOpacity(0.3),
                                            blurRadius: 10,
                                          ),
                                        ],
                                      ),
                                      child: const Icon(
                                        Icons.hotel_rounded,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    const Text(
                                      'ROOMMASTER',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 2,
                                      ),
                                    ),
                                  ],
                                )
                              : const Icon(
                                  Icons.hotel_rounded,
                                  color: Colors.white,
                                ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: InkWell(
                    onTap: () {
                      setState(() => _isExpanded = !_isExpanded);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF6C63FF).withOpacity(0.2),
                            const Color(0xFF5A52D5).withOpacity(0.2),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF6C63FF).withOpacity(0.3),
                        ),
                      ),
                      child: Icon(
                        _isExpanded
                            ? Icons.chevron_left_rounded
                            : Icons.chevron_right_rounded,
                        color: const Color(0xFF6C63FF),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: _sections.length,
                    itemBuilder: (context, sectionIndex) {
                      final section = _sections[sectionIndex];
                      return _buildSection(section, sectionIndex);
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(child: _flattenedItems[_selectedIndex].screen),
        ],
      ),
    );
  }

  Widget _buildSection(NavigationSection section, int sectionIndex) {
    int itemOffset = _sections
        .take(sectionIndex)
        .fold(0, (sum, s) => sum + s.items.length);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_isExpanded)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 20, 12, 12),
            child: Text(
              section.title,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF6C63FF).withOpacity(0.7),
                letterSpacing: 2,
              ),
            ),
          ),
        ...section.items.asMap().entries.map((entry) {
          final index = itemOffset + entry.key;
          final item = entry.value;
          final isSelected = _selectedIndex == index;

          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: InkWell(
              onTap: () {
                setState(() => _selectedIndex = index);
              },
              borderRadius: BorderRadius.circular(16),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: EdgeInsets.symmetric(
                  horizontal: _isExpanded ? 16 : 0,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? item.gradient
                      : const LinearGradient(
                          colors: [Colors.transparent, Colors.transparent],
                        ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: item.gradient.colors.first.withOpacity(0.4),
                            blurRadius: 20,
                            spreadRadius: 0,
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  children: [
                    if (!_isExpanded) const Spacer(),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.white.withOpacity(0.15)
                            : Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(item.icon, color: Colors.white, size: 20),
                    ),
                    if (_isExpanded) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          item.label,
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : Colors.white.withOpacity(0.6),
                            fontSize: 14,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: isSelected
                            ? Colors.white
                            : Colors.white.withOpacity(0.6),
                        size: 18,
                      ),
                    ],
                    if (!_isExpanded) const Spacer(),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ],
    );
  }
}

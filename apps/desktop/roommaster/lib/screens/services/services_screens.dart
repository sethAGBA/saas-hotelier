import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../data/local_database.dart';

class RestaurantScreen extends StatefulWidget {
  const RestaurantScreen({super.key});

  @override
  State<RestaurantScreen> createState() => _RestaurantScreenState();
}

class _RestaurantScreenState extends State<RestaurantScreen> {
  late Future<List<String>> _future;
  final _newServiceController = TextEditingController();
  String _search = '';

  @override
  void initState() {
    super.initState();
    _future = LocalDatabase.instance.fetchServices();
  }

  @override
  void dispose() {
    _newServiceController.dispose();
    super.dispose();
  }

  Future<void> _addService() async {
    final name = _newServiceController.text.trim();
    if (name.isEmpty) return;
    await LocalDatabase.instance.addService(name);
    _newServiceController.clear();
    setState(() {
      _future = LocalDatabase.instance.fetchServices();
    });
  }

  Future<void> _deleteService(String name) async {
    await LocalDatabase.instance.deleteService(name);
    setState(() {
      _future = LocalDatabase.instance.fetchServices();
    });
  }

  Future<void> _editService(String name) async {
    final controller = TextEditingController(text: name);
    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('Renommer', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Nom du service',
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
            ),
            focusedBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
              borderSide: BorderSide(color: Color(0xFF6C63FF)),
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          TextButton(onPressed: () => Navigator.pop(ctx, controller.text.trim()), child: const Text('Enregistrer')),
        ],
      ),
    );
    if (newName == null || newName.isEmpty || newName == name) return;
    await LocalDatabase.instance.addService(newName);
    await LocalDatabase.instance.deleteService(name);
    setState(() {
      _future = LocalDatabase.instance.fetchServices();
    });
  }

  @override
  Widget build(BuildContext context) {
    return _ServiceScaffold(
      title: 'Restaurant',
      subtitle: 'Carte & commandes',
      child: FutureBuilder<List<String>>(
        future: _future,
        builder: (context, snapshot) {
          final services = snapshot.data ?? [];
          final filtered = services.where((s) => s.toLowerCase().contains(_search.toLowerCase())).toList();
          final items = services.isEmpty
              ? _sampleMenu()
              : filtered.map((e) => {'name': e, 'description': 'Service personnalisé', 'price': 0}).toList();
          return Column(
            children: [
              _AddServiceForm(
                controller: _newServiceController,
                onAdd: _addService,
                hint: 'Ajouter un plat ou service',
                onSearch: (v) => setState(() => _search = v),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: _MenuList(
                  items: items,
                  onDelete: _deleteService,
                  onEdit: _editService,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class BarScreen extends StatefulWidget {
  const BarScreen({super.key});

  @override
  State<BarScreen> createState() => _BarScreenState();
}

class _BarScreenState extends State<BarScreen> {
  late Future<List<String>> _future;
  final _newServiceController = TextEditingController();
  String _search = '';

  @override
  void initState() {
    super.initState();
    _future = LocalDatabase.instance.fetchServices();
  }

  @override
  void dispose() {
    _newServiceController.dispose();
    super.dispose();
  }

  Future<void> _addService() async {
    final name = _newServiceController.text.trim();
    if (name.isEmpty) return;
    await LocalDatabase.instance.addService(name);
    _newServiceController.clear();
    setState(() {
      _future = LocalDatabase.instance.fetchServices();
    });
  }

  Future<void> _deleteService(String name) async {
    await LocalDatabase.instance.deleteService(name);
    setState(() {
      _future = LocalDatabase.instance.fetchServices();
    });
  }

  Future<void> _editService(String name) async {
    final controller = TextEditingController(text: name);
    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('Renommer', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Nom du service',
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
            ),
            focusedBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
              borderSide: BorderSide(color: Color(0xFF6C63FF)),
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          TextButton(onPressed: () => Navigator.pop(ctx, controller.text.trim()), child: const Text('Enregistrer')),
        ],
      ),
    );
    if (newName == null || newName.isEmpty || newName == name) return;
    await LocalDatabase.instance.addService(newName);
    await LocalDatabase.instance.deleteService(name);
    setState(() {
      _future = LocalDatabase.instance.fetchServices();
    });
  }

  @override
  Widget build(BuildContext context) {
    return _ServiceScaffold(
      title: 'Bar',
      subtitle: 'Boissons & encaissements',
      child: FutureBuilder<List<String>>(
        future: _future,
        builder: (context, snapshot) {
          final services = snapshot.data ?? [];
          final filtered = services.where((s) => s.toLowerCase().contains(_search.toLowerCase())).toList();
          final items = services.isEmpty
              ? _sampleMenu(drinks: true)
              : filtered.map((e) => {'name': e, 'description': 'Service bar', 'price': 0}).toList();
          return Column(
            children: [
              _AddServiceForm(
                controller: _newServiceController,
                onAdd: _addService,
                hint: 'Ajouter une boisson ou un service',
                onSearch: (v) => setState(() => _search = v),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: _MenuList(
                  items: items,
                  onDelete: _deleteService,
                  onEdit: _editService,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class RoomServiceScreen extends StatefulWidget {
  const RoomServiceScreen({super.key});

  @override
  State<RoomServiceScreen> createState() => _RoomServiceScreenState();
}

class _RoomServiceScreenState extends State<RoomServiceScreen> {
  final _roomController = TextEditingController();
  String? _selectedService;
  List<Map<String, String>> _orders = [];
  late Future<List<String>> _future;

  @override
  void initState() {
    super.initState();
    _future = LocalDatabase.instance.fetchServices();
  }

  @override
  void dispose() {
    _roomController.dispose();
    super.dispose();
  }

  void _addOrder(List<String> services) {
    if (_roomController.text.trim().isEmpty || _selectedService == null) return;
    setState(() {
      _orders = List.from(_orders)
        ..add({
          'room': _roomController.text.trim(),
          'item': _selectedService!,
          'status': 'En cours',
        });
      _roomController.clear();
      _selectedService = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return _ServiceScaffold(
      title: 'Room Service',
      subtitle: 'Suivi des commandes',
      child: FutureBuilder<List<String>>(
        future: _future,
        builder: (context, snapshot) {
          final services = snapshot.data ?? [];
          final options = services.isEmpty ? _sampleMenu().map((e) => e['name'] as String).toList() : services;
          return Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.03),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Nouvelle commande', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _roomController,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: 'Chambre',
                              hintStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                              ),
                              focusedBorder: const OutlineInputBorder(
                                borderRadius: BorderRadius.all(Radius.circular(12)),
                                borderSide: BorderSide(color: Color(0xFF6C63FF)),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _selectedService,
                            dropdownColor: const Color(0xFF1A1A2E),
                            decoration: InputDecoration(
                              hintText: 'Service',
                              hintStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
                              filled: true,
                              fillColor: Colors.white.withOpacity(0.03),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                              ),
                              focusedBorder: const OutlineInputBorder(
                                borderRadius: BorderRadius.all(Radius.circular(12)),
                                borderSide: BorderSide(color: Color(0xFF6C63FF)),
                              ),
                            ),
                            items: options
                                .map((s) => DropdownMenuItem(
                                      value: s,
                                      child: Text(s),
                                    ))
                                .toList(),
                            onChanged: (v) => setState(() => _selectedService = v),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton.icon(
                        onPressed: () => _addOrder(options),
                        icon: const Icon(Icons.add),
                        label: const Text('Ajouter'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6C63FF),
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: _orders.isEmpty
                    ? const Center(child: Text('Aucune commande', style: TextStyle(color: Colors.white70)))
                    : ListView.separated(
                        itemCount: _orders.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final o = _orders[index];
                          return _ServiceCard(
                            title: 'Ch. ${o['room']}',
                            subtitle: o['item'] ?? '',
                            status: o['status'] ?? '',
                            color: (o['status'] == 'Livré') ? Colors.greenAccent : Colors.orangeAccent,
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ServiceScaffold extends StatelessWidget {
  const _ServiceScaffold({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF7F7FD5), Color(0xFF91EAE4)],
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.restaurant_menu_rounded, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(color: Colors.white.withOpacity(0.7)),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(child: child),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuList extends StatelessWidget {
  const _MenuList({required this.items, this.onDelete, this.onEdit});

  final List<Map<String, dynamic>> items;
  final ValueChanged<String>? onDelete;
  final ValueChanged<String>? onEdit;

  @override
  Widget build(BuildContext context) {
    final money = NumberFormat.currency(locale: 'fr_FR', symbol: 'FCFA', decimalDigits: 0);
    return ListView.separated(
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final item = items[index];
        return _ServiceCard(
          title: item['name'] as String,
          subtitle: item['description'] as String,
          status: item['price'] == 0 ? 'Personnalisé' : money.format(item['price'] as num),
          color: Colors.blueAccent,
          trailing: onDelete != null || onEdit != null
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (onEdit != null)
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.white70),
                        onPressed: () => onEdit?.call(item['name'] as String),
                      ),
                    if (onDelete != null)
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                        onPressed: () => onDelete?.call(item['name'] as String),
                      ),
                  ],
                )
              : null,
        );
      },
    );
  }
}

class _ServiceCard extends StatelessWidget {
  const _ServiceCard({
    required this.title,
    required this.subtitle,
    required this.status,
    required this.color,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final String status;
  final Color color;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12),
                ),
              ],
            ),
          ),
          if (trailing != null)
            trailing!
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                status,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _AddServiceForm extends StatelessWidget {
  const _AddServiceForm({
    required this.controller,
    required this.onAdd,
    required this.hint,
    this.onSearch,
  });

  final TextEditingController controller;
  final VoidCallback onAdd;
  final String hint;
  final ValueChanged<String>? onSearch;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                  borderSide: BorderSide(color: Color(0xFF6C63FF)),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          ElevatedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: const Text('Ajouter'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6C63FF),
              foregroundColor: Colors.white,
            ),
          ),
          if (onSearch != null) ...[
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                onChanged: onSearch,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Rechercher',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                    borderSide: BorderSide(color: Color(0xFF6C63FF)),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

List<Map<String, dynamic>> _sampleMenu({bool drinks = false}) {
  return drinks
      ? [
          {'name': 'Mojito', 'description': 'Menthe, citron vert, rhum', 'price': 3500},
          {'name': 'Bière locale', 'description': '33cl', 'price': 2000},
          {'name': 'Cocktail sans alcool', 'description': 'Fruits frais', 'price': 2500},
        ]
      : [
          {'name': 'Burger gourmet', 'description': 'Bœuf, cheddar, frites', 'price': 8500},
          {'name': 'Salade César', 'description': 'Poulet, parmesan, croûtons', 'price': 6500},
          {'name': 'Pâtes pesto', 'description': 'Basilic, parmesan, pignons', 'price': 7000},
        ];
}

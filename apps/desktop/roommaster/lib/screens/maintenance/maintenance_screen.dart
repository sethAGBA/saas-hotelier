import 'package:flutter/material.dart';

import '../../data/local_database.dart';

class MaintenanceScreen extends StatefulWidget {
  const MaintenanceScreen({super.key});

  @override
  State<MaintenanceScreen> createState() => _MaintenanceScreenState();
}

class _MaintenanceScreenState extends State<MaintenanceScreen> {
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = LocalDatabase.instance.getMaintenanceTickets();
  }

  Future<void> _reload() async {
    setState(() {
      _future = LocalDatabase.instance.getMaintenanceTickets();
    });
  }

  @override
  Widget build(BuildContext context) {
    return _MaintenanceScaffold(
      title: 'Maintenance',
      onAdd: () async {
        await _showTicketDialog(context);
        await _reload();
      },
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final tickets = snapshot.data ?? [];
          if (tickets.isEmpty) {
            return const Center(
              child: Text(
                'Aucun ticket pour le moment.',
                style: TextStyle(color: Colors.white70),
              ),
            );
          }
          return ListView.separated(
            itemCount: tickets.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final t = tickets[index];
              return _TicketCard(
                room: t['room'] as String? ?? '',
                title: t['title'] as String? ?? '',
                status: t['status'] as String? ?? '',
                priority: t['priority'] as String? ?? '',
                assigned: t['assigned'] as String? ?? '',
                onClose: () async {
                  await LocalDatabase.instance.updateMaintenanceTicket(
                    t['id'] as int,
                    status: 'Résolu',
                  );
                  await _reload();
                },
                onDelete: () async {
                  await LocalDatabase.instance
                      .deleteMaintenanceTicket(t['id'] as int);
                  await _reload();
                },
              );
            },
          );
        },
      ),
    );
  }
}

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = LocalDatabase.instance.getInventoryItems();
  }

  Future<void> _reload() async {
    setState(() {
      _future = LocalDatabase.instance.getInventoryItems();
    });
  }

  @override
  Widget build(BuildContext context) {
    return _MaintenanceScaffold(
      title: 'Inventaire',
      onAdd: () async {
        await _showInventoryDialog(context);
        await _reload();
      },
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = snapshot.data ?? [];
          if (items.isEmpty) {
            return const Center(
              child: Text(
                'Inventaire vide.',
                style: TextStyle(color: Colors.white70),
              ),
            );
          }
          return ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final item = items[index];
              final stock = (item['stock'] as int?) ?? 0;
              final threshold = (item['threshold'] as int?) ?? 0;
              final isLow = stock < threshold;
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
                            item['label'] as String? ?? '',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Seuil: $threshold',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.6),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove, color: Colors.white70),
                          onPressed: () async {
                            await LocalDatabase.instance.updateInventoryItem(
                              item['id'] as int,
                              stock: stock > 0 ? stock - 1 : 0,
                            );
                            await _reload();
                          },
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: (isLow
                                    ? Colors.redAccent
                                    : Colors.greenAccent)
                                .withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'Stock: $stock',
                            style: TextStyle(
                              color:
                                  isLow ? Colors.redAccent : Colors.greenAccent,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add, color: Colors.white70),
                          onPressed: () async {
                            await LocalDatabase.instance.updateInventoryItem(
                              item['id'] as int,
                              stock: stock + 1,
                            );
                            await _reload();
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _MaintenanceScaffold extends StatelessWidget {
  const _MaintenanceScaffold(
      {required this.title, required this.child, this.onAdd});

  final String title;
  final Widget child;
  final VoidCallback? onAdd;

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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (onAdd != null)
                    ElevatedButton.icon(
                      onPressed: onAdd,
                      icon: const Icon(Icons.add, color: Colors.white),
                      label: const Text(
                        'Ajouter',
                        style: TextStyle(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                      ),
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

class _TicketCard extends StatelessWidget {
  const _TicketCard({
    required this.room,
    required this.title,
    required this.status,
    required this.priority,
    required this.assigned,
    this.onClose,
    this.onDelete,
  });

  final String room;
  final String title;
  final String status;
  final String priority;
  final String assigned;
  final VoidCallback? onClose;
  final VoidCallback? onDelete;

  Color _statusColor() {
    switch (status.toLowerCase()) {
      case 'résolu':
      case 'resolu':
        return Colors.greenAccent;
      case 'en cours':
        return Colors.orangeAccent;
      default:
        return Colors.blueAccent;
    }
  }

  Color _priorityColor() {
    switch (priority.toLowerCase()) {
      case 'haute':
        return Colors.redAccent;
      case 'moyenne':
        return Colors.orangeAccent;
      default:
        return Colors.blueAccent;
    }
  }

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
                  'Ch. $room',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  style: TextStyle(color: Colors.white.withOpacity(0.7)),
                ),
                const SizedBox(height: 4),
                Text(
                  'Assigné: $assigned',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.6), fontSize: 12),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _Pill(label: status, color: _statusColor()),
              const SizedBox(height: 6),
              _Pill(label: priority, color: _priorityColor()),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.check, color: Colors.greenAccent),
                    onPressed: onClose,
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.redAccent),
                    onPressed: onDelete,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}

Future<void> _showTicketDialog(BuildContext context) async {
  final roomCtrl = TextEditingController();
  final titleCtrl = TextEditingController();
  String status = 'Ouvert';
  String priority = 'Moyenne';
  final assignedCtrl = TextEditingController();
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Nouveau ticket'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: roomCtrl,
            decoration: const InputDecoration(labelText: 'Chambre'),
          ),
          TextField(
            controller: titleCtrl,
            decoration: const InputDecoration(labelText: 'Titre'),
          ),
          DropdownButtonFormField<String>(
            value: status,
            decoration: const InputDecoration(labelText: 'Statut'),
            items: const [
              DropdownMenuItem(value: 'Ouvert', child: Text('Ouvert')),
              DropdownMenuItem(value: 'En cours', child: Text('En cours')),
              DropdownMenuItem(value: 'Résolu', child: Text('Résolu')),
            ],
            onChanged: (v) => status = v ?? status,
          ),
          DropdownButtonFormField<String>(
            value: priority,
            decoration: const InputDecoration(labelText: 'Priorité'),
            items: const [
              DropdownMenuItem(value: 'Haute', child: Text('Haute')),
              DropdownMenuItem(value: 'Moyenne', child: Text('Moyenne')),
              DropdownMenuItem(value: 'Basse', child: Text('Basse')),
            ],
            onChanged: (v) => priority = v ?? priority,
          ),
          TextField(
            controller: assignedCtrl,
            decoration: const InputDecoration(labelText: 'Assigné à'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Annuler'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Créer'),
        ),
      ],
    ),
  );
  if (ok == true) {
    await LocalDatabase.instance.addMaintenanceTicket(
      room: roomCtrl.text.trim().isEmpty ? 'N/A' : roomCtrl.text.trim(),
      title: titleCtrl.text.trim().isEmpty ? 'Ticket' : titleCtrl.text.trim(),
      status: status,
      priority: priority,
      assigned: assignedCtrl.text.trim(),
    );
  }
}

Future<void> _showInventoryDialog(BuildContext context) async {
  final labelCtrl = TextEditingController();
  final stockCtrl = TextEditingController(text: '0');
  final thresholdCtrl = TextEditingController(text: '0');
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Nouvel article'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: labelCtrl,
            decoration: const InputDecoration(labelText: 'Libellé'),
          ),
          TextField(
            controller: stockCtrl,
            decoration: const InputDecoration(labelText: 'Stock'),
            keyboardType: TextInputType.number,
          ),
          TextField(
            controller: thresholdCtrl,
            decoration: const InputDecoration(labelText: 'Seuil'),
            keyboardType: TextInputType.number,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Annuler'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Créer'),
        ),
      ],
    ),
  );
  if (ok == true) {
    await LocalDatabase.instance.addInventoryItem(
      label: labelCtrl.text.trim(),
      stock: int.tryParse(stockCtrl.text) ?? 0,
      threshold: int.tryParse(thresholdCtrl.text) ?? 0,
    );
  }
}

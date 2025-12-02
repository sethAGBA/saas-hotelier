import 'package:flutter/material.dart';

class ChangementsScreen extends StatelessWidget {
  const ChangementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final requests = [
      {'guest': 'Awa Diop', 'from': '101', 'to': '203', 'reason': 'Vue mer demandée', 'status': 'En attente'},
      {'guest': 'Jean Dupont', 'from': '305', 'to': 'Suite 401', 'reason': 'Upgrade VIP', 'status': 'Approuvé'},
    ];
    return _FrontScaffold(
      title: 'Changements de chambre',
      child: requests.isEmpty
          ? const Center(child: Text('Aucune demande', style: TextStyle(color: Colors.white70)))
          : ListView.separated(
              itemCount: requests.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final r = requests[index];
                return _Card(
                  title: r['guest'] as String,
                  subtitle: 'De ${r['from']} → ${r['to']}',
                  trailing: r['status'] as String,
                  color: (r['status'] == 'Approuvé') ? Colors.greenAccent : Colors.orangeAccent,
                  body: r['reason'] as String,
                );
              },
            ),
    );
  }
}

class GestionClesScreen extends StatelessWidget {
  const GestionClesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final keys = [
      {'room': '101', 'holder': 'Awa Diop', 'status': 'Remise', 'time': '09:15'},
      {'room': '203', 'holder': 'Jean Dupont', 'status': 'En cours', 'time': '08:40'},
      {'room': '305', 'holder': 'Staff ménage', 'status': 'Badge', 'time': '07:55'},
    ];
    return _FrontScaffold(
      title: 'Gestion Clés',
      child: ListView.separated(
        itemCount: keys.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final k = keys[index];
          return _Card(
            title: 'Ch. ${k['room']}',
            subtitle: k['holder'] as String,
            trailing: k['status'] as String,
            color: Colors.blueAccent,
            body: 'Dernière action : ${k['time']}',
          );
        },
      ),
    );
  }
}

class _FrontScaffold extends StatelessWidget {
  const _FrontScaffold({required this.title, required this.child});

  final String title;
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
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
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

class _Card extends StatelessWidget {
  const _Card({
    required this.title,
    required this.subtitle,
    required this.trailing,
    required this.color,
    this.body,
  });

  final String title;
  final String subtitle;
  final String trailing;
  final Color color;
  final String? body;

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
                  style: TextStyle(color: Colors.white.withOpacity(0.7)),
                ),
                if (body != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    body!,
                    style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              trailing,
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

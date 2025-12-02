import 'package:flutter/material.dart';

import 'tabs/cloud_tab.dart';
import 'tabs/entite_tab.dart';
import 'tabs/parametres_etendus_tab.dart';
import 'tabs/securite_tab.dart';
import 'tabs/templates_tab.dart';
import 'tabs/utilisateurs_tab.dart';

class ParametresScreen extends StatefulWidget {
  const ParametresScreen({super.key});

  @override
  State<ParametresScreen> createState() => _ParametresScreenState();
}

class _ParametresScreenState extends State<ParametresScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

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
              const Text(
                'Paramètres & Administration',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                ),
                child: TabBar(
                  controller: _tabController,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white60,
                  indicator: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  tabs: const [
                    Tab(icon: Icon(Icons.business), text: 'Entité'),
                    Tab(
                      icon: Icon(Icons.people_alt_rounded),
                      text: 'Utilisateurs',
                    ),
                    Tab(icon: Icon(Icons.description), text: 'Templates'),
                    Tab(icon: Icon(Icons.security), text: 'Sécurité'),
                    Tab(icon: Icon(Icons.cloud), text: 'Cloud'),
                    Tab(
                      icon: Icon(Icons.settings_applications),
                      text: 'Paramètres étendus',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: const [
                    EntiteTab(),
                    UtilisateursTab(),
                    TemplatesTab(),
                    SecuriteTab(),
                    CloudTab(),
                    ParametresEtendusTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import '../../models/user.dart';
import 'package:flutter/material.dart';



String getUserRoleString(UserRole role) {
  switch (role) {
    case UserRole.admin:
      return 'Admin';
    case UserRole.comptable:
      return 'Comptable';
    case UserRole.commercial:
      return 'Commercial';
    case UserRole.secretaire:
      return 'Secrétaire';
  }
}

Color getRoleColor(UserRole role) {
  switch (role) {
    case UserRole.admin:
      return const Color(0xFF6366F1);
    case UserRole.comptable:
      return const Color(0xFF10B981);
    case UserRole.commercial:
      return const Color(0xFFF59E0B);
    case UserRole.secretaire:
      return const Color(0xFF06B6D4);
  }
}

String formatDate(DateTime dt) => '${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

// Modules correspondants aux titres des menus (MainScreen)
const List<String> kAllModules = [
  'Tableau de Bord',
  'Étudiants',
  'Formations',
  'Comptabilité',
  'Facturation',
  'Analyses',
  'Reporting Avancé',
  'Analyse',
  'Analyse Étendue',
  'Recherche certificats',
  'Personnel',
  'Ajouter Employé',
  'Gestion des Employés',
  'Paie',
  'Temps & Congés',
  'Gestion des Départements',
  'Gestion des Postes',
  'Matériel & Achats',
  'Paramètres',
];

// Modules par défaut selon le rôle
List<String> defaultModulesForRole(UserRole role) {
  switch (role) {
    case UserRole.admin:
      return List<String>.from(kAllModules);
    case UserRole.comptable:
      return [
        'Tableau de Bord',
        'Comptabilité',
        'Facturation',
        'Analyses',
        'Analyse',
        'Reporting Avancé',
      ];
    case UserRole.commercial:
      return [
        'Tableau de Bord',
        'Étudiants',
        'Formations',
        'Facturation',
        'Recherche certificats',
        'Analyses',
        'Analyse',
      ];
    case UserRole.secretaire:
      return [
        'Tableau de Bord',
        'Étudiants',
        'Formations',
        'Recherche certificats',
      ];
  }
}

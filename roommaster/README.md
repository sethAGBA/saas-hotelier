# roommaster

Tableau de bord Flutter pour la gestion hôtelière, destiné à un usage local (macOS/iOS).

## Pré-requis

- Flutter 3.19+ et Dart 3.9+
- Xcode 15+ avec CocoaPods (`brew install cocoapods`)
- macOS 13+ pour les builds desktop

## Installation & Build

```bash
flutter pub get

# macOS
cd macos && pod install
flutter run -d macos

# iOS (simulateur ou appareil)
cd ios && pod install
flutter run -d ios
```

La base SQLite (`roommaster.db`) est créée dans le dossier Application Support du système. Pour ré-initialiser les données, supprimez ce fichier puis relancez l’application.

## Fonctionnalités actuelles

- UI dashboard futuriste (statistiques, statut des chambres, activités récentes)
- Base locale Sqflite utilisable sur macOS (via `sqflite_common_ffi`) et iOS
- Exemple de données persistées (chambres 101/102) et agrégation temps réel dans le synoptique
- Écran "Gestion chambres" connecté à SQLite (ajout, édition, suppression, changement de statut)

## Étapes suivantes

- Créer les modèles métier (réservations, clients, housekeeping)
- Ajouter la navigation multi-modules et les formulaires de gestion
- Implémenter l’authentification locale (profils réception, admin, maintenance)
- Couvrir les nouveaux services avec des tests (`flutter test`) et activer CI

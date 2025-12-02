# Gemini Project Configuration
 find ~ -type f -name "afroforma.db" 2>/dev/null | tee ~/found_afroforma_db_paths.txt
## Project Overview

This project is an **Accounting Management Application for Training Organizations**.

## Technology Stack

- **Framework:** Flutter Desktop
- **Database:** SQLite
- **Mode:** Offline-first

## Development Guidelines

- When making changes, please adhere to the existing coding style and conventions.
- Ensure that all database interactions are compatible with SQLite.
- Prioritize offline functionality and data synchronization strategies.



Application de Gestion Comptable pour Organismes de Formation
Flutter Desktop + SQLite (Mode Offline)
🏗️ Architecture Technique
Base de données SQLite
sql
-- Tables principales
- utilisateurs (gestion des rôles)
- etudiants 
- formations
- sessions_formation
- inscriptions
- transactions_financieres
- ecritures_comptables
- plan_comptable
- parametres_entreprise
Structure de navigation
•	Sidebar : Navigation principale entre modules
•	AppBar : Barre d'outils contextuelle avec actions rapides
•	Body : Zone de contenu principal avec onglets si nécessaire
•	Bottom Bar : Informations de statut et notifications
 
📱 Modules & Écrans Détaillés
🔹 1. TABLEAU DE BORD
Écran principal avec widgets synthétiques
Widgets dashboard :
•	Chiffres clés du mois : CA, nb inscriptions, encaissements
•	Graphiques : Évolution CA sur 12 mois, répartition par formation
•	Alertes : Étudiants en impayés, sessions bientôt complètes
•	Raccourcis : Nouvelle inscription, nouveau paiement, rapport express
Actions rapides :
•	Bouton FAB : "Nouvelle inscription"
•	Barre de recherche globale (étudiant/formation)
•	Notifications système (sauvegarde, alertes)
 
🔹 2. GESTION DES ÉTUDIANTS
Écran principal : Liste des étudiants
•	DataTable avec colonnes : Photo, Nom, Formation actuelle, Statut paiement, Actions
•	Filtres : Par formation, statut paiement, période d'inscription
•	Recherche : Nom, téléphone, email
•	Actions en lot : Relances, exports, suppressions
Écran détail étudiant (Modal/Page)
dart
Tabs:
├── 📋 Informations personnelles
│   ├── Données civiles (nom, adresse, contact)
│   ├── Photo d'identité
│   └── Documents joints (CNI, diplômes)
├── 🎓 Parcours académique
│   ├── Formations suivies/en cours
│   ├── Notes et évaluations
│   └── Certificats obtenus
├── 💰 Suivi financier
│   ├── Historique des paiements
│   ├── Échéancier restant
│   ├── Remises accordées
│   └── Génération reçus
└── 📞 Communication
    ├── Historique des échanges
    ├── Relances envoyées
    └── Nouveau message/appel
Formulaire nouvel étudiant
•	Wizard en étapes : Infos personnelles → Formation → Modalités paiement
•	Validation temps réel des champs
•	Calcul automatique des montants avec remises
•	Génération automatique du numéro étudiant
 
🔹 3. GESTION DES FORMATIONS
Écran catalogue formations
•	Cards avec image, titre, durée, tarif, nb inscrits
•	Filtres : Domaine, niveau, statut (active/inactive)
•	Actions : Modifier, Dupliquer, Archiver
Écran détail formation
dart
Tabs:
├── ℹ️ Informations générales
│   ├── Description, objectifs, prérequis
│   ├── Durée, modalités, tarification
│   └── Documents pédagogiques
├── 👨‍🏫 Formateurs assignés
│   ├── Liste des intervenants
│   ├── Planning d'intervention
│   └── Coûts de formation
├── 📅 Sessions programmées
│   ├── Calendrier des sessions
│   ├── Gestion des salles
│   └── Taux de remplissage
└── 💰 Analyse financière
    ├── CA généré par formation
    ├── Coûts directs/indirects
    └── Marge bénéficiaire
Planification des sessions
•	Calendrier interactif avec drag & drop
•	Gestion des conflits de salle/formateur
•	Notifications automatiques aux inscrits
 
🔹 4. COMPTABILITÉ
Plan comptable
•	TreeView hiérarchique (Classes → Comptes → Sous-comptes)
•	Paramétrage SYSCOHADA par défaut
•	Personnalisation possible selon besoins
Journal des écritures
•	DataTable avec filtres par journal, période, compte
•	Saisie rapide avec templates d'écritures récurrentes
•	Validation/Lettrage automatique
•	Export vers Excel/CSV
États comptables
dart
Rapports disponibles:
├── 📊 Balance générale
├── 📋 Grand livre
├── 💼 Bilan comptable
├── 📈 Compte de résultat
├── 🏦 Journal de trésorerie
└── 📄 Déclarations fiscales
 
🔹 5. FACTURATION & ENCAISSEMENTS
Génération automatique factures
•	Templates personnalisables (logo, mentions légales)
•	Numérotation automatique selon paramètres
•	Calculs automatiques (remises, TVA, total)
•	Export PDF avec signature électronique
Suivi des paiements
•	Interface timeline : Échéances → Relances → Encaissements
•	Modes de paiement : Espèces, Chèque, Virement, Mobile Money
•	Rapprochement bancaire semi-automatique
•	Alertes impayés configurables
Écran encaissement
•	Saisie rapide avec calcul automatique de la monnaie
•	Impression reçu instantanée
•	Répartition paiement sur plusieurs échéances
 
🔹 6. REPORTING & ANALYSES
Tableau de bord financier
dart
Widgets analytics:
├── 📊 CA par formation (graphique en secteurs)
├── 📈 Évolution mensuelle (courbes)
├── 💰 Taux de recouvrement (jauges)
├── 🎯 Objectifs vs Réalisé
└── 🔄 Ratios financiers clés
Rapports personnalisables
•	Générateur de requêtes visuelles (drag & drop)
•	Templates prédéfinis : Bilan pédagogique, Situation trésorerie
•	Planification automatique d'envoi
•	Formats d'export : PDF, Excel, CSV
 
🔹 7. PARAMÈTRES & ADMINISTRATION
Configuration entreprise
•	Informations société (RCCM, NIF, logo)
•	Paramètres comptables (exercice, plan comptable)
•	Templates documents (factures, reçus, attestations)
Gestion utilisateurs
•	Profils d'accès : Admin, Comptable, Commercial, Secrétaire
•	Permissions granulaires par module/action
•	Traçabilité complète des actions utilisateurs
Sauvegarde & Sécurité
•	Backup automatique SQLite avec chiffrement
•	Import/Export base de données
•	Historique des modifications avec possibilité de rollback
 
🎨 Interface Utilisateur
Design System
•	Material 3 Design avec thème personnalisé
•	Mode sombre/clair selon préférences
•	Responsive pour différentes tailles d'écran
•	Accessibilité complète (contrastes, navigation clavier)
Composants réutilisables
•	DataTables avec tri/filtrage avancé
•	Forms avec validation temps réel
•	Charts interactifs (fl_chart)
•	PDF Viewer/Generator intégré
•	DatePickers avec périodes prédéfinies
 
⚡ Fonctionnalités Avancées
Performance
•	Pagination intelligente des listes
•	Cache SQLite pour requêtes fréquentes
•	Indexation optimisée des tables
•	Lazy loading des données volumineuses
Automatisations
•	Génération automatique des écritures comptables
•	Calcul automatique des amortissements
•	Relances automatiques des impayés
•	Clôture automatique des exercices
Import/Export
•	Import Excel pour migration de données
•	Export comptable vers logiciels tiers
•	Synchronisation avec solutions bancaires
•	API REST pour intégrations futures
 
🔄 Workflow Types
Nouvelle inscription
Prospect → Inscription → Facturation → Paiement → Confirmation
Suivi paiement échelonné
Échéancier → Relance → Encaissement → Lettrage → Clôture
Session de formation
Planification → Inscription → Réalisation → Évaluation → Facturation



class _EntrepriseTabState extends State<EntrepriseTab> {
  final _formKey = GlobalKey<FormState>();
  final _raisonSocialeController = TextEditingController(text: 'AfroForma SARL');
  final _rccmController = TextEditingController(text: 'TG-LOM-01-B-123456');
  final _nifController = TextEditingController(text: '12345678901');
  final _adresseController = TextEditingController(text: '123 Avenue de la Paix, Lomé');
  final _telephoneController = TextEditingController(text: '+228 22 12 34 56');
  final _emailController = TextEditingController(text: 'contact@afroforma.com');
  final _siteWebController = TextEditingController(text: 'www.afroforma.com');
  final _exerciceController = TextEditingController(text: DateTime.now().year.toString());
  String? _logoPath;
  String _monnaie = 'FCFA';
  String _planComptable = 'SYSCOHADA';


  firebase deploy --only storage --project k-empire-68e8c

flutter run -d macos --dart-define=USE_FIREBASE_EMULATORS=true
## Firebase Storage Integration of Update Files





✦ The compiled application binaries (APKs for Android, EXEs for Windows, DMGs for macOS, DEBs/RPMs for Linux) need to be hosted somewhere accessible via a URL.

  Given that your project already uses Firebase, Firebase Storage is an excellent and convenient option for hosting these files.

  Here's how you would typically set it up:

   1. Build Your Application for Each Platform:
      Run the appropriate build commands in your project's root directory:
       * For Android: flutter build apk --release
       * For Windows: flutter build windows --release
       * For macOS: flutter build macos --release
       * For Linux: flutter build linux --release
      These commands will generate the deployable files in the build/app/outputs/ directory (e.g., build/app/outputs/flutter-apk/app-release.apk,
  build/windows/runner/Release/your_app_name.exe, etc.).

   2. Upload Binaries to Firebase Storage:
       * Go to your Firebase project console (console.firebase.google.com).
       * Navigate to the "Storage" section.
       * Create a new folder (e.g., app_updates/v1.0.1/) to organize your versions.
       * Upload the generated APK, EXE, DMG, DEB, etc., files into this folder.

   3. Obtain Public Download URLs:
       * After uploading each file, click on it within the Firebase Storage interface.
       * In the file details pane, you will find a "Download URL". This is the public URL that your app will use to download the update.

   4. Update Firestore with Version Info and URLs:
       * In your Firestore database, you'll need to create or update the app_settings/update_info document (as per the code I added to firestore_service.dart).
       * This document should contain the latest_version (e.g., "1.0.1") and a map of download_urls for each platform.

      Example Firestore Document (`app_settings/update_info`):

   1     {
   2       "latest_version": "1.0.1",
   3       "download_urls": {
   4         "android":
     "https://firebasestorage.googleapis.com/v0/b/your-project-id.appspot.com/o/app_updates%2Fv1.0.1%2Fapp-release.apk?alt=media&token=...",
   5         "windows":
     "https://firebasestorage.googleapis.com/v0/b/your-project-id.appspot.com/o/app_updates%2Fv1.0.1%2Fyour_app_name.exe?alt=media&token=...",
   6         "macos":
     "https://firebasestorage.googleapis.com/v0/b/your-project-id.appspot.com/o/app_updates%2Fv1.0.1%2Fyour_app_name.dmg?alt=media&token=...",
   7         "linux":
     "https://firebasestorage.googleapis.com/v0/b/your-project-id.appspot.com/o/app_updates%2Fv1.0.1%2Fyour_app_name.deb?alt=media&token=..."
   8       }
   9     }
      Your app will then read these URLs from Firestore and use them when the user clicks "Télécharger" in the update dialog.





- Journaux + numérotation
      - CRUD des journaux (codes ACH/VTE/BQ/CAI/OD) et séquences (numérotation auto par journal).
      - Verrouillage d’exercice et dates autorisées.
  - Saisie d’écritures
      - Assistant de saisie rapide (débit/crédit équilibré, compte, libellé, TVA).
      - Lettrage/délettrage simple, duplication, pièces jointes.
  - États comptables exportables
      - Grand livre, Balance, Bilan, Compte de résultat.
      - Export PDF/XLSX/CVS et filtres période/journal/compte (les écrans existent; j’unifie les exports et ajoute colonnes utiles).
  - Sync Firestore
      - Collections journaux, ecritures_comptables avec updatedAt + isDeleted.
      - Pull/push avec conversions de types (bool→int) comme on l’a fait pour étudiants.
      - Option “Synchroniser maintenant” avec logs détaillés.
  - Intégration paiements/ventes
      - Génération d’écritures automatiques à partir des paiements inscriptions (produits/banque/tiers).
      - Paramètres d’imputation (comptes de ventes/clients/banque par défaut).

  Dites-moi ce qu’on attaque en premier:

  - A) Journaux + numérotation + saisie basique
  - B) États + exports unifiés
  - C) Sync Firestore “journaux” et “écritures”
  - D) Écritures auto depuis paiements + paramétrage des comptes

  Je peux démarrer sur A + C (fondations) puis enchaîner sur B et D.




  Je propose d’attaquer la Comptabilité par A + C en priorité:

  - A) Journaux + numérotation + saisie d’écritures (base solide pour travailler)
  - C) Sync Firestore sur journaux/écritures (dans la foulée, comme on l’a fait pour étudiants)

  Plan d’implémentation

  1. Numérotation par journal

  - Ajouter un générateur de “pieceNumber” par journal (table numerotation déjà en place).
  - Incrémenter auto à chaque insertion d’écriture; format configurable (ex: VTE-2025-000123).

  2. Saisie rapide d’une écriture

  - Bouton “Nouvelle écriture” avec modal minimal:
      - date, journal, compte, libellé, débit/crédit.
      - Vérification équilibrée (débit == crédit).
      - Enregistre avec updatedAt.

  3. Mise à jour schéma + marquage

  - Ajouter updatedAt si absent:
      - journaux, ecritures_comptables.
  - Marquer updatedAt à chaque insert/update pour la sync.

  4. Sync Firestore

  - Ajouter push/pull pour:
      - journaux → /journaux
      - ecritures_comptables → /ecritures_comptables
  - Conversion types (bool→int, Map/List→JSON) déjà en place côté pull.
  - Ne pas descendre les éléments supprimés (si besoin, même logique que pour étudiants).

  5. Exports de base

  - Unifier export PDF/Excel/CSV sur la vue des écritures filtrées (période/journal/recherche).

  Dites‑moi si je démarre sur ce plan. Si oui, je:

  - Ajoute la numérotation + saisie rapide (UI modale).
  - Ajoute updatedAt sur journaux/écritures + sync Firestore correspondante.
  - Laisse l’export pour la passe suivante (rapide à ajouter).
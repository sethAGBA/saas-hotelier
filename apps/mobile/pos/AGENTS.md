# Repository Guidelines

## Project Structure & Module Organization
The app follows the standard Flutter layout. Core application code lives in `lib/`, with the entry point and navigation wiring in `lib/main.dart`. Widget-specific assets and helpers should be added under new subdirectories (for example, `lib/widgets/receipt/`). Cross-platform platform shells reside in `android/`, `ios/`, `linux/`, `macos/`, `windows/`, and `web/`; edit these only when a platform-specific capability is needed. Shared configuration and dependency metadata belong in `pubspec.yaml`, while instrumentation, smoke, or unit tests sit in `test/` alongside any golden assets they consume.

## Build, Test, and Development Commands
- `flutter pub get` — Install or refresh Dart and Flutter dependencies as defined in `pubspec.yaml`.
- `flutter run -d <device_id>` — Launch the app on an attached simulator or device for fast feedback.
- `flutter test` — Execute the automated Dart test suite in `test/`. Add `--coverage` when you need a coverage report in `coverage/lcov.info`.
- `flutter build apk --release` (or `ios --release`) — Produce distributable binaries; run only from a clean state to avoid bundling stale artifacts.

## Coding Style & Naming Conventions
Follow the rules enforced by `analysis_options.yaml`, which extends `flutter_lints`. Keep Dart files formatted with `dart format lib test` (2-space indentation, trailing commas to encourage multi-line formatting). Use `snake_case` filenames (for example, `receipt_summary.dart`), `PascalCase` for widgets and public classes, and `lowerCamelCase` for members. Prefer small composable widgets over sprawling build methods, and keep platform-conditional logic behind clearly named helpers.

## Testing Guidelines
Author tests with the `flutter_test` framework; use `group()` blocks to mirror feature areas and name files `<feature>_test.dart`. Stub asynchronous work with `FakeAsync` or mock clients to keep tests deterministic. Aim to touch new logic with at least one focused unit test and a widget test when UI behavior is affected. Run `flutter test` locally before raising a pull request; add `--coverage` to confirm critical flows hit minimum expectations (≥80% for new modules).

## Commit & Pull Request Guidelines
Write commits in imperative tense (`Add POS cart widget`) and limit the subject to ~50 characters, optionally referencing tracking IDs (`Add receipt flow #123`). Each pull request should include: a concise summary of the change, links to related issues, screenshots or recordings for visible UI updates, and a checklist of manual or automated tests executed. Keep PRs scoped to a single feature or bug fix so reviewers can assess impact quickly.


##  reviewing what's missing in design or functionality and preparing a summary with suggestions to address those gaps, based on the user's question. This is an analysis step rather than a new plan.


 Expérience tablette — navigation dédiée (drawer compact ou bottom bar) manque pour passer vite entre tables, cuisine, caisse; il faudrait aussi gérer l’orientation paysage, les padding et tailles de
    police adaptatifs, et prévoir un mode “caisse” à gros boutons pour les serveurs.
  - Workflow POS complet — seuls les menus/tables existent; il manque la gestion des notes d’articles, des remises, des splits d’addition, des paiements multiples (cash/carte), de l’historique et des
    tickets imprimables/PDF.
  - Gestion catalogue — pas d’écran pour ajouter/modifier articles, catégories, prix, TVA ou disponibilités; un module d’édition (avec import/export CSV) faciliterait la maintenance sur place.
  - État des tables — prévoir des badges visuels (en attente, prêt, payé), un chronomètre de durée d’occupation, et des filtres de recherche quand on dépasse 12 tables; la vue actuelle ne montre que
    “occupé/libre”.
  - Design cohérent — malgré le nouveau thème, l’app manque de hiérarchies claires: ajoute typographies secondaires, cartes modulaires pour commandes, animations discrètes pour feedback, et un panneau
    “résumé order” fixe sur tablette large.
  - Mode hors ligne/sauvegarde — l’appli ne mentionne pas de stockage local (SQLite/Isar) ni de synchronisation; pour un POS local, il faut persister les commandes et gérer les reprises après crash.
  - Rôles et sécurité — prévoir un écran de login PIN, différents niveaux d’accès (serveur, manager) et un mode verrouillage rapide.
  - Intégrations périphériques — ajouter hooks pour imprimantes thermiques, tiroirs-caisse et lecteurs de carte, même si simulés via services abstraits pour commencer.
  - Analytics & reporting — aucune fonctionnalité de stats journalières/hebdo; il serait utile d’avoir un tableau de bord ventes, top articles, chiffres par serveur.



 1. Écran catalogue & disponibilité
      - Ajoute un onglet ou un drawer « Catalogue » permettant d’activer/désactiver des articles, modifier prix/TVA, créer des catégories.
      - Stocke ces changements via le repo (ou un fichier séparé) afin qu’ils persistent.
  2. Suivi cuisine / impressions
      - Sépare la commande en tickets « cuisine » (entrées/plats) et « bar » (boissons) avec un état par ticket (en cours, prêt).
      - Prépare un service abstrait KitchenPrinter/ReceiptPrinter pour simuler l’envoi des commandes; même sans hardware, ça aidera la logique.
  3. Flux d’authentification & rôles
      - Ajoute un écran de verrouillage rapide (PIN par rôle).
      - Restreins l’accès aux sections (catalogue, annulation ticket) selon le rôle connecté.
  4. Reporting local
      - Ajoute un écran « Rapports » listant ventes du jour/semaine, top articles, tickets ouverts. Ces chiffres s’appuient sur l’historique que nous stockons déjà par table.




  - Tablet navigation/adaptation: still missing a dedicated drawer/bottom bar, landscape padding, responsive typography, and a large-button “caisse” mode.
  - POS workflow depth: no support yet for line notes everywhere, per-line discounts, split bills, multi-payment capture, ticket history, or richer PDF/print flows.
  - Catalog administration: consider a richer management screen (bulk edit, category creation, VAT, CSV import/export) for on-site maintenance.
  - Table state clarity: add badges for waiting/ready/paid, occupancy timers, and search/filtering when table counts grow.
  - Visual hierarchy: secondary typography, modular cards, subtle animations, and a fixed order-summary panel on wide tablets would reinforce the new look.
  - Offline/storage: move persistence to SQLite/Isar with sync/replay logic rather than a single JSON file.
  - Roles/security: extend the PIN flow to enforce role-based permissions (catalog edits, voids) and provide a quick-lock toggle.
  - Peripheral hooks & analytics: keep building toward printer/drawer/card-reader abstractions and expose a sales dashboard (daily/weekly totals, top sellers, per-server metrics).
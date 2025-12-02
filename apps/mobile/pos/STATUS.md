POS Mobile/Tablet – état d’avancement

Déjà fait
- App Flutter tablette POS (restaurant/bar) avec thèmes, navigation par onglets et gestion tables/menu.
- Persistance locale JSON (`pos_state.json` + backup) via `PosRepository` : tables, menu, ventes, settings (pins, users, catégories).
- Auth par rôle (staff/manager) via PIN, lock screen de démarrage.
- Menu/catalogue : catégories dynamiques, disponibilité (dispo/rupture/saisonnier), TVA par item, image locale optionnelle, journal de modifications (catalogLogs).
- Prise de commande par table, tickets cuisine/bar, gestion statuts et enregistrement des ventes.
- Génération de reçus PDF (format 58mm) et service d’impression simulé.

Reste à faire (priorité)
- Sync backend (multi-tenant) et lien PMS : folios chambres, transfert en chambre, centralisation caisse.
- Paiements : Flooz/T-Money/CB, split payments, remboursements, pourboires/discounts harmonisés, clôture caisse.
- Inventaire/stock (décrémentation, alertes), modifiers/options menu, combos.
- Sécurité : chiffrement du stockage local, rotation des PINs, audit des actions, rôles additionnels.
- Reporting : ventes/jours/canaux, product mix, exports comptables (plan comptable), envoi email/PDF.
- Qualité/ops : tests unit/widget, CI, paramétrage build tablette, gestion répertoire PDF/imprimante matérielle. 

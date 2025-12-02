Roomaster – état d’avancement

Déjà fait
- Architecture Flutter desktop/mobile avec thème futuriste et navigation par modules (dashboard, réservations, chambres, housekeeping, clients, maintenance, finance, reporting).
- Base SQLite locale initialisée via `LocalDatabase` avec nombreuses tables (chambres, réservations, clients, services, compta, maintenance, inventaire) et jeux de données seed.
- Auth locale : seed admin, hash SHA-256, écran de connexion, support TOTP côté service.
- Dashboard alimenté par la base (occupation, revenus moyens, activités récentes) et gestion chambres CRUD + statuts/housekeeping.
- Réservations : liste filtrable/triable, formulaire complet de création/édition, check-in/check-out avec filtres.
- Clients : base clients + écrans VIP/Corporate/Fidélité en place (maquettes fonctionnelles).

Reste à faire (priorité Roomaster/mobile)
- Connecter à un backend multi-tenant (auth JWT/OAuth2, sync distante) tout en conservant SQLite pour le mode offline/sync.
- Compléter POS/restaurant-bar, caisse et facturation (fonds de caisse, split billing, templates facture/folio).
- Channel manager OTA, pricing dynamique, promotions/packaging, programme fidélité complet.
- Housekeeping/maintenance/inventaire : assignations, timers, photos, stocks, reporting.
- CRM/messaging (email/SMS), exports conformité (registre police, RGPD), logs/audit, monitoring.
- Tests unit/widget, CI, données de démo, publication builds (desktop/mobile) et sécurisation (2FA réel).

Note base locale
- La base SQLite locale doit être maintenue pour le mode offline. On peut l’enrichir et prévoir une couche de synchronisation distante ultérieurement (pas besoin de la retirer).

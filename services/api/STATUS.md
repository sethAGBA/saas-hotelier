API Backend – état d’avancement
pour 
Déjà fait
- Squelette de dossiers (auth, config, db, tenancy, modules, integrations, queues), pas de code implémenté pour le moment.

Reste à faire (priorité)
- Choix stack et bootstrap (ex. NestJS) avec config typée, validation, logs, observabilité.
- Multi-tenant : résolution tenant (domaine/clé), RLS côté DB, middleware guard, scopes par rôle.
- Auth : JWT/OAuth2, refresh, rôles/permissions, TOTP, rate limiting, sessions service.
- Modèles métier : réservations, chambres, clients, housekeeping, POS, facturation/caisse, channel manager, pricing, reporting.
- Infra data : Prisma/TypeORM + migrations, seeds par tenant, fixtures de démo, storage (S3/MinIO), cache Redis, queues BullMQ.
- API externes : paiements (Stripe/Mobile Money), OTA, SMS/Email, webhooks, exports comptables.
- Qualité/ops : tests (unit/integration/e2e), lint/format, CI/CD, observabilité (OpenTelemetry, Sentry), sécurité (CORS, headers, audit).

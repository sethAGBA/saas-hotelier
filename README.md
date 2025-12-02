# SAAS_HOTELIER Monorepo

Structure multi-apps pour le SaaS hôtellerie.

## Arborescence
- `apps/web` : front Next.js (App Router).
- `apps/mobile`, `apps/desktop`, `apps/kiosk` : autres clients (placeholders).
- `services/api` : backend (Nest/Express), `services/workers`, `services/realtime`, `services/reporting`.
- `packages/*` : bibliothèques partagées (UI, schémas, types, auth, utils, monitoring).
- `infra/*` : Docker, K8s, Terraform, CI/CD, scripts.
- `docs` : documentation fonctionnelle/technique.
- `roommaster` : app Flutter desktop/mobile (macOS/iOS) existante.

## Commandes (Makefile)
- `make web-dev` : lancer le front web.
- `npm run dev --workspace services/api` : Lancer l'api.
- `make web-build` : build du front web.
- `make web-lint` : lint du front web.
- `make web-start` : démarrer le build web.
- `make flutter-get` : installer les dépendances Flutter.
- `make flutter-run-desktop` : lancer roommaster sur macOS.
- `make flutter-run-ios` : lancer roommaster sur iOS (simulateur ou device).
- `make flutter-clean` : nettoyer roommaster.

## Notes
- Le projet Next.js a été déplacé dans `apps/web` (sans `node_modules`, `.next` ni dépôt `.git`).
- Ajoutez des README ou supprimez les `.gitkeep` selon vos besoins au fur et à mesure que vous remplissez chaque dossier.
- Auth demo (NextAuth Credentials) : utilisateur par défaut `admin@hotelflow.pro` / `password123` (surchargable via `DEMO_USER_EMAIL` et `DEMO_USER_PASSWORD`). Pensez à définir `NEXTAUTH_SECRET` en production.
# saas-hotelier

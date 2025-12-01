# SAAS_HOTELIER Monorepo

Structure multi-apps pour le SaaS hôtellerie.

## Arborescence
- `apps/web` : front Next.js (App Router).
- `apps/mobile`, `apps/desktop`, `apps/kiosk` : autres clients (placeholders).
- `services/api` : backend (Nest/Express), `services/workers`, `services/realtime`, `services/reporting`.
- `packages/*` : bibliothèques partagées (UI, schémas, types, auth, utils, monitoring).
- `infra/*` : Docker, K8s, Terraform, CI/CD, scripts.
- `docs` : documentation fonctionnelle/technique.
- `roommaster` : app Flutter locale existante.

## Commandes
- `npm run dev:web` : lancer le front web depuis la racine.
- `npm run build:web` : build du front web.
- `npm run lint:web` : lint du front web.

## Notes
- Le projet Next.js a été déplacé dans `apps/web` (sans `node_modules`, `.next` ni dépôt `.git`).
- Ajoutez des README ou supprimez les `.gitkeep` selon vos besoins au fur et à mesure que vous remplissez chaque dossier.
# saas-hotelier

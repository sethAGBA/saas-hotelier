# API Backend (NestJS)

Bootstrap minimal NestJS-style API with multi-tenant hooks.

## Scripts

- `npm install` (depuis la racine ou dans `services/api`) pour installer les dépendances.
- `npm run dev --workspace services/api` pour lancer en mode dev (ts-node-dev).
- `npm run build --workspace services/api` puis `npm run start --workspace services/api` pour build + run.
- `npm run check --workspace services/api` pour la compilation TypeScript.
- `npm run lint --workspace services/api` pour ESLint.
- `npm run seed --workspace services/api` pour créer un tenant + admin (variables `SEED_*` optionnelles).

## Endpoints

- `GET /api/health` : heartbeat (inclut le tenant détecté si fourni).
- `GET /api/health/ready` : readiness (stub DB/cache à compléter).
- `POST /api/auth/login` : login avec tenant/email/password, retourne un JWT.
- `GET /api/auth/me` : profil JWT courant (JWT requis).
- `GET /api/rooms` : liste des chambres (JWT requis).
- `POST /api/rooms` : création (roles ADMIN/MANAGER).
- `PATCH /api/rooms/:id/status` : mise à jour du statut (ADMIN/MANAGER).
- `GET /api/reservations` : liste des réservations (JWT requis).
- `POST /api/reservations` : création (roles ADMIN/MANAGER/STAFF).
- `PATCH /api/reservations/:id/status` : mise à jour du statut (ADMIN/MANAGER/STAFF).

## Tenancy (stub)

- `X-Tenant-Id` ou query `?tenant=` pour propager un tenantId dans le contexte (AsyncLocalStorage).
- Intercepteur global `TenantInterceptor` : disponible pour enricher les services/guards plus tard.

## Variables d’environnement

Voir `.env.example` (PORT, DATABASE_URL, REDIS_URL). Ajoutez un `.env` local si besoin.

## Base de données (Prisma)

- Schéma de base multi-tenant : `Tenant`, `User`, `Room`, `Reservation` (`prisma/schema.prisma`).
- Générer le client : `npx prisma generate --schema prisma/schema.prisma`.
- Appliquer une migration : `npx prisma migrate dev --name init --schema prisma/schema.prisma` (DB PostgreSQL requise).
- Client Prisma accessible via `PrismaService` (tenantId contextuel disponible).

### Seed

- Variables (facultatives) : `SEED_TENANT_SLUG`, `SEED_TENANT_NAME`, `SEED_ADMIN_EMAIL`, `SEED_ADMIN_PASSWORD`.
- Exécution : `npm run seed --workspace services/api`.
- Par défaut : tenant `demo`, admin `admin@demo.tld` / `Password123!`, chambres de démo et deux réservations.

## Usage rapide (API)

1. Login :
```bash
curl -X POST http://localhost:4000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"tenant":"demo","email":"admin@demo.tld","password":"Password123!"}'
```
2. Appels protégés (ex. rooms) :
```bash
curl -X GET http://localhost:4000/api/rooms \
  -H "Authorization: Bearer <JWT>" \
  -H "X-Tenant-Id: <tenantId du token>"  # doit matcher le JWT (sinon 401)
```

## Prochaines étapes

- Finaliser RLS applicative (guards) et connexion PostgreSQL réelle.
- Enrichir l’auth (création d’utilisateur, refresh token, rôles/politiques, rate limiting).
- Modules métier (reservations, chambres, clients, POS, facturation) + intégrations (paiements, OTA).
- Observabilité (logs structurés, OpenTelemetry, Sentry) et CI.

 ## À faire pour exploiter :

  1. Configurer Postgres : définir DATABASE_URL dans .env.
  2. Générer client Prisma : `npx prisma generate --schema services/api/prisma/schema.prisma`.
  3. Créer migration et appliquer : `npx prisma migrate dev --name init --schema services/api/prisma/schema.prisma`.
  4. Seed (non fait) : créer un tenant + user avec mot de passe hashé (bcryptjs) pour tester le login.
  5. Relancer l’API : `npm run dev --workspace services/api puis tester POST /api/auth/login avec tenant/email/password`.

  Si tu veux, je peux ajouter un script de seed (tenant + admin) et un guard de rôle/tenant strict pour sécuriser les futurs modules.
  
### Options pour avancer :

  1. Basculer temporairement sur un Postgres local (docker) pour appliquer les migrations et tester l’API.
      - Exemple .env :

        DATABASE_URL=postgresql://postgres:postgres@localhost:5432/hotelier
        DIRECT_URL=postgresql://postgres:postgres@localhost:5432/hotelier
      - Commandes : docker run --name hotelier-pg -e POSTGRES_PASSWORD=postgres -e POSTGRES_DB=hotelier -p 5432:5432 -d postgres:15
      - Puis npx prisma migrate dev --name init --schema services/api/prisma/schema.prisma
  2. Vérifier l’accès Supabase :
      - Confirmer que l’instance est accessible publiquement (essayer psql ou nc -zv depuis ta machine).
      - Vérifier mot de passe et host (pooler/direct) et ajouter sslmode=require (déjà fait).
      - Eventuellement autoriser l’IP source ou vérifier si le réseau ici est restreint.
  3. Si tu veux, je peux préparer un script de seed pour créer un tenant + admin et un garde-fou pour rôles, en attendant que la connexion DB soit résolue.

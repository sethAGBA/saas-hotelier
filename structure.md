Voici une arborescence recommandée pour ton SaaS (multi‑plateforme, multi‑tenant) qui sépare apps, services backend, paquets partagés et infra :

  .
  ├─ apps/
  │  ├─ web/                 # Next.js (App Router)
  │  │  ├─ src/app/          # routes, layouts, metadata
  │  │  ├─ src/features/     # domaines (reservations, clients, chambres…)
  │  │  ├─ src/components/   # UI réutilisable
  │  │  ├─ src/lib/          # utils front (fetcher, auth client)
  │  │  ├─ src/styles/       # thèmes, tokens
  │  │  └─ public/           # assets
  │  ├─ mobile/              # Flutter (app staff/client)
  │  ├─ desktop/             # Electron/Flutter desktop si nécessaire
  │  └─ kiosk/               # PWA kiosque check-in
  │
  ├─ services/
  │  ├─ api/                 # NestJS/Express (REST+GraphQL)
  │  │  ├─ src/modules/      # domaines (reservations, housekeeping, billing…)
  │  │  ├─ src/auth/         # JWT/OAuth2, guards, policies
  │  │  ├─ src/tenancy/      # résolution tenant, RLS
  │  │  ├─ src/db/           # Prisma/TypeORM, migrations
  │  │  ├─ src/queues/       # jobs Bull/Redis
  │  │  ├─ src/integrations/ # OTA, paiements, SMS, email
  │  │  └─ src/config/       # config typée par env
  │  ├─ workers/             # process lourds (sync OTA, pricing dynamique)
  │  ├─ realtime/            # WebSocket/Socket.IO ou SSE
  │  └─ reporting/           # ETL/BI, exports, jobs d’agrégation
  │
  ├─ packages/
  │  ├─ ui/                  # design system partagé (React), tokens
  │  ├─ schemas/             # zod/io-ts DTOs, contrats d’API
  │  ├─ types/               # types communs (TS)
  │  ├─ config/              # eslint, prettier, tsconfig base
  │  ├─ auth/                # lib client/serveur pour auth et rôles
  │  ├─ utils/               # helpers transverses
  │  └─ monitoring/          # instrumentation (OpenTelemetry)
  │
  ├─ infra/
  │  ├─ docker/              # Dockerfiles, compose dev
  │  ├─ k8s/                 # manifests Helm/Manifests
  │  ├─ terraform/           # cloud (DB, Redis, S3, secrets)
  │  ├─ github-actions/      # CI/CD pipelines
  │  └─ scripts/             # déploiement, migrations, seed
  │
  ├─ docs/                   # ADR, specs fonctionnelles/techniques
  ├─ .env.example            # variables d’environnement de base
  └─ Makefile / package.json # commandes dev (lint/test/build)

  Principes :

  - Séparer clairement les apps (web/mobile/desktop) des services backend.
  - Centraliser le design system et les contrats d’API dans packages/ pour éviter la duplication.
  - Tenancy géré côté API (services/api/src/tenancy) + RLS en base.
  - Jobs asynchrones et intégrations externes isolés dans workers/ et services/api/src/integrations.
  - Infra versionnée (Docker/K8s/Terraform) et CI/CD dans infra/.

  Adapte les noms/domains selon tes modules (reservations, chambres, housekeeping, billing, channel-manager, etc.).
HotelFlow Web – état d’avancement

Déjà fait
- Landing Next.js (App Router) avec sections marketing : Hero, Benefits, Features, Testimonials, Timeline, Integrations, FAQ, CTA, Pricing.
- Pages additionnelles maquettes : Dashboard statique, Demo (formulaire), Login (NextAuth credentials démo), Resources/Blog/Help/Website-builder/Security/Status.
- Design dark/émeraude, composants UI maison (button, card, input, calendar simplifié), icons Lucide, Tailwind v4.
- Auth démo via NextAuth credentials (email/mdp en variables d’environnement), route `api/auth/[...nextauth]` prête.

Reste à faire (priorité)
- Brancher un backend réel multi-tenant (API, données dynamiques) pour Dashboard, réservations, paiements, housekeeping, etc.
- Protéger les routes backoffice via NextAuth + rôles, état de session côté client, redirections, middleware.
- Alimenter les pages avec des données réelles ou mocks typés (ADR, RevPAR, planning, housekeeping, paiements) et composants dynamiques (charts, filtres).
- Formulaires (demo/contact/login/signup) : validation, anti-spam, enregistrement (DB/CRM), notifications.
- Ajouter pages produit essentielles : planning Gantt, réservations, check-in/out, housekeeping, paiements/folio, pricing, channel manager, POS.
- Observabilité et qualité : lint/config stricte, tests (unitaires + e2e), CI/CD, gestion env (dotenv), Sentry/monitoring.

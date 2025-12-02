import Link from 'next/link';
import { CalendarDays, BookOpen, LineChart, ArrowUpRight } from 'lucide-react';

const posts = [
  {
    id: 1,
    title: 'Boostez votre RevPAR : tarification dynamique pour les hôtels togolais',
    excerpt: 'Configurer vos saisons, événements spéciaux et canaux directs vs OTA pour éviter le surbooking.',
    date: 'Jan 2025',
    tag: 'Revenue',
  },
  {
    id: 2,
    title: 'Intégrer Flooz et T-Money en toute sécurité',
    excerpt: 'Paramétrage, encaissements, rapprochements, gestion des annulations et des remboursements.',
    date: 'Déc 2024',
    tag: 'Paiements',
  },
  {
    id: 3,
    title: 'Housekeeping mobile : gagner 35% de temps',
    excerpt: 'Checklists, photos avant/après, tickets maintenance et suivi offline pour vos équipes.',
    date: 'Nov 2024',
    tag: 'Opérations',
  },
  {
    id: 4,
    title: 'Relancer vos clients directs : email/SMS au bon moment',
    excerpt: 'Scénarios d’automations, coupons, upsell spa/restaurant et réduction des no-shows.',
    date: 'Oct 2024',
    tag: 'Marketing',
  },
];

export default function BlogPage() {
  return (
    <main className="bg-slate-950 text-white">
      <div className="max-w-6xl mx-auto px-6 py-16">
        <div className="text-center space-y-3">
          <p className="text-sm uppercase tracking-[0.2em] text-emerald-200">Ressources & Blog</p>
          <h1 className="text-3xl md:text-4xl font-semibold">Guides pour hôteliers et équipes opérationnelles</h1>
          <p className="text-slate-200">Revenue management, housekeeping, paiements, marketing direct, conformité.</p>
        </div>

        <div className="mt-12 grid grid-cols-1 gap-6 md:grid-cols-2">
          {posts.map((post) => (
            <article key={post.id} className="rounded-2xl border border-white/10 bg-white/5 p-6 shadow-lg">
              <div className="flex items-center gap-3 text-xs text-emerald-100">
                <span className="rounded-full bg-emerald-400/15 px-3 py-1 font-semibold text-emerald-100">{post.tag}</span>
                <CalendarDays className="h-4 w-4" />
                <span>{post.date}</span>
              </div>
              <h2 className="mt-3 text-xl font-semibold leading-tight">{post.title}</h2>
              <p className="mt-2 text-sm text-slate-200">{post.excerpt}</p>
              <Link
                href="#"
                className="mt-4 inline-flex items-center gap-2 text-sm font-semibold text-emerald-200 hover:underline"
              >
                Lire l’article
                <ArrowUpRight className="h-4 w-4" />
              </Link>
            </article>
          ))}
        </div>

        <div className="mt-14 grid gap-6 md:grid-cols-[1.1fr_0.9fr]">
          <div className="rounded-2xl border border-white/10 bg-white/5 p-6">
            <div className="flex items-center gap-2 text-sm text-emerald-200">
              <LineChart className="h-4 w-4" />
              Benchmarks & KPI
            </div>
            <h3 className="mt-2 text-2xl font-semibold">KPI marché togolais</h3>
            <p className="mt-2 text-slate-200">
              RevPAR, ADR, no-show, conversion OTA vs direct et top canaux par segment (business, loisirs, groupes).
            </p>
            <div className="mt-4 flex flex-wrap gap-2 text-xs text-emerald-100">
              <span className="rounded-full bg-emerald-400/15 px-3 py-1">RevPAR moyen : 47k FCFA</span>
              <span className="rounded-full bg-emerald-400/15 px-3 py-1">No-show moyen : 6%</span>
              <span className="rounded-full bg-emerald-400/15 px-3 py-1">Direct vs OTA : 42% / 58%</span>
            </div>
          </div>
          <div className="rounded-2xl border border-white/10 bg-white/5 p-6">
            <div className="flex items-center gap-2 text-sm text-emerald-200">
              <BookOpen className="h-4 w-4" />
              Replays & Webinars
            </div>
            <h3 className="mt-2 text-2xl font-semibold">Apprenez avec nos experts</h3>
            <ul className="mt-3 space-y-2 text-sm text-slate-200">
              <li>• Gérer la parité tarifaire entre OTA et direct</li>
              <li>• Housekeeping mobile et checklists qualité</li>
              <li>• Paiements Flooz/T-Money : règles et sécurité</li>
              <li>• Connecter Booking.com et Airbnb sans surbooking</li>
            </ul>
            <Link
              href="/resources"
              className="mt-4 inline-flex items-center gap-2 text-sm font-semibold text-emerald-200 hover:underline"
            >
              Voir toutes les ressources
              <ArrowUpRight className="h-4 w-4" />
            </Link>
          </div>
        </div>
      </div>
    </main>
  );
}

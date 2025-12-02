import Link from 'next/link';
import { BookOpen, ShieldCheck, PlugZap, Server, HelpCircle, LineChart, Globe2 } from 'lucide-react';
import { Button } from '@/components/ui/button';

const resourceCards = [
  {
    title: 'Guides & Blog',
    desc: 'Playbooks revenue, housekeeping, marketing direct, Mobile Money, OTA.',
    icon: BookOpen,
    cta: { label: 'Lire les guides', href: '/blog' },
  },
  {
    title: 'Sécurité & Conformité',
    desc: 'DGT, RGPD, facturation locale, sauvegardes, contrôle d’accès par rôles.',
    icon: ShieldCheck,
    cta: { label: 'Voir nos engagements', href: '/security' },
  },
  {
    title: 'Status & Fiabilité',
    desc: 'Suivi temps réel des services (web, API, paiements) et historiques incidents.',
    icon: Server,
    cta: { label: 'Consulter le statut', href: '/status' },
  },
  {
    title: 'API & Intégrations',
    desc: 'Channel manager, paiements, exports comptables, webhooks et SDK front.',
    icon: PlugZap,
    cta: { label: 'Explorer l’API', href: '/api' },
  },
  {
    title: 'Centre d’aide',
    desc: 'FAQ, vidéos, procédures d’onboarding, checklists réception/housekeeping.',
    icon: HelpCircle,
    cta: { label: 'Aller au help center', href: '/help' },
  },
  {
    title: 'Benchmarks & KPIs',
    desc: 'RevPAR, ADR, no-show, conversion OTA vs direct pour le marché togolais.',
    icon: LineChart,
    cta: { label: 'Voir les benchmarks', href: '/blog' },
  },
];

export default function Resources() {
  return (
    <main className="bg-slate-950 text-white">
      <div className="max-w-6xl mx-auto px-6 py-16">
        <div className="text-center space-y-3">
          <p className="text-sm uppercase tracking-[0.2em] text-emerald-200">Ressources</p>
          <h1 className="text-3xl md:text-4xl font-semibold">Tout pour accélérer votre hôtel</h1>
          <p className="text-slate-200">Guides, API, sécurité, support et outils pour vos équipes.</p>
        </div>

        <div className="mt-12 grid grid-cols-1 gap-6 md:grid-cols-2">
          {resourceCards.map((card) => (
            <div key={card.title} className="rounded-2xl border border-white/10 bg-white/5 p-6 shadow-lg">
              <div className="flex items-center gap-3">
                <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-emerald-400/20 text-emerald-200">
                  <card.icon className="h-5 w-5" />
                </div>
                <div>
                  <h3 className="text-xl font-semibold">{card.title}</h3>
                  <p className="text-sm text-slate-200">{card.desc}</p>
                </div>
              </div>
              <div className="mt-4">
                <Link
                  href={card.cta.href}
                  className="text-emerald-200 text-sm font-semibold hover:underline"
                >
                  {card.cta.label}
                </Link>
              </div>
            </div>
          ))}
        </div>

        <div className="mt-14 grid gap-6 md:grid-cols-[1.1fr_0.9fr]">
          <div className="rounded-2xl border border-white/10 bg-white/5 p-6">
            <h2 className="text-2xl font-semibold">Assistance locale 7j/7</h2>
            <p className="mt-2 text-slate-200">Equipe basée au Togo pour vous aider sur la configuration, la formation et les intégrations.</p>
            <div className="mt-4 flex flex-wrap gap-3 text-sm text-emerald-100">
              <span className="rounded-full bg-emerald-400/15 px-3 py-1">Onboarding en 30 jours</span>
              <span className="rounded-full bg-emerald-400/15 px-3 py-1">WhatsApp + appel</span>
              <span className="rounded-full bg-emerald-400/15 px-3 py-1">Formation réception & housekeeping</span>
            </div>
            <div className="mt-6 flex gap-3">
              <Button asChild className="bg-emerald-400 text-slate-950 hover:bg-emerald-300">
                <Link href="/demo">Parler à un expert</Link>
              </Button>
              <Button variant="outline" asChild className="border-emerald-200 text-white hover:bg-white/10">
                <Link href="/help">Ouvrir le help center</Link>
              </Button>
            </div>
          </div>
          <div className="rounded-2xl border border-white/10 bg-white/5 p-6">
            <h2 className="text-2xl font-semibold">Programmes & webinaires</h2>
            <p className="mt-2 text-slate-200">Replays, ateliers et sessions live pour vos équipes.</p>
            <ul className="mt-4 space-y-2 text-sm text-slate-200">
              <li>• Optimiser le RevPAR avec la tarification dynamique</li>
              <li>• Housekeeping mobile : checklists et photos avant/après</li>
              <li>• Paiements Flooz / T-Money : meilleures pratiques</li>
              <li>• Connecter Booking.com, Airbnb, Expedia sans surbooking</li>
            </ul>
            <div className="mt-4 flex items-center gap-2 text-sm text-emerald-100">
              <Globe2 className="h-4 w-4" /> Sessions FR/EN, replays disponibles
            </div>
          </div>
        </div>
      </div>
    </main>
  );
}

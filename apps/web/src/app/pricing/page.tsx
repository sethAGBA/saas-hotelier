// app/pricing/page.tsx
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import Link from 'next/link';
import { CheckCircle2, Sparkles } from 'lucide-react';

const tiers = [
  {
    name: 'Starter',
    price: '20 000',
    period: 'mois',
    features: [
      '10 chambres',
      'Planning & réservations',
      'Paiements Flooz / T-Money',
      'Support email',
      'Site web hôtel (starter)',
      'Utilisateurs illimités',
      'Mode offline',
    ],
  },
  {
    name: 'Business',
    price: '50 000',
    period: 'mois',
    features: [
      '30 chambres',
      'Channel manager OTA',
      'Housekeeping mobile',
      'Support chat + onboarding',
      'Revenue de base (saisons, événements)',
      'Sites web + widgets réservation',
      'Exports financiers de base',
      'Utilisateurs illimités',
      'Mode offline',
    ],
    highlighted: true,
    badge: 'Recommandé',
  },
  {
    name: 'Professional',
    price: '120 000',
    period: 'mois',
    features: [
      '100 chambres',
      'Revenue management avancé',
      'Site web hôtel + builder',
      'Support prioritaire 24/7',
      'Exports comptables & BI',
      'Channel manager premium',
      'API & webhooks prioritaire',
      'Utilisateurs illimités',
      'Mode offline & plan de reprise',
    ],
  },
];

const addons = [
  'POS Restaurant / Bar',
  'Kiosque check-in libre-service',
  'IA Pricing dynamique',
  'Intégrations comptables',
];

export default function Pricing() {
  return (
    <main className="bg-slate-950 text-white">
      <div className="max-w-6xl mx-auto px-6 py-16">
        <div className="text-center space-y-3">
          <p className="text-sm uppercase tracking-[0.2em] text-emerald-200">Tarifs</p>
          <h1 className="text-3xl md:text-4xl font-semibold">Des plans adaptés à la taille de votre établissement</h1>
          <p className="text-slate-200">Onboarding accompagné. Pas de commissions sur vos réservations directes.</p>
        </div>

        <div className="mt-12 grid grid-cols-1 gap-6 md:grid-cols-3">
          {tiers.map((tier) => (
            <Card
              key={tier.name}
              className={`relative border-white/10 bg-white/5 text-white ${
                tier.highlighted ? 'ring-2 ring-emerald-300 ring-offset-1 ring-offset-slate-950' : ''
              }`}
            >
              {tier.badge && (
                <div className="absolute top-4 right-4 inline-flex items-center gap-2 rounded-full bg-emerald-400/20 px-3 py-1 text-xs font-semibold text-emerald-100">
                  <Sparkles className="h-4 w-4" /> {tier.badge}
                </div>
              )}
              <CardHeader className="space-y-2">
                <CardTitle className="text-2xl">{tier.name}</CardTitle>
                <p className="text-sm text-emerald-100">Jusqu’à {tier.features[0]}</p>
              </CardHeader>
              <CardContent className="space-y-5">
                <div>
                  <span className="text-4xl font-bold">{tier.price}</span>
                  <span className="ml-2 text-slate-200">FCFA / {tier.period}</span>
                </div>
                <ul className="space-y-2 text-sm">
                  {tier.features.map((f) => (
                    <li key={f} className="flex items-center gap-2 text-slate-100">
                      <CheckCircle2 className="h-4 w-4 text-emerald-300" /> {f}
                    </li>
                  ))}
                </ul>
                <Button asChild className="w-full bg-emerald-400 text-slate-950 hover:bg-emerald-300">
                  <Link href="/demo">Choisir ce plan</Link>
                </Button>
              </CardContent>
            </Card>
          ))}
        </div>

        <div className="mt-12 grid gap-6 md:grid-cols-2">
          <div className="rounded-2xl border border-white/10 bg-white/5 p-6">
            <h3 className="text-xl font-semibold">Options additionnelles</h3>
            <ul className="mt-4 space-y-2 text-sm text-slate-200">
              {addons.map((a) => (
                <li key={a} className="flex items-center gap-2">
                  <CheckCircle2 className="h-4 w-4 text-emerald-300" /> {a}
                </li>
              ))}
            </ul>
          </div>
          <div className="rounded-2xl border border-white/10 bg-white/5 p-6 flex flex-col gap-3 justify-center">
            <h3 className="text-xl font-semibold">Onboarding express</h3>
            <p className="text-slate-200">Configuration, import chambres/tarifs et formation équipes : livrés en 30 jours avec un expert local.</p>
            <Button variant="outline" asChild className="border-emerald-200 text-white hover:bg-white/10 w-fit">
              <Link href="/demo">Planifier un appel</Link>
            </Button>
          </div>
        </div>

        <div className="mt-12 grid gap-6 lg:grid-cols-[1.1fr_0.9fr]">
          <div className="rounded-2xl border border-white/10 bg-white/5 p-6 space-y-3">
            <h3 className="text-xl font-semibold">Comparatif rapide</h3>
            <ul className="space-y-2 text-sm text-slate-200">
              <li className="flex gap-2"><CheckCircle2 className="h-4 w-4 text-emerald-300" /> Channel manager OTA : inclus Business/Pro</li>
              <li className="flex gap-2"><CheckCircle2 className="h-4 w-4 text-emerald-300" /> Revenue management avancé : inclus Pro</li>
              <li className="flex gap-2"><CheckCircle2 className="h-4 w-4 text-emerald-300" /> Site web hôtel : inclus tous les plans (builder complet en Pro)</li>
              <li className="flex gap-2"><CheckCircle2 className="h-4 w-4 text-emerald-300" /> Support : email (Starter), chat + onboarding (Business), prioritaire 24/7 (Pro)</li>
              <li className="flex gap-2"><CheckCircle2 className="h-4 w-4 text-emerald-300" /> Offline & Mobile Money : inclus tous les plans</li>
            </ul>
          </div>
          <div className="rounded-2xl border border-white/10 bg-white/5 p-6 space-y-3">
            <h3 className="text-xl font-semibold">Questions fréquentes</h3>
            <p className="text-sm text-slate-200"><strong>Frais cachés ?</strong> Aucun frais de setup, aucune commission sur vos réservations directes.</p>
            <p className="text-sm text-slate-200"><strong>Paiements et facturation ?</strong> Facturation mensuelle, possibilité annuelle sur demande. Encaissements Flooz/T-Money/CB inclus.</p>
            <p className="text-sm text-slate-200"><strong>Mise en ligne ?</strong> Onboarding accompagné en 30 jours, import de données et formation réception/housekeeping.</p>
            <Button variant="outline" asChild className="border-emerald-200 text-white hover:bg-white/10 w-fit">
              <Link href="/help">Voir toutes les questions</Link>
            </Button>
          </div>
        </div>
      </div>
    </main>
  );
}

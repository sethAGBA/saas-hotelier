// components/Benefits.tsx (Inspiré : Grow Revenue, Simplify Ops, Online Presence)
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { TrendingUp, Workflow, Globe2 } from 'lucide-react';

const benefits = [
  {
    title: 'Augmentez vos revenus',
    desc: 'Tarification dynamique, connectivité OTA et moteur de réservation direct pour maximiser vos ventes.',
    icon: TrendingUp,
    badge: '+22% RevPAR moyen',
  },
  {
    title: 'Simplifiez vos opérations',
    desc: 'Planning unifié, encaissements Flooz/T-Money, check-in express et suivi housekeeping offline.',
    icon: Workflow,
    badge: '-35% de temps admin',
  },
  {
    title: 'Présence en ligne clé en main',
    desc: 'Site web sans commission, SEO local, widgets de réservation et paiements sécurisés.',
    icon: Globe2,
    badge: '3 min pour publier',
  },
];

export default function Benefits() {
  return (
    <section className="bg-slate-900 py-16 text-white">
      <div className="max-w-6xl mx-auto px-6">
        <div className="flex flex-col gap-3 text-center">
          <p className="text-sm uppercase tracking-[0.2em] text-emerald-200">Bénéfices clés</p>
          <h2 className="text-3xl md:text-4xl font-semibold">Pensé pour les hôtels, lodges et maisons d’hôtes</h2>
          <p className="text-slate-200">Des modules métiers prêts à l’emploi pour remplir vos chambres, encaisser plus vite et offrir une expérience fluide.</p>
        </div>
        <div className="mt-12 grid grid-cols-1 gap-6 md:grid-cols-3">
          {benefits.map(({ title, desc, icon: Icon, badge }) => (
            <Card key={title} className="border-white/10 bg-white/5 text-white">
              <CardHeader className="flex flex-col gap-3">
                <div className="inline-flex w-12 h-12 items-center justify-center rounded-xl bg-emerald-400/20 text-emerald-200">
                  <Icon className="h-6 w-6" />
                </div>
                <CardTitle className="text-xl text-white">{title}</CardTitle>
              </CardHeader>
              <CardContent className="text-slate-200">
                <p>{desc}</p>
                <span className="mt-4 inline-flex rounded-full bg-emerald-400/15 px-3 py-1 text-xs font-semibold text-emerald-200">
                  {badge}
                </span>
              </CardContent>
            </Card>
          ))}
        </div>
      </div>
    </section>
  );
}

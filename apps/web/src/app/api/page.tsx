import Link from 'next/link';
import { PlugZap, Webhook, Lock, BookOpen } from 'lucide-react';

const endpoints = [
  { name: 'Webhooks réservations', desc: 'Réception des créations/annulations pour vos intégrations.' },
  { name: 'Inventaire & tarifs', desc: 'Mise à jour des disponibilités et prix par catégorie/chambre.' },
  { name: 'Paiements', desc: 'Créer et suivre des paiements Flooz / T-Money / CB via API.' },
  { name: 'Reporting', desc: 'Exports financiers et PMS au format JSON/CSV.' },
];

export default function ApiPage() {
  return (
    <main className="bg-slate-950 text-white min-h-screen">
      <div className="max-w-5xl mx-auto px-6 py-16 space-y-8">
        <div className="space-y-2 text-center">
          <p className="text-sm uppercase tracking-[0.2em] text-emerald-200">API & Intégrations</p>
          <h1 className="text-3xl font-semibold">Connectez vos outils à HotelFlow Pro</h1>
          <p className="text-slate-300">Webhooks, inventaire, paiements, exports comptables et SDK front.</p>
        </div>
        <div className="grid gap-4 md:grid-cols-2">
          {endpoints.map((ep) => (
            <div key={ep.name} className="rounded-2xl border border-white/10 bg-white/5 p-5">
              <h3 className="text-lg font-semibold">{ep.name}</h3>
              <p className="mt-2 text-sm text-slate-200">{ep.desc}</p>
            </div>
          ))}
        </div>
        <div className="rounded-2xl border border-white/10 bg-white/5 p-6 space-y-3 text-sm text-slate-200">
          <div className="flex items-center gap-2 text-emerald-200">
            <PlugZap className="h-4 w-4" /> SDK & Auth
          </div>
          <p>Authentification par clés d’API, OAuth pour apps partenaires, et widgets front (booking, paiement).</p>
          <div className="flex items-center gap-2 text-emerald-200">
            <Webhook className="h-4 w-4" /> Webhooks
          </div>
          <p>Réservations, paiements, housekeeping et folios. Signature HMAC pour sécuriser les callbacks.</p>
          <div className="flex items-center gap-2 text-emerald-200">
            <Lock className="h-4 w-4" /> Sécurité
          </div>
          <p>Limites de taux, isolation multi-tenant, gestion des permissions par rôle.</p>
          <Link href="/help" className="inline-flex items-center gap-2 text-emerald-200 hover:underline text-sm">
            <BookOpen className="h-4 w-4" /> Voir la documentation (bientôt)
          </Link>
        </div>
      </div>
    </main>
  );
}

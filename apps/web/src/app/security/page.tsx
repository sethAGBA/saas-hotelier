import { ShieldCheck, LockKeyhole, Cloud } from 'lucide-react';

const items = [
  { title: 'Conformité & données', desc: 'RGPD, DGT : collecte minimale, droits d’accès par rôle, journalisation des actions.' },
  { title: 'Chiffrement & réseau', desc: 'TLS, mots de passe hashés, séparation des environnements, secrets gérés.' },
  { title: 'Sauvegardes', desc: 'Backups quotidiens, rétention 30 jours, tests de restauration mensuels.' },
  { title: 'Résilience', desc: 'Surveillance 24/7, alerting, répartition de charge, reprise en cas d’incident.' },
];

export default function SecurityPage() {
  return (
    <main className="bg-slate-950 text-white min-h-screen">
      <div className="max-w-5xl mx-auto px-6 py-16 space-y-8">
        <div className="space-y-2 text-center">
          <p className="text-sm uppercase tracking-[0.2em] text-emerald-200">Sécurité & conformité</p>
          <h1 className="text-3xl font-semibold">Protection des données et continuité</h1>
          <p className="text-slate-300">Contrôles d’accès, chiffrement, sauvegardes, conformité locale et européenne.</p>
        </div>
        <div className="grid gap-4 md:grid-cols-2">
          {items.map((item) => (
            <div key={item.title} className="rounded-2xl border border-white/10 bg-white/5 p-5">
              <h3 className="text-lg font-semibold">{item.title}</h3>
              <p className="mt-2 text-sm text-slate-200">{item.desc}</p>
            </div>
          ))}
        </div>
        <div className="rounded-2xl border border-white/10 bg-white/5 p-6 space-y-3 text-sm text-slate-200">
          <div className="flex items-center gap-2 text-emerald-200">
            <ShieldCheck className="h-4 w-4" /> Audit & bonnes pratiques
          </div>
          <p>Formation des équipes, revue périodique des accès, gestion des appareils mobiles, plan de réponse incident.</p>
          <div className="flex items-center gap-2 text-emerald-200">
            <LockKeyhole className="h-4 w-4" /> Contrôles d’accès
          </div>
          <p>Rôles : direction, réception, housekeeping, finance, maintenance. 2FA recommandé pour les rôles sensibles.</p>
          <div className="flex items-center gap-2 text-emerald-200">
            <Cloud className="h-4 w-4" /> Continuité
          </div>
          <p>Procédures de bascule en cas d’interruption réseau ou fournisseur, mode offline pour opérations critiques.</p>
        </div>
      </div>
    </main>
  );
}

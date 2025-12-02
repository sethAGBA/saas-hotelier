export default function StatusPage() {
  return (
    <main className="bg-slate-950 text-white min-h-screen">
      <div className="max-w-5xl mx-auto px-6 py-16 space-y-6">
        <div className="space-y-2 text-center">
          <p className="text-sm uppercase tracking-[0.2em] text-emerald-200">Statut</p>
          <h1 className="text-3xl font-semibold">Santé des services</h1>
          <p className="text-slate-300">Web, API, paiements, synchronisation OTA, notifications.</p>
        </div>
        <div className="rounded-2xl border border-white/10 bg-white/5 p-6 space-y-3">
          <StatusItem label="Web & dashboard" status="Opérationnel" />
          <StatusItem label="API & Webhooks" status="Opérationnel" />
          <StatusItem label="Synchronisation OTA" status="Opérationnel" />
          <StatusItem label="Paiements Flooz / T-Money" status="Opérationnel" />
          <StatusItem label="Notifications email / SMS" status="Opérationnel" />
        </div>
        <div className="rounded-2xl border border-white/10 bg-white/5 p-6 text-sm text-slate-200">
          Historique incident : aucune interruption signalée sur les 30 derniers jours. En cas d’incident, nous publions ici les mises à jour en temps réel.
        </div>
      </div>
    </main>
  );
}

function StatusItem({ label, status }: { label: string; status: string }) {
  return (
    <div className="flex items-center justify-between rounded-xl border border-white/5 bg-slate-900/60 px-4 py-3 text-sm">
      <span>{label}</span>
      <span className="rounded-full bg-emerald-400/20 px-3 py-1 text-emerald-100">{status}</span>
    </div>
  );
}

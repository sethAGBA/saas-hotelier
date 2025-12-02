import Link from 'next/link';

const faqs = [
  { q: 'Comment activer Flooz / T-Money ?', a: 'Contactez le support pour lier votre compte marchand. Le module paiements est activé sous 24h.' },
  { q: 'Comment connecter Booking.com ou Airbnb ?', a: 'Depuis le channel manager, ajoutez vos identifiants OTA. La synchronisation bidirectionnelle s’active après validation.' },
  { q: 'Puis-je fonctionner offline ?', a: 'Oui. Les actions critiques sont synchronisées dès le retour de la connexion (réservations, housekeeping, encaissements différés).' },
  { q: 'Comment ajouter des utilisateurs et rôles ?', a: 'Allez dans Paramètres > Utilisateurs, assignez les rôles (réception, direction, housekeeping, finance).' },
];

export default function HelpPage() {
  return (
    <main className="bg-slate-950 text-white min-h-screen">
      <div className="max-w-5xl mx-auto px-6 py-16 space-y-8">
        <div className="space-y-2 text-center">
          <p className="text-sm uppercase tracking-[0.2em] text-emerald-200">Centre d’aide</p>
          <h1 className="text-3xl font-semibold">FAQ & guides express</h1>
          <p className="text-slate-300">Configuration, paiements, OTA, offline, rôles et sécurité.</p>
        </div>
        <div className="grid gap-4 md:grid-cols-2">
          {faqs.map((f) => (
            <div key={f.q} className="rounded-2xl border border-white/10 bg-white/5 p-5">
              <h3 className="text-lg font-semibold">{f.q}</h3>
              <p className="mt-2 text-sm text-slate-200">{f.a}</p>
            </div>
          ))}
        </div>
        <div className="rounded-2xl border border-white/10 bg-white/5 p-6 text-sm text-slate-200">
          Vous ne trouvez pas la réponse ? Écrivez à <Link href="mailto:support@togostay.pro" className="text-emerald-200 underline">support@togostay.pro</Link> ou WhatsApp +228 90 57 99 46. Sessions de formation disponibles chaque semaine.
        </div>
      </div>
    </main>
  );
}

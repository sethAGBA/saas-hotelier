"use client";

export default function Timeline() {
  const steps = [
    { title: 'Inscription & audit', desc: '15 minutes pour comprendre votre inventaire et vos canaux actuels.' },
    { title: 'Paramétrage & import', desc: 'Types de chambres, tarifs saisonniers, TVA locale et encaissements.' },
    { title: 'Formation équipes', desc: 'Réception, housekeeping, direction : 1h en visio ou sur site.' },
    { title: 'Lancement + support', desc: 'Mise en ligne en 30 jours, support 7j/7 et suivi des KPI.' },
  ];

  return (
    <section className="bg-white py-16 dark:bg-slate-950">
      <div className="max-w-5xl mx-auto px-6">
        <div className="flex flex-col gap-2">
          <p className="text-sm uppercase tracking-[0.2em] text-emerald-600 dark:text-emerald-300">Onboarding guidé</p>
          <h2 className="text-3xl font-semibold text-slate-900 dark:text-white">Votre hôtel opérationnel en 4 étapes</h2>
          <p className="text-slate-600 dark:text-slate-300">Un accompagnement par un expert local jusqu’à la mise en ligne.</p>
        </div>
        <div className="mt-10 space-y-4">
          {steps.map((s, i) => (
            <div key={s.title} className="flex gap-4">
              <div className="relative flex flex-col items-center">
                <div className="flex h-10 w-10 items-center justify-center rounded-full border-2 border-emerald-400 bg-emerald-50 text-emerald-700 dark:border-emerald-400 dark:bg-emerald-950 dark:text-emerald-200">
                  {i + 1}
                </div>
                {i < steps.length - 1 && <div className="mt-1 h-full w-px flex-1 bg-gradient-to-b from-emerald-400 to-transparent" />}
              </div>
              <div className="rounded-2xl border border-slate-200 bg-white p-4 shadow-sm dark:border-slate-800 dark:bg-slate-900">
                <h3 className="text-lg font-semibold text-slate-900 dark:text-white">{s.title}</h3>
                <p className="text-sm text-slate-600 dark:text-slate-300">{s.desc}</p>
              </div>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}

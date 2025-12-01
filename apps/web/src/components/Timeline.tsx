"use client";

export default function Timeline() {
  const steps = [
    'Inscription',
    'Configuration du compte',
    'Import des chambres',
    'Lancement en direct',
  ];

  return (
    <div className="space-y-4">
      {steps.map((s, i) => (
        <div key={s} className="flex items-center gap-4">
          <div className="w-8 h-8 rounded-full bg-blue-600 text-white flex items-center justify-center">{i + 1}</div>
          <div>{s}</div>
        </div>
      ))}
    </div>
  );
}

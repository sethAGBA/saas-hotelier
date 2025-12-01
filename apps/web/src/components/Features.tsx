"use client";

export default function Features() {
  const cards = [
    { title: 'Réservations', desc: 'Centralisez vos réservations et disponibilités.' },
    { title: 'Paiements', desc: 'Support pour Flooz & Mobile Money.' },
    { title: 'Rapports', desc: 'Tableaux de bord simples pour suivre l’activité.' },
  ];

  return (
    <div className="grid md:grid-cols-3 gap-6">
      {cards.map((c) => (
        <div key={c.title} className="p-6 border rounded-lg">
          <h3 className="font-semibold text-lg">{c.title}</h3>
          <p className="mt-2 text-sm">{c.desc}</p>
        </div>
      ))}
    </div>
  );
}

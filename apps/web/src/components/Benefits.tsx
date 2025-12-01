"use client";

export default function Benefits() {
  const items = [
    'Réservations centralisées',
    'Paiements Flooz & Mobile Money',
    'Gestion des tarifs et disponibilités',
  ];

  return (
    <section className="container mx-auto py-12">
      <h2 className="text-2xl font-bold mb-4">Bénéfices</h2>
      <ul className="grid md:grid-cols-3 gap-4">
        {items.map((t) => (
          <li key={t} className="p-4 border rounded">{t}</li>
        ))}
      </ul>
    </section>
  );
}

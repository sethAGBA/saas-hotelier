export default function DashboardPage() {
  return (
    <section className="container mx-auto py-16">
      <h1 className="text-3xl font-bold mb-6">Backoffice</h1>
      <div className="grid gap-6 md:grid-cols-3">
        <div className="p-4 border rounded">Réservations (à venir)</div>
        <div className="p-4 border rounded">Chambres & Tarifs</div>
        <div className="p-4 border rounded">Paiements & Intégrations</div>
      </div>
      <section className="mt-8">
        <h2 className="text-xl font-semibold mb-4">Raccourcis</h2>
        <ul className="list-disc pl-6">
          <li>Créer une réservation</li>
          <li>Voir statistiques</li>
        </ul>
      </section>
    </section>
  );
}

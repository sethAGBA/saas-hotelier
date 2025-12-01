export default function PricingPage() {
  return (
    <section className="container mx-auto py-16">
      <h1 className="text-3xl font-bold mb-6">Tarifs adaptés au Togo</h1>
      <div className="grid gap-6 grid-cols-1 md:grid-cols-3">
        <div className="p-6 border rounded-lg">
          <h2 className="text-xl font-semibold">Starter</h2>
          <p className="mt-2">Pour petits B&B et pensions — 5 000 XOF / mois</p>
        </div>
        <div className="p-6 border rounded-lg">
          <h2 className="text-xl font-semibold">Pro</h2>
          <p className="mt-2">Gestion complète — 15 000 XOF / mois</p>
        </div>
        <div className="p-6 border rounded-lg">
          <h2 className="text-xl font-semibold">Enterprise</h2>
          <p className="mt-2">Personnalisé pour chaînes — contactez-nous</p>
        </div>
      </div>
    </section>
  );
}

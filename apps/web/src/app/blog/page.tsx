export default function BlogPage() {
  const posts = [
    { id: 1, title: 'Lancer son hôtel au Togo', excerpt: 'Conseils pour démarrer et attirer des clients locaux.' },
    { id: 2, title: 'Accepter Flooz & Mobile Money', excerpt: 'Intégration des paiements populaires au Togo.' },
  ];

  return (
    <section className="container mx-auto py-16">
      <h1 className="text-3xl font-bold mb-6">Ressources & Blog</h1>
      <ul className="space-y-4">
        {posts.map((p) => (
          <li key={p.id} className="p-4 border rounded">
            <h2 className="font-semibold">{p.title}</h2>
            <p className="text-sm">{p.excerpt}</p>
          </li>
        ))}
      </ul>
    </section>
  );
}

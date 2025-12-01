import Link from 'next/link';

export default function LoginPage() {
  return (
    <section className="container mx-auto py-16 max-w-lg">
      <h1 className="text-2xl font-bold mb-4">Connexion</h1>
      <p className="mb-6">Connectez-vous pour accéder au backoffice.</p>
      <form className="grid gap-4">
        <input name="email" placeholder="Email" className="p-3 border rounded" />
        <input name="password" placeholder="Mot de passe" type="password" className="p-3 border rounded" />
        <div className="flex items-center justify-between">
          <button type="button" className="px-4 py-2 bg-blue-600 text-white rounded" onClick={() => window.location.href = '/dashboard'}>Se connecter</button>
          <Link href="/demo"><a className="text-sm text-blue-600">Demander une démo</a></Link>
        </div>
      </form>
    </section>
  );
}

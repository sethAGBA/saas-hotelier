"use client";

// app/login/page.tsx
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import Link from 'next/link';
import { ShieldCheck, LockKeyhole, LogIn } from 'lucide-react';
import { useState } from 'react';
import { useRouter } from 'next/navigation';
import { saveSession } from '@/lib/session';

export default function Login() {
  const [mode, setMode] = useState<'login' | 'signup'>('login');
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);
  const router = useRouter();

  const handleSubmit = (e: React.FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    const formData = new FormData(e.currentTarget);
    const tenant = String(formData.get('tenant') ?? '');
    const email = String(formData.get('email') ?? '');
    const password = String(formData.get('password') ?? '');

    if (mode === 'signup') {
      // Rediriger vers la démo pour créer un compte accompagné
      router.push('/demo');
      return;
    }

    if (!email || !password) {
      setError('Renseignez votre email et votre mot de passe.');
      return;
    }

    setLoading(true);
    setError(null);

    fetch(`${process.env.NEXT_PUBLIC_API_BASE_URL ?? 'http://localhost:4000'}/api/auth/login`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ tenant, email, password }),
    }).then(async (res) => {
      if (!res.ok) {
        setLoading(false);
        setError('Email ou mot de passe incorrect.');
        return;
      }
      const data = await res.json() as { accessToken?: string; user?: { tenantId?: string } };
      if (!data.accessToken || !data.user?.tenantId) {
        setLoading(false);
        setError('Réponse invalide du serveur.');
        return;
      }
      saveSession({
        accessToken: data.accessToken,
        tenantId: data.user.tenantId,
        email,
      });
      router.push('/dashboard');
    }).catch((err) => {
      setLoading(false);
      setError(`Connexion impossible: ${err}`);
    });
  };

  return (
    <main className="min-h-screen bg-slate-950 text-white flex items-center justify-center px-4 py-16">
      <div className="w-full max-w-5xl grid gap-8 md:grid-cols-[1.1fr_0.9fr]">
        <div className="rounded-3xl border border-white/10 bg-white/5 p-8 shadow-2xl">
          <div className="flex items-center gap-2 text-sm text-emerald-200">
            <LockKeyhole className="h-4 w-4" />
            Connexion sécurisée
          </div>
          <h1 className="mt-3 text-3xl font-semibold">
            {mode === 'login' ? 'Accédez à votre backoffice' : 'Créer un compte hôtel'}
          </h1>
          <p className="mt-2 text-slate-200">Réservations, encaissements, housekeeping et reporting, au même endroit.</p>

          <div className="mt-6 flex gap-3 text-sm">
            <Button
              variant={mode === 'login' ? 'default' : 'outline'}
              className={mode === 'login' ? 'bg-emerald-400 text-slate-950 hover:bg-emerald-300' : 'border-emerald-200 text-white hover:bg-white/10'}
              onClick={() => setMode('login')}
            >
              Connexion
            </Button>
            <Button
              variant={mode === 'signup' ? 'default' : 'outline'}
              className={mode === 'signup' ? 'bg-emerald-400 text-slate-950 hover:bg-emerald-300' : 'border-emerald-200 text-white hover:bg-white/10'}
              onClick={() => setMode('signup')}
            >
              Créer un compte
            </Button>
          </div>

          <form className="mt-8 space-y-6" onSubmit={handleSubmit}>
            <div className="space-y-2">
              <Label htmlFor="email" className="text-slate-200">Email</Label>
              <Input id="email" name="email" type="email" placeholder="prenom.nom@hotel.tg" className="bg-slate-900 border-slate-700 text-white" required />
            </div>
            <div className="space-y-2">
              <Label htmlFor="tenant" className="text-slate-200">Tenant</Label>
              <Input id="tenant" name="tenant" type="text" defaultValue="demo" placeholder="demo" className="bg-slate-900 border-slate-700 text-white" required />
            </div>
            {mode === 'signup' && (
              <>
                <div className="space-y-2">
                  <Label htmlFor="hotel" className="text-slate-200">Nom de l’établissement</Label>
                  <Input id="hotel" type="text" placeholder="Hôtel Elowah" className="bg-slate-900 border-slate-700 text-white" required />
                </div>
                <div className="space-y-2">
                  <Label htmlFor="phone" className="text-slate-200">Téléphone</Label>
                  <Input id="phone" type="tel" placeholder="+228 ..." className="bg-slate-900 border-slate-700 text-white" required />
                </div>
              </>
            )}
            <div className="space-y-2">
              <Label htmlFor="password" className="text-slate-200">Mot de passe</Label>
              <Input id="password" name="password" type="password" placeholder="••••••••" className="bg-slate-900 border-slate-700 text-white" required />
            </div>
            {mode === 'signup' && (
              <div className="space-y-2">
                <Label htmlFor="confirm" className="text-slate-200">Confirmer le mot de passe</Label>
                <Input id="confirm" type="password" placeholder="••••••••" className="bg-slate-900 border-slate-700 text-white" required />
              </div>
            )}
            {error && <p className="text-sm text-red-300">{error}</p>}
            <Button type="submit" disabled={loading} className="w-full bg-emerald-400 text-slate-950 hover:bg-emerald-300 disabled:opacity-60">
              <LogIn className="mr-2 h-4 w-4" /> {mode === 'login' ? 'Se connecter' : 'Créer mon compte'}
            </Button>
          </form>
          <p className="mt-4 text-center text-sm text-slate-300">
            Besoin d’un onboarding accompagné ? <Link href="/demo" className="text-emerald-200 underline">Demander une démo</Link>
          </p>
        </div>
        <div className="rounded-3xl border border-white/10 bg-gradient-to-br from-emerald-500/20 via-cyan-500/10 to-transparent p-8 text-white">
          <h3 className="text-2xl font-semibold">Pourquoi nous choisir ?</h3>
          <ul className="mt-4 space-y-3 text-sm text-emerald-50">
            <li className="flex gap-2"><ShieldCheck className="h-4 w-4 mt-0.5 text-emerald-200" /> Auth par rôles (réception, direction, housekeeping, finance).</li>
            <li className="flex gap-2"><ShieldCheck className="h-4 w-4 mt-0.5 text-emerald-200" /> Conformité DGT & RGPD, sauvegardes quotidiennes.</li>
            <li className="flex gap-2"><ShieldCheck className="h-4 w-4 mt-0.5 text-emerald-200" /> Support local 7j/7 et onboarding en 30 jours.</li>
          </ul>
          <div className="mt-6 rounded-2xl border border-white/10 bg-white/5 p-4 text-sm text-emerald-50">
            Besoin d’aide ? <a href="mailto:support@togostay.pro" className="text-emerald-200 underline">support@togostay.pro</a> ou WhatsApp +228 90 57 99 46.
          </div>
        </div>
      </div>
    </main>
  );
}

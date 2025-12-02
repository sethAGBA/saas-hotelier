"use client";

import Link from 'next/link';
import { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import { Button } from '@/components/ui/button';
import { Globe, LogIn, LogOut, Menu, X } from 'lucide-react';
import { clearSession, loadSession, subscribeSessionChange } from '@/lib/session';

const navItems = [
  { label: 'Fonctionnalités', href: '/features' },
  { label: 'Tarifs', href: '/pricing' },
  { label: 'Témoignages', href: '/testimonials' },
  { label: 'Ressources', href: '/resources' },
  { label: 'Réservations', href: '/reservations' },
];

// components/Header.tsx
export default function Header() {
  const [open, setOpen] = useState(false);
  const [isLogged, setIsLogged] = useState(false);
  const router = useRouter();

  useEffect(() => {
    const session = loadSession();
    setIsLogged(Boolean(session?.accessToken && session?.tenantId));
    const unsubscribe = subscribeSessionChange(() => {
      const s = loadSession();
      setIsLogged(Boolean(s?.accessToken && s?.tenantId));
    });
    return unsubscribe;
  }, []);

  const handleLogout = () => {
    clearSession();
    setIsLogged(false);
    router.push('/login');
  };

  return (
    <header className="sticky top-0 z-50 border-b border-white/10 bg-slate-950/70 text-white backdrop-blur">
      <nav className="mx-auto flex max-w-7xl items-center justify-between px-6 py-4">
        <Link href="/" className="text-2xl font-semibold text-white">
          HotelFlow <span className="text-emerald-300">Pro</span>
        </Link>
        <div className="hidden items-center gap-6 md:flex">
          {navItems.map((item) => (
            <Link
              key={item.href}
              href={item.href}
              className="text-sm font-medium text-slate-200 transition hover:text-white"
            >
              {item.label}
            </Link>
          ))}
        </div>
        <div className="hidden items-center gap-3 md:flex">
          <Button variant="outline" asChild className="border-emerald-200 text-white hover:bg-white/10">
            <Link href="/demo">Démo</Link>
          </Button>
          {isLogged ? (
            <>
              <Button asChild className="bg-emerald-400 text-slate-950 hover:bg-emerald-300">
                <Link href="/dashboard">Dashboard</Link>
              </Button>
              <Button variant="outline" onClick={handleLogout} className="border-emerald-200 text-white hover:bg-white/10">
                <LogOut className="mr-2 h-4 w-4" /> Déconnexion
              </Button>
            </>
          ) : (
            <Button asChild className="bg-emerald-400 text-slate-950 hover:bg-emerald-300">
              <Link href="/login">
                <LogIn className="mr-2 h-4 w-4" /> Connexion
              </Link>
            </Button>
          )}
          <Globe className="h-5 w-5 text-slate-400" aria-hidden />
        </div>
        <button
          className="md:hidden inline-flex h-10 w-10 items-center justify-center rounded-lg border border-white/15 bg-white/5 text-white"
          onClick={() => setOpen(!open)}
          aria-label="Ouvrir la navigation"
        >
          {open ? <X className="h-5 w-5" /> : <Menu className="h-5 w-5" />}
        </button>
      </nav>
      {open && (
        <div className="md:hidden border-t border-white/10 bg-slate-950/90 px-6 pb-6">
          <div className="flex flex-col gap-3 py-4">
            {navItems.map((item) => (
              <Link
                key={item.href}
                href={item.href}
                className="text-sm font-medium text-slate-200 transition hover:text-white"
                onClick={() => setOpen(false)}
              >
                {item.label}
              </Link>
            ))}
          </div>
          <div className="flex flex-col gap-3">
            <Button variant="outline" asChild className="border-emerald-200 text-white hover:bg-white/10">
              <Link href="/demo" onClick={() => setOpen(false)}>Démo</Link>
            </Button>
            {isLogged ? (
              <>
                <Button asChild className="bg-emerald-400 text-slate-950 hover:bg-emerald-300">
                  <Link href="/dashboard" onClick={() => setOpen(false)}>Dashboard</Link>
                </Button>
                <Button variant="outline" onClick={() => { handleLogout(); setOpen(false); }} className="border-emerald-200 text-white hover:bg-white/10">
                  <LogOut className="mr-2 h-4 w-4" /> Déconnexion
                </Button>
              </>
            ) : (
              <Button asChild className="bg-emerald-400 text-slate-950 hover:bg-emerald-300">
                <Link href="/login" onClick={() => setOpen(false)}>
                  <LogIn className="mr-2 h-4 w-4" /> Connexion
                </Link>
              </Button>
            )}
          </div>
        </div>
      )}
    </header>
  );
}

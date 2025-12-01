"use client";
import Link from 'next/link';

export default function Header() {
  return (
    <header className="border-b bg-white">
      <div className="container mx-auto px-6 py-4 flex items-center justify-between">
        <Link href="/"><a className="font-bold text-xl">TogoStay Pro</a></Link>
        <nav className="space-x-4">
          <Link href="/features"><a>Fonctionnalités</a></Link>
          <Link href="/pricing"><a>Tarifs</a></Link>
          <Link href="/testimonials"><a>Témoignages</a></Link>
          <Link href="/login"><a className="ml-4 px-3 py-1 border rounded">Connexion</a></Link>
        </nav>
      </div>
    </header>
  );
}

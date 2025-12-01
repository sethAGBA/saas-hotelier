"use client";
import Link from 'next/link';

export default function Hero() {
  return (
    <section className="bg-gradient-to-r from-blue-600 to-indigo-600 text-white py-20">
      <div className="container mx-auto px-6">
        <h1 className="text-4xl font-bold">TogoStay Pro — Gestion hôtelière pour le Togo</h1>
        <p className="mt-4 max-w-2xl">Réservations, paiements Flooz, tarification dynamique et site web pour hôtels indépendants.</p>
        <div className="mt-6">
          <Link href="/demo"><a className="px-5 py-3 bg-white text-blue-600 rounded font-semibold">Demandez une démo</a></Link>
        </div>
      </div>
    </section>
  );
}

import Link from 'next/link';
import { MapPin, Phone, Mail, ShieldCheck } from 'lucide-react';
import { Button } from '@/components/ui/button';

// components/Footer.tsx (Inspiré : Liens, Contact, Social)
export default function Footer() {
  return (
    <footer className="bg-slate-950 text-white border-t border-white/10">
      <div className="max-w-7xl mx-auto px-6 py-14 grid grid-cols-1 gap-10 md:grid-cols-4">
        <div className="space-y-3">
          <div className="text-2xl font-semibold">HotelFlow <span className="text-emerald-300">Pro</span></div>
          <p className="text-sm text-slate-200">Suite tout-en-un pour la gestion hôtelière en Afrique de l’Ouest.</p>
          <div className="flex items-center gap-2 text-xs text-emerald-200">
            <ShieldCheck className="h-4 w-4" /> Conformité DGT & RGPD
          </div>
          <Button asChild className="bg-emerald-400 text-slate-950 hover:bg-emerald-300">
            <Link href="/demo">Demander une démo</Link>
          </Button>
        </div>

        <div>
          <h3 className="text-lg font-semibold mb-4">Navigation</h3>
          <ul className="space-y-2 text-sm text-slate-200">
            <li><Link href="/features" className="hover:text-white">Fonctionnalités</Link></li>
            <li><Link href="/pricing" className="hover:text-white">Tarifs</Link></li>
            <li><Link href="/testimonials" className="hover:text-white">Témoignages</Link></li>
            <li><Link href="/login" className="hover:text-white">Connexion</Link></li>
          </ul>
        </div>

        <div>
          <h3 className="text-lg font-semibold mb-4">Ressources</h3>
          <ul className="space-y-2 text-sm text-slate-200">
            <li><Link href="/blog" className="hover:text-white">Blog & Guides</Link></li>
            <li><Link href="/status" className="hover:text-white">Statut du service</Link></li>
            <li><Link href="/help" className="hover:text-white">Centre d’aide & FAQ</Link></li>
            <li>Webinars & ateliers</li>
            <li><Link href="/security" className="hover:text-white">Sécurité & conformité</Link></li>
            <li><Link href="/api" className="hover:text-white">API & intégrations</Link></li>
            <li>Onboarding en 30 jours</li>
            <li>Programme partenaires</li>
            <li>Ressources OTA & channel manager</li>
            <li>Guides Mobile Money (Flooz / T-Money)</li>
          </ul>
        </div>

        <div className="space-y-3">
          <h3 className="text-lg font-semibold">Contact</h3>
          <div className="flex items-start gap-2 text-sm text-slate-200">
            <MapPin className="h-4 w-4 mt-0.5 text-emerald-200" /> Lomé, Togo
          </div>
          <div className="flex items-center gap-2 text-sm text-slate-200">
            <Phone className="h-4 w-4 text-emerald-200" /> +228 90 57 99 46
          </div>
          <div className="flex items-center gap-2 text-sm text-slate-200">
            <Mail className="h-4 w-4 text-emerald-200" /> support@togostay.pro
          </div>
        </div>
      </div>
      <div className="border-t border-white/10 py-4 text-center text-xs text-slate-400">
        © 2025 HotelFlow Pro — Tous droits réservés.
      </div>
    </footer>
  );
}

"use client";
import Link from 'next/link';

export default function CTA({ text = 'Commencez maintenant', href = '/demo' }: { text?: string; href?: string }) {
  return (
    <div className="py-12 text-center">
      <Link href={href}><a className="px-6 py-3 bg-blue-600 text-white rounded font-semibold">{text}</a></Link>
    </div>
  );
}

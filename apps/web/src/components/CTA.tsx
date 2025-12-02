"use client";
import Link from 'next/link';

export default function CTA({ text = 'Commencez maintenant', href = '/demo' }: { text?: string; href?: string }) {
  return (
    <div className="py-12 text-center">
      <Link
        href={href}
        className="inline-flex items-center justify-center rounded-md bg-blue-600 px-6 py-3 font-semibold text-white transition hover:bg-blue-700 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-blue-500"
      >
        {text}
      </Link>
    </div>
  );
}

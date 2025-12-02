"use client";

export default function Integrations() {
  const partners = ['Flooz', 'T-Money', 'Visa', 'Mastercard', 'Booking.com', 'Airbnb', 'Expedia', 'Stripe'];
  return (
    <section className="bg-slate-900 py-14 text-white">
      <div className="max-w-6xl mx-auto px-6">
        <div className="flex flex-col gap-2 text-center">
          <p className="text-sm uppercase tracking-[0.2em] text-emerald-200">Intégrations</p>
          <h2 className="text-3xl font-semibold">Connectée aux solutions que vous utilisez</h2>
          <p className="text-slate-200">Paiements, OTA, channel manager et facturation locale.</p>
        </div>
        <div className="mt-10 grid grid-cols-2 gap-4 md:grid-cols-4">
          {partners.map((p) => (
            <div
              key={p}
              className="rounded-xl border border-white/10 bg-white/5 px-4 py-3 text-center text-sm font-semibold tracking-wide text-white/90"
            >
              {p}
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}

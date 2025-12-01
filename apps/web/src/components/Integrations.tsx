"use client";

export default function Integrations() {
  const partners = ['Flooz', 'MTN MoMo', 'Visa', 'Mastercard'];
  return (
    <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
      {partners.map((p) => (
        <div key={p} className="p-4 border rounded text-center">{p}</div>
      ))}
    </div>
  );
}

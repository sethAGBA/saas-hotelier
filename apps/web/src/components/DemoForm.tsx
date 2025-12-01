"use client";
import { useState } from 'react';

export default function DemoForm() {
  const [name, setName] = useState('');
  const [email, setEmail] = useState('');

  function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    // Replace with real API call
    console.log('Demo request', { name, email });
    alert('Merci — nous vous contacterons bientôt.');
    setName('');
    setEmail('');
  }

  return (
    <form onSubmit={handleSubmit} className="grid gap-4 max-w-md">
      <input value={name} onChange={(e) => setName(e.target.value)} placeholder="Nom de l'hôtel / contact" className="p-3 border rounded" />
      <input value={email} onChange={(e) => setEmail(e.target.value)} placeholder="Email" className="p-3 border rounded" />
      <button type="submit" className="px-4 py-2 bg-blue-600 text-white rounded">Demander une démo</button>
    </form>
  );
}

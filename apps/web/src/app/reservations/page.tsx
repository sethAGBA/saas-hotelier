"use client";

import { useEffect, useState } from "react";
import { CalendarClock, BedDouble, ArrowUpRight, Filter } from "lucide-react";

import { fetchReservations } from "@/lib/apiClient";
import { loadSession } from "@/lib/session";
import type { ReservationDto } from "@/lib/apiClient";

function formatDate(value: string) {
  return new Date(value).toLocaleString("fr-FR", {
    day: "2-digit",
    month: "2-digit",
    hour: "2-digit",
    minute: "2-digit",
  });
}

function formatAmount(value?: string | number | null) {
  const num = typeof value === "string" ? Number(value) : value ?? 0;
  if (Number.isNaN(num)) return "—";
  return `${num.toLocaleString("fr-FR")} FCFA`;
}

const statusColor: Record<string, string> = {
  confirmed: "bg-emerald-500/20 text-emerald-200",
  provisional: "bg-amber-500/20 text-amber-200",
  cancelled: "bg-rose-500/20 text-rose-200",
  checked_in: "bg-blue-500/20 text-blue-200",
  checked_out: "bg-purple-500/20 text-purple-200",
};

export default function ReservationsPage() {
  const [reservations, setReservations] = useState<ReservationDto[]>([]);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    const session = loadSession();
    if (!session?.accessToken || !session.tenantId) {
      setError("Connectez-vous pour voir les réservations.");
      return;
    }
    fetchReservations(session.accessToken, session.tenantId)
      .then(setReservations)
      .catch((err) => {
        console.error(err);
        setError("Impossible de charger les réservations.");
      });
  }, []);

  return (
    <main className="bg-slate-950 text-white min-h-screen">
      <div className="max-w-6xl mx-auto px-6 py-10 space-y-6">
        <header className="flex items-center justify-between gap-4">
          <div>
            <p className="text-sm uppercase tracking-[0.2em] text-emerald-200">Réservations</p>
            <h1 className="text-3xl font-semibold">Planning & arrivées</h1>
            <p className="text-slate-300">Liste des réservations avec statut, montants et chambres.</p>
          </div>
          <div className="flex gap-3">
            <button className="inline-flex items-center gap-2 rounded-lg border border-white/15 bg-white/5 px-4 py-2 text-sm text-white hover:bg-white/10">
              <Filter className="h-4 w-4" /> Filtres
            </button>
            <button className="inline-flex items-center gap-2 rounded-lg bg-emerald-400 px-4 py-2 text-slate-950 font-semibold hover:bg-emerald-300">
              <CalendarClock className="h-4 w-4" /> Nouvelle réservation
            </button>
          </div>
        </header>

        {error && (
          <div className="rounded-xl border border-amber-400/30 bg-amber-400/10 px-4 py-3 text-amber-100">
            {error}
          </div>
        )}

        <div className="grid gap-4">
          {reservations.map((r) => {
            const statusKey = r.status?.toLowerCase() ?? "";
            const chipClass = statusColor[statusKey] ?? "bg-white/10 text-white";
            return (
              <div key={r.id} className="rounded-2xl border border-white/10 bg-white/5 p-4 shadow">
                <div className="flex flex-wrap items-center justify-between gap-3">
                  <div className="flex items-center gap-3">
                    <div className="flex h-10 w-10 items-center justify-center rounded-lg bg-emerald-400/15 text-emerald-200">
                      <BedDouble className="h-5 w-5" />
                    </div>
                    <div>
                      <p className="text-lg font-semibold text-white">{r.guestName}</p>
                      <p className="text-sm text-slate-300">
                        Chambre {r.room?.number ?? "—"} · {formatDate(r.checkIn)} → {formatDate(r.checkOut)}
                      </p>
                    </div>
                  </div>
                  <div className="flex items-center gap-2 text-sm">
                    <span className={`rounded-full px-3 py-1 ${chipClass}`}>{r.status}</span>
                    <span className="text-slate-200">{formatAmount(r.amount)}</span>
                  </div>
                </div>
                <div className="mt-3 flex items-center gap-4 text-sm text-slate-300">
                  <span>Source: {r.source ?? "—"}</span>
                  <span>Acompte: {formatAmount(r.deposit)}</span>
                </div>
              </div>
            );
          })}
          {reservations.length === 0 && !error && (
            <div className="rounded-xl border border-white/10 bg-white/5 p-6 text-slate-200">
              Aucune réservation à afficher.
            </div>
          )}
        </div>
      </div>
    </main>
  );
}

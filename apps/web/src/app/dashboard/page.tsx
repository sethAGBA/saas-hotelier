/* eslint-disable react-hooks/set-state-in-effect */
"use client";

import {
  BarChart3,
  BedDouble,
  CalendarCheck,
  CreditCard,
  Sparkles,
  ArrowUpRight,
  ShieldCheck,
  Bell,
} from "lucide-react";
import { useEffect, useMemo, useState } from "react";
import { loadSession } from "@/lib/session";

import type { ReservationDto, RoomDto } from "@/lib/apiClient";
import { fetchReservations, fetchRooms } from "@/lib/apiClient";

type DashboardStats = {
  occupation: string;
  adr: string;
  revpar: string;
  noShow: string;
};

function computeStats(reservations: ReservationDto[], rooms: RoomDto[]): DashboardStats {
  const occupied = rooms.filter((r) => r.status?.toLowerCase() === "occupied").length;
  const totalRooms = rooms.length || 1;
  const occupation = Math.round((occupied / totalRooms) * 100);

  const amounts = reservations
    .map((r) => Number(r.amount ?? 0))
    .filter((v) => !Number.isNaN(v));
  const adr = amounts.length ? Math.round(amounts.reduce((a, b) => a + b, 0) / amounts.length) : 0;
  // Simple revpar approximation: ADR * occupation
  const revpar = Math.round(adr * (occupation / 100));
  const noShow = reservations.filter((r) => r.status?.toLowerCase() === "no_show").length;

  return {
    occupation: `${occupation}%`,
    adr: `${adr.toLocaleString("fr-FR")} FCFA`,
    revpar: `${revpar.toLocaleString("fr-FR")} FCFA`,
    noShow: `${noShow}`,
  };
}

function formatAmount(value: string | number) {
  const num = typeof value === "string" ? Number(value) : value;
  if (Number.isNaN(num)) return value.toString();
  return `${num.toLocaleString("fr-FR")} FCFA`;
}

export default function DashboardPage() {
  const saved = typeof window !== "undefined" ? loadSession() : null;
  const token = saved?.accessToken;
  const tenantId = saved?.tenantId;
  const [rooms, setRooms] = useState<RoomDto[]>([]);
  const [reservations, setReservations] = useState<ReservationDto[]>([]);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (!token || !tenantId) return;
    let cancelled = false;
    setError(null);
    Promise.all([fetchRooms(token, tenantId), fetchReservations(token, tenantId)])
      .then(([r, res]) => {
        if (cancelled) return;
        setRooms(r);
        setReservations(res);
      })
      .catch((err) => {
        if (cancelled) return;
        console.error("API error", err);
        setError("Impossible de charger les données en direct");
      })
      .finally(() => {});
    return () => {
      cancelled = true;
    };
  }, [token, tenantId]);

  const stats = useMemo(() => computeStats(reservations, rooms), [reservations, rooms]);
  const statCards = [
    { label: "Taux d'occupation", value: stats.occupation, trend: "", icon: BedDouble },
    { label: "ADR", value: stats.adr, trend: "", icon: BarChart3 },
    { label: "RevPAR", value: stats.revpar, trend: "", icon: BarChart3 },
    { label: "No-show", value: stats.noShow, trend: "", icon: ShieldCheck },
  ];
  const arrivals = useMemo(
    () =>
      reservations
        .slice(0, 5)
        .map((r) => ({
          guest: r.guestName,
          room: r.room?.number ?? "—",
          eta: new Date(r.checkIn).toLocaleString("fr-FR", { day: "2-digit", month: "2-digit", hour: "2-digit", minute: "2-digit" }),
          status: r.status,
        })) ?? [],
    [reservations],
  );
  const housekeeping = rooms.slice(0, 3).map((r) => ({
    room: r.number,
    status: r.status,
    assignee: "—",
    eta: "—",
  }));
  const payments = reservations.slice(0, 3).map((r) => ({
    ref: r.id,
    amount: formatAmount(r.amount ?? 0),
    method: r.source ?? "—",
    status: r.status,
  }));

  return (
    <main className="bg-slate-950 text-white min-h-screen">
      <div className="max-w-7xl mx-auto px-6 py-10 space-y-8">
        <header className="flex flex-wrap items-center justify-between gap-4">
          <div>
            <p className="text-sm uppercase tracking-[0.2em] text-emerald-200">Backoffice</p>
            <h1 className="text-3xl font-semibold">Vue d’ensemble</h1>
            <p className="text-slate-300">Occupations, arrivées, housekeeping et encaissements en un coup d’œil.</p>
          </div>
          <div className="flex flex-wrap gap-3">
            <button className="inline-flex items-center gap-2 rounded-lg bg-emerald-400 px-4 py-2 text-slate-950 font-semibold hover:bg-emerald-300">
              <CalendarCheck className="h-4 w-4" /> Nouvelle réservation
            </button>
            <button className="inline-flex items-center gap-2 rounded-lg border border-emerald-200 px-4 py-2 text-white hover:bg-white/10">
              <Sparkles className="h-4 w-4" /> Planifier pricing
            </button>
          </div>
        </header>

        <section className="grid grid-cols-1 gap-4 md:grid-cols-2 lg:grid-cols-4">
          {statCards.map((s) => (
            <div key={s.label} className="rounded-2xl border border-white/10 bg-white/5 p-4 shadow">
              <div className="flex items-center justify-between">
                <div className="flex h-10 w-10 items-center justify-center rounded-lg bg-emerald-400/15 text-emerald-200">
                  <s.icon className="h-5 w-5" />
                </div>
                <span className="text-xs text-emerald-200">{s.trend}</span>
              </div>
              <p className="mt-4 text-2xl font-semibold">{s.value}</p>
              <p className="text-sm text-slate-300">{s.label}</p>
            </div>
          ))}
        </section>

        <section className="grid grid-cols-1 gap-6 lg:grid-cols-[1.1fr_0.9fr]">
          <div className="rounded-2xl border border-white/10 bg-white/5 p-6">
            <div className="flex items-center justify-between">
              <h2 className="text-xl font-semibold">Arrivées du jour</h2>
              <button className="text-sm text-emerald-200 hover:underline">Tout voir</button>
            </div>
            <div className="mt-4 divide-y divide-white/5 text-sm">
          {(arrivals.length ? arrivals : [{ guest: "—", room: "—", eta: "—", status: error ?? "Connecte-toi pour voir" }]).map((a) => (
            <div key={a.guest + a.room} className="flex items-center justify-between py-3">
              <div>
                <p className="font-semibold text-white">{a.guest}</p>
                <p className="text-slate-300">{a.status}</p>
              </div>
              <div className="text-right">
                    <p className="font-semibold">{a.room}</p>
                    <p className="text-slate-300">{a.eta}</p>
                  </div>
                </div>
              ))}
            </div>
          </div>
          <div className="rounded-2xl border border-white/10 bg-white/5 p-6 space-y-4">
            <div className="flex items-center justify-between">
              <h2 className="text-xl font-semibold">Housekeeping</h2>
              <button className="text-sm text-emerald-200 hover:underline">Voir planning</button>
            </div>
            <div className="space-y-3 text-sm">
              {(housekeeping.length ? housekeeping : [{ room: "—", status: error ?? "Pas de données", assignee: "—", eta: "—" }]).map((h) => (
                <div key={h.room} className="rounded-xl border border-white/5 bg-slate-900/60 px-4 py-3">
                  <div className="flex items-center justify-between">
                    <span className="font-semibold">{h.room}</span>
                    <span className="text-xs rounded-full bg-emerald-400/15 px-3 py-1 text-emerald-100">{h.status}</span>
                  </div>
                  <div className="mt-1 flex justify-between text-slate-300">
                    <span>{h.assignee}</span>
                    <span>{h.eta}</span>
                  </div>
                </div>
              ))}
            </div>
          </div>
        </section>

        <section className="grid grid-cols-1 gap-6 lg:grid-cols-[1.1fr_0.9fr]">
          <div className="rounded-2xl border border-white/10 bg-white/5 p-6">
            <div className="flex items-center justify-between">
              <h2 className="text-xl font-semibold">Encaissements récents</h2>
              <button className="text-sm text-emerald-200 hover:underline">Exporter</button>
            </div>
            <div className="mt-4 divide-y divide-white/5 text-sm">
              {(payments.length ? payments : [{ ref: "#", amount: "—", method: "—", status: error ?? "Pas de données" }]).map((p) => (
                <div key={p.ref} className="flex items-center justify-between py-3">
                  <div>
                    <p className="font-semibold text-white">{p.ref}</p>
                    <p className="text-slate-300">{p.method}</p>
                  </div>
                  <div className="text-right">
                    <p className="font-semibold">{p.amount}</p>
                    <p className="text-emerald-200">{p.status}</p>
                  </div>
                </div>
              ))}
            </div>
            <div className="mt-4 flex items-center gap-2 text-xs text-emerald-200">
              <CreditCard className="h-4 w-4" /> Flooz, T-Money, CB, POS et factures folios.
            </div>
          </div>

          <div className="rounded-2xl border border-white/10 bg-white/5 p-6 space-y-4">
            <div className="flex items-center justify-between">
              <h2 className="text-xl font-semibold">Alertes</h2>
              <button className="text-sm text-emerald-200 hover:underline">Centre de notifications</button>
            </div>
            <div className="space-y-3 text-sm text-slate-200">
              <AlertItem icon={<Bell className="h-4 w-4" />} text="2 chambres en maintenance : 217, 304" />
              <AlertItem icon={<Bell className="h-4 w-4" />} text="No-show prévu : 1 réservation sans garantie" />
              <AlertItem icon={<Bell className="h-4 w-4" />} text="Stock minibar bas (Bâtiment A)" />
            </div>
            <button className="inline-flex items-center gap-2 rounded-lg border border-emerald-200 px-4 py-2 text-sm text-white hover:bg-white/10">
              <ArrowUpRight className="h-4 w-4" /> Ouvrir le channel manager
            </button>
          </div>
        </section>
      </div>
    </main>
  );
}

function AlertItem({ icon, text }: { icon: React.ReactNode; text: string }) {
  return (
    <div className="flex items-center gap-2 rounded-xl border border-white/5 bg-slate-900/60 px-4 py-3">
      <span className="text-emerald-200">{icon}</span>
      <span>{text}</span>
    </div>
  );
}

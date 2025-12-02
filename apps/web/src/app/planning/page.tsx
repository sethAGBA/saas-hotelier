"use client";

import { useEffect, useMemo, useState } from "react";
import { Calendar, Clock, Loader2, MapPin, ArrowUpRight } from "lucide-react";

import { fetchReservations, fetchRooms } from "@/lib/apiClient";
import { loadSession } from "@/lib/session";
import type { ReservationDto, RoomDto } from "@/lib/apiClient";

function formatDate(value: string) {
  const d = new Date(value);
  return d.toLocaleDateString("fr-FR", { day: "2-digit", month: "2-digit" }) + " " + d.toLocaleTimeString("fr-FR", { hour: "2-digit", minute: "2-digit" });
}

function statusColor(status?: string) {
  const s = (status ?? "").toLowerCase();
  if (s === "confirmed") return "bg-emerald-500/20 text-emerald-200";
  if (s === "provisional") return "bg-amber-500/20 text-amber-200";
  if (s === "cancelled") return "bg-rose-500/20 text-rose-200";
  if (s === "checked_in") return "bg-blue-500/20 text-blue-200";
  if (s === "checked_out") return "bg-purple-500/20 text-purple-200";
  return "bg-white/10 text-white";
}

export default function PlanningPage() {
  const session = typeof window !== "undefined" ? loadSession() : null;
  const token = session?.accessToken;
  const tenantId = session?.tenantId;
  const [rooms, setRooms] = useState<RoomDto[]>([]);
  const [reservations, setReservations] = useState<ReservationDto[]>([]);
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    if (!token || !tenantId) {
      setError("Connectez-vous pour voir le planning.");
      return;
    }
    setLoading(true);
    Promise.all([fetchRooms(token, tenantId), fetchReservations(token, tenantId)])
      .then(([r, res]) => {
        setRooms(r);
        setReservations(res);
      })
      .catch((err) => {
        console.error(err);
        setError("Impossible de charger les données.");
      })
      .finally(() => setLoading(false));
  }, [token, tenantId]);

  const roomMap = useMemo(() => {
    const map = new Map<string, RoomDto>();
    rooms.forEach((r) => map.set(r.id, r));
    return map;
  }, [rooms]);

  return (
    <main className="bg-slate-950 text-white min-h-screen">
      <div className="max-w-6xl mx-auto px-6 py-10 space-y-6">
        <header className="flex items-center justify-between gap-4">
          <div>
            <p className="text-sm uppercase tracking-[0.2em] text-emerald-200">Planning</p>
            <h1 className="text-3xl font-semibold">Réservations (timeline)</h1>
            <p className="text-slate-300">Vue simple des réservations avec horaires.</p>
          </div>
        </header>

        {error && (
          <div className="rounded-xl border border-amber-400/30 bg-amber-400/10 px-4 py-3 text-amber-100">
            {error}
          </div>
        )}

        {loading ? (
          <div className="flex items-center gap-2 text-slate-200"><Loader2 className="h-4 w-4 animate-spin" /> Chargement...</div>
        ) : (
          <div className="space-y-3">
            {reservations.map((res) => {
              const room = res.room ?? (res.roomId ? roomMap.get(res.roomId) : undefined);
              return (
                <div key={res.id} className="rounded-2xl border border-white/10 bg-white/5 p-4">
                  <div className="flex flex-wrap items-center justify-between gap-3">
                    <div className="flex items-center gap-3">
                      <div className="flex h-10 w-10 items-center justify-center rounded-lg bg-emerald-400/15 text-emerald-200">
                        <Calendar className="h-5 w-5" />
                      </div>
                      <div>
                        <p className="text-lg font-semibold text-white">{res.guestName}</p>
                        <p className="text-sm text-slate-300">
                          Chambre {room?.number ?? "—"} · {room?.type ?? ""}
                        </p>
                      </div>
                    </div>
                    <span className={`rounded-full px-3 py-1 text-xs uppercase ${statusColor(res.status)}`}>{res.status}</span>
                  </div>
                  <div className="mt-3 grid grid-cols-1 gap-2 text-sm text-slate-200 md:grid-cols-3">
                    <div className="flex items-center gap-2"><Clock className="h-4 w-4 text-emerald-200" /> {formatDate(res.checkIn)} → {formatDate(res.checkOut)}</div>
                    <div className="flex items-center gap-2"><MapPin className="h-4 w-4 text-emerald-200" /> {room?.floor ? `Étage ${room.floor}` : 'Étage ?'}</div>
                    <div className="flex items-center gap-2"><ArrowUpRight className="h-4 w-4 text-emerald-200" /> Source: {res.source ?? '—'}</div>
                  </div>
                </div>
              );
            })}
            {reservations.length === 0 && !error && (
              <div className="rounded-xl border border-white/10 bg-white/5 p-6 text-slate-200">
                Aucune réservation.
              </div>
            )}
          </div>
        )}
      </div>
    </main>
  );
}

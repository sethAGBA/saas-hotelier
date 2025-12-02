// Simple client-side fetcher to call the Nest API with JWT + tenant header.
export type RoomDto = {
  id: string;
  number: string;
  type?: string;
  status: string;
  floor?: string;
};

export type ReservationDto = {
  id: string;
  guestName: string;
  status: string;
  amount?: number | string | null;
  deposit?: number | string | null;
  checkIn: string;
  checkOut: string;
  room?: RoomDto;
};

const baseUrl =
  process.env.NEXT_PUBLIC_API_BASE_URL ??
  process.env.API_BASE_URL ??
  'http://localhost:4000';

async function apiGet<T>({
  path,
  token,
  tenantId,
}: {
  path: string;
  token?: string | null;
  tenantId?: string | null;
}): Promise<T> {
  const headers: Record<string, string> = {
    'Content-Type': 'application/json',
  };
  if (token) headers['Authorization'] = `Bearer ${token}`;
  if (tenantId) headers['X-Tenant-Id'] = tenantId;

  const resp = await fetch(`${baseUrl}${path}`, {
    headers,
    cache: 'no-cache',
  });
  if (!resp.ok) {
    throw new Error(`API ${resp.status} ${resp.statusText}`);
  }
  return (await resp.json()) as T;
}

export async function fetchRooms(token?: string | null, tenantId?: string | null) {
  return apiGet<RoomDto[]>({ path: '/api/rooms', token, tenantId });
}

export async function fetchReservations(token?: string | null, tenantId?: string | null) {
  return apiGet<ReservationDto[]>({ path: '/api/reservations', token, tenantId });
}

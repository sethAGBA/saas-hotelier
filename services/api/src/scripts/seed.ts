/* Simple seed: creates/updates a tenant and an admin user. */
import 'dotenv/config';
import {
  PrismaClient,
  UserRole,
  RoomStatus,
  ReservationStatus,
} from '@prisma/client';
import { hash } from 'bcryptjs';

const prisma = new PrismaClient();

async function main() {
  const tenantSlug = process.env.SEED_TENANT_SLUG ?? 'demo';
  const tenantName = process.env.SEED_TENANT_NAME ?? 'Demo Hotel';
  const adminEmail = (process.env.SEED_ADMIN_EMAIL ?? 'admin@demo.tld').toLowerCase();
  const adminPassword = process.env.SEED_ADMIN_PASSWORD ?? 'Password123!';

  const tenant = await prisma.tenant.upsert({
    where: { slug: tenantSlug },
    update: { name: tenantName },
    create: { slug: tenantSlug, name: tenantName },
  });

  const passwordHash = await hash(adminPassword, 10);

  await prisma.user.upsert({
    where: { email: adminEmail },
    update: {
      passwordHash,
      tenantId: tenant.id,
      role: UserRole.ADMIN,
      isActive: true,
    },
    create: {
      email: adminEmail,
      passwordHash,
      tenantId: tenant.id,
      role: UserRole.ADMIN,
      isActive: true,
    },
  });

  const roomsToSeed = [
    { number: '101', type: 'Standard', floor: '1', status: RoomStatus.AVAILABLE },
    { number: '102', type: 'Standard', floor: '1', status: RoomStatus.OCCUPIED },
    { number: '201', type: 'Deluxe', floor: '2', status: RoomStatus.AVAILABLE },
    { number: '301', type: 'Suite', floor: '3', status: RoomStatus.MAINTENANCE },
  ];

  for (const room of roomsToSeed) {
    await prisma.room.upsert({
      where: {
        tenantId_number: {
          tenantId: tenant.id,
          number: room.number,
        },
      },
      update: {
        type: room.type,
        floor: room.floor,
        status: room.status,
      },
      create: {
        tenantId: tenant.id,
        number: room.number,
        type: room.type,
        floor: room.floor,
        status: room.status,
      },
    });
  }

  const existingReservations = await prisma.reservation.count({
    where: { tenantId: tenant.id },
  });

  if (existingReservations === 0) {
    const rooms = await prisma.room.findMany({
      where: { tenantId: tenant.id },
    });
    const room101 = rooms.find((r) => r.number === '101');
    const room201 = rooms.find((r) => r.number === '201');

    await prisma.reservation.create({
      data: {
        tenantId: tenant.id,
        guestName: 'A. Mensah',
        checkIn: new Date(),
        checkOut: new Date(Date.now() + 2 * 24 * 60 * 60 * 1000),
        status: ReservationStatus.CONFIRMED,
        amount: 120000,
        deposit: 40000,
        source: 'Direct',
        roomId: room101?.id,
      },
    });

    await prisma.reservation.create({
      data: {
        tenantId: tenant.id,
        guestName: 'S. Akouvi',
        checkIn: new Date(Date.now() + 1 * 24 * 60 * 60 * 1000),
        checkOut: new Date(Date.now() + 3 * 24 * 60 * 60 * 1000),
        status: ReservationStatus.PROVISIONAL,
        amount: 180000,
        deposit: 60000,
        source: 'Booking.com',
        roomId: room201?.id,
      },
    });
  }

  // eslint-disable-next-line no-console
  console.log('Seed completed', {
    tenant: { id: tenant.id, slug: tenant.slug },
    admin: { email: adminEmail, role: UserRole.ADMIN },
  });
}

main()
  .catch((err) => {
    // eslint-disable-next-line no-console
    console.error('Seed failed', err);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });

import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { Prisma, ReservationStatus } from '@prisma/client';

import { PrismaService } from '../../db/prisma.service';

@Injectable()
export class ReservationsService {
  constructor(private readonly prisma: PrismaService) {}

  private get tenantId(): string {
    const tenantId = this.prisma.tenantId;
    if (!tenantId) throw new BadRequestException('Tenant manquant');
    return tenantId;
  }

  list() {
    return this.prisma.reservation.findMany({
      where: { tenantId: this.tenantId },
      orderBy: [{ checkIn: 'desc' }],
      include: { room: true },
    });
  }

  async create(input: Prisma.ReservationCreateInput) {
    const tenantId = this.tenantId;

    if (input.room?.connect?.id) {
      const room = await this.prisma.room.findFirst({
        where: { id: input.room.connect.id, tenantId },
      });
      if (!room) {
        throw new NotFoundException('Chambre introuvable pour ce tenant');
      }
    }

    return this.prisma.reservation.create({
      data: { ...input, tenant: { connect: { id: tenantId } } },
      include: { room: true },
    });
  }

  async updateStatus(id: string, status: ReservationStatus) {
    const tenantId = this.tenantId;
    return this.prisma.reservation.update({
      where: { id },
      data: { status },
      include: { room: true },
    });
  }
}

import { Injectable, BadRequestException } from '@nestjs/common';
import { Prisma, RoomStatus } from '@prisma/client';

import { PrismaService } from '../../db/prisma.service';

@Injectable()
export class RoomsService {
  constructor(private readonly prisma: PrismaService) {}

  private get tenantId(): string {
    const tenantId = this.prisma.tenantId;
    if (!tenantId) {
      throw new BadRequestException('Tenant manquant');
    }
    return tenantId;
  }

  list() {
    return this.prisma.room.findMany({
      where: { tenantId: this.tenantId },
      orderBy: [{ number: 'asc' }],
    });
  }

  create(data: Prisma.RoomCreateInput) {
    return this.prisma.room.create({
      data: { ...data, tenant: { connect: { id: this.tenantId } } },
    });
  }

  updateStatus(id: string, status: RoomStatus) {
    return this.prisma.room.update({
      where: { id },
      data: { status },
    });
  }
}

import { Injectable } from '@nestjs/common';
import { Prisma, User } from '@prisma/client';

import { PrismaService } from '../../db/prisma.service';

@Injectable()
export class UserService {
  constructor(private readonly prisma: PrismaService) {}

  private get tenantId(): string | null {
    return this.prisma.tenantId;
  }

  async findByEmail(email: string): Promise<User | null> {
    const tenantId = this.tenantId;
    return this.prisma.user.findFirst({
      where: { email: email.toLowerCase(), tenantId: tenantId ?? undefined },
    });
  }

  async create(data: Prisma.UserCreateInput): Promise<User> {
    return this.prisma.user.create({ data });
  }
}

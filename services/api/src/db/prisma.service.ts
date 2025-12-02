import { Injectable, OnModuleDestroy, OnModuleInit } from '@nestjs/common';
import { PrismaClient } from '@prisma/client';

import { TenantContext } from '../tenancy/tenant.context';

@Injectable()
export class PrismaService
  extends PrismaClient
  implements OnModuleInit, OnModuleDestroy {
  constructor(private readonly tenantContext: TenantContext) {
    super({
      log: [{ emit: 'stdout', level: 'warn' }],
    });
  }

  async onModuleInit() {
    await this.$connect();
  }

  async onModuleDestroy() {
    await this.$disconnect();
  }

  /** Helper to ensure queries always include tenantId where applicable. */
  get tenantId(): string | null {
    return this.tenantContext.tenantId;
  }
}

import { Module } from '@nestjs/common';

import { PrismaService } from '../../db/prisma.service';
import { TenancyModule } from '../../tenancy/tenancy.module';
import { TenantService } from './tenant.service';

@Module({
  imports: [TenancyModule],
  providers: [PrismaService, TenantService],
  exports: [TenantService],
})
export class TenantModule {}

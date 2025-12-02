import { Module } from '@nestjs/common';

import { AuthModule } from '../../auth/auth.module';
import { PrismaService } from '../../db/prisma.service';
import { TenancyModule } from '../../tenancy/tenancy.module';
import { ReservationsService } from './reservations.service';
import { ReservationsController } from './reservations.controller';

@Module({
  imports: [TenancyModule, AuthModule],
  providers: [PrismaService, ReservationsService],
  controllers: [ReservationsController],
})
export class ReservationsModule {}

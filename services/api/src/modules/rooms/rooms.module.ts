import { Module } from '@nestjs/common';

import { AuthModule } from '../../auth/auth.module';
import { PrismaService } from '../../db/prisma.service';
import { TenancyModule } from '../../tenancy/tenancy.module';
import { RoomsService } from './rooms.service';
import { RoomsController } from './rooms.controller';

@Module({
  imports: [TenancyModule, AuthModule],
  providers: [PrismaService, RoomsService],
  controllers: [RoomsController],
})
export class RoomsModule {}

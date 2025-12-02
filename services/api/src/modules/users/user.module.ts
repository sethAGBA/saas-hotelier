import { Module } from '@nestjs/common';

import { PrismaService } from '../../db/prisma.service';
import { TenancyModule } from '../../tenancy/tenancy.module';
import { UserService } from './user.service';

@Module({
  imports: [TenancyModule],
  providers: [PrismaService, UserService],
  exports: [UserService],
})
export class UserModule {}

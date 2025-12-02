import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';

import { AuthModule } from './auth/auth.module';
import { HealthModule } from './modules/health/health.module';
import { ReservationsModule } from './modules/reservations/reservations.module';
import { RoomsModule } from './modules/rooms/rooms.module';
import { TenantModule } from './modules/tenants/tenant.module';
import { UserModule } from './modules/users/user.module';
import { TenancyModule } from './tenancy/tenancy.module';

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
      envFilePath: ['.env', '.env.local'],
    }),
    TenancyModule,
    TenantModule,
    UserModule,
    AuthModule,
    RoomsModule,
    ReservationsModule,
    HealthModule,
  ],
})
export class AppModule {}

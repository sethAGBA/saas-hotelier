import { Module } from '@nestjs/common';

import { TenancyModule } from '../../tenancy/tenancy.module';
import { HealthController } from './health.controller';

@Module({
  imports: [TenancyModule],
  controllers: [HealthController],
})
export class HealthModule {}

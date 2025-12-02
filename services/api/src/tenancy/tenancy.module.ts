import { Module } from '@nestjs/common';
import { APP_INTERCEPTOR } from '@nestjs/core';

import { TenantInterceptor } from './tenant.interceptor';
import { TenancyService } from './tenancy.service';
import { TenantContext } from './tenant.context';

@Module({
  providers: [
    TenancyService,
    TenantContext,
    {
      provide: APP_INTERCEPTOR,
      useClass: TenantInterceptor,
    },
  ],
  exports: [TenancyService, TenantContext],
})
export class TenancyModule {}

import { Controller, Get } from '@nestjs/common';

import { TenantContext } from '../../tenancy/tenant.context';

@Controller('health')
export class HealthController {
  constructor(private readonly tenantContext: TenantContext) {}

  @Get()
  heartbeat() {
    return {
      status: 'ok',
      uptime: process.uptime(),
      timestamp: new Date().toISOString(),
      tenant: this.tenantContext.tenantId,
    };
  }

  @Get('ready')
  readiness() {
    // Extend with DB/cache checks when wired.
    return {
      status: 'ready',
      dependencies: {
        database: 'not-configured',
        cache: 'not-configured',
      },
      timestamp: new Date().toISOString(),
      tenant: this.tenantContext.tenantId,
    };
  }
}

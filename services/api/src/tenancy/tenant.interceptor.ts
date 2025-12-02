import {
  CallHandler,
  ExecutionContext,
  Injectable,
  NestInterceptor,
} from '@nestjs/common';

import { TenancyService } from './tenancy.service';
import { TenantContext } from './tenant.context';

@Injectable()
export class TenantInterceptor implements NestInterceptor {
  constructor(
    private readonly tenancy: TenancyService,
    private readonly context: TenantContext,
  ) {}

  intercept(context: ExecutionContext, next: CallHandler) {
    const request = context.switchToHttp().getRequest();
    const tenantId = this.tenancy.resolveTenantId(request);
    return this.context.run(tenantId, () => next.handle());
  }
}

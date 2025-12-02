import { Injectable } from '@nestjs/common';
import type { Request } from 'express';

@Injectable()
export class TenancyService {
  resolveTenantId(request: Request): string | null {
    const header =
      (request.headers['x-tenant-id'] as string | undefined) ??
      (request.headers['x-tenant'] as string | undefined);
    const query = request.query?.tenant as string | undefined;
    const candidate = (header ?? query ?? '').trim();
    return candidate.length > 0 ? candidate : null;
  }
}

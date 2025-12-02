import {
  CanActivate,
  ExecutionContext,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';

@Injectable()
export class TenantGuard implements CanActivate {
  canActivate(context: ExecutionContext): boolean {
    const request = context.switchToHttp().getRequest();
    const tenantHeader =
      (request.headers['x-tenant-id'] as string | undefined) ??
      (request.headers['x-tenant'] as string | undefined);
    const tenantQuery = request.query?.tenant as string | undefined;
    const tenantFromHeader = (tenantHeader ?? tenantQuery ?? '').trim() || null;
    const userTenant = (request.user?.tenantId as string | undefined) ?? null;

    if (!userTenant) {
      throw new UnauthorizedException('Tenant manquant dans le token');
    }
    if (tenantFromHeader && tenantFromHeader !== userTenant) {
      throw new UnauthorizedException('Tenant du header incompatible');
    }
    // enforce request tenant to match JWT tenant
    request.tenantId = userTenant;
    return true;
  }
}

import { Injectable, UnauthorizedException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { UserRole } from '@prisma/client';
import { compare } from 'bcryptjs';

import { UserService } from '../modules/users/user.service';
import { TenantService } from '../modules/tenants/tenant.service';

export interface JwtPayload {
  sub: string;
  email: string;
  tenantId: string;
  role: UserRole;
}

@Injectable()
export class AuthService {
  constructor(
    private readonly users: UserService,
    private readonly tenants: TenantService,
    private readonly jwt: JwtService,
  ) {}

  async validateTenant(tenant: string) {
    const byId = await this.tenants.findById(tenant);
    if (byId) return byId;
    const bySlug = await this.tenants.findBySlug(tenant);
    if (bySlug) return bySlug;
    throw new UnauthorizedException('Tenant inconnu');
  }

  async login({
    tenant,
    email,
    password,
  }: {
    tenant: string;
    email: string;
    password: string;
  }) {
    const tenantEntity = await this.validateTenant(tenant);
    const user = await this.users.findByEmail(email);
    if (!user || user.tenantId !== tenantEntity.id || !user.isActive) {
      throw new UnauthorizedException('Identifiants invalides');
    }
    const valid = await compare(password, user.passwordHash);
    if (!valid) {
      throw new UnauthorizedException('Identifiants invalides');
    }

    const payload: JwtPayload = {
      sub: user.id,
      email: user.email,
      tenantId: tenantEntity.id,
      role: user.role,
    };
    const token = await this.jwt.signAsync(payload);
    return { accessToken: token, user: payload };
  }
}

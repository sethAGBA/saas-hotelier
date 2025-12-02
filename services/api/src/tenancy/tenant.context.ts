import { Injectable } from '@nestjs/common';
import { AsyncLocalStorage } from 'async_hooks';

@Injectable()
export class TenantContext {
  private readonly storage = new AsyncLocalStorage<string | null>();

  run<T>(tenantId: string | null, handler: () => T): T {
    return this.storage.run(tenantId, handler);
  }

  get tenantId(): string | null {
    return this.storage.getStore() ?? null;
  }
}

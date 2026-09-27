import { auditLogs, type Db, type Tx } from '@plengo/db';

/** Every sensitive admin action is attributed to the acting admin (spec §0.3, §32). */
export function createAuditService(db: Db, hashIp: (ip: string) => string | null) {
  return {
    async record(
      entry: {
        actorAdminId: string | null;
        action: string;
        resourceType: string;
        resourceId?: string | null;
        metadata?: Record<string, unknown>;
        ip?: string | null;
      },
      conn: Db | Tx = db,
    ) {
      await conn.insert(auditLogs).values({
        actorAdminId: entry.actorAdminId,
        action: entry.action,
        resourceType: entry.resourceType,
        resourceId: entry.resourceId ?? null,
        metadata: entry.metadata ?? {},
        ipHash: entry.ip ? hashIp(entry.ip) : null,
      });
    },
  };
}

export type AuditService = ReturnType<typeof createAuditService>;

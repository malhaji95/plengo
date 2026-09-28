import { and, count, desc, eq, gt, inArray, sql } from 'drizzle-orm';
import { contentReports, users, type Db } from '@plengo/db';

export type ReportRow = typeof contentReports.$inferSelect;
export type ReportFilter = {
  status?: ReportRow['status'] | undefined;
  itemType?: ReportRow['itemType'] | undefined;
  reason?: ReportRow['reason'] | undefined;
  /** Only these items (a subject filter resolved to item ids by the service). */
  itemIds?: string[] | undefined;
};

/** Content problem reports (§21). */
export function createReportRepository(db: Db) {
  return {
    insert: async (values: typeof contentReports.$inferInsert) =>
      (await db.insert(contentReports).values(values).returning())[0]!,

    async openByStudentItem(userId: string, itemType: ReportRow['itemType'], itemId: string) {
      const [row] = await db
        .select()
        .from(contentReports)
        .where(
          and(
            eq(contentReports.userId, userId),
            eq(contentReports.itemType, itemType),
            eq(contentReports.itemId, itemId),
            eq(contentReports.status, 'open'),
          ),
        );
      return row ?? null;
    },

    async countSince(userId: string, since: Date) {
      const [row] = await db
        .select({ n: count() })
        .from(contentReports)
        .where(and(eq(contentReports.userId, userId), gt(contentReports.createdAt, since)));
      return row!.n;
    },

    mine: (userId: string, limit: number) =>
      db
        .select()
        .from(contentReports)
        .where(eq(contentReports.userId, userId))
        .orderBy(desc(contentReports.createdAt))
        .limit(limit),

    /** Newest first, with the reporting student. */
    list: (f: ReportFilter, limit: number, offset: number) =>
      db
        .select({ report: contentReports, name: users.name, email: users.email })
        .from(contentReports)
        .innerJoin(users, eq(users.id, contentReports.userId))
        .where(
          and(
            f.status ? eq(contentReports.status, f.status) : undefined,
            f.itemType ? eq(contentReports.itemType, f.itemType) : undefined,
            f.reason ? eq(contentReports.reason, f.reason) : undefined,
            f.itemIds
              ? f.itemIds.length
                ? inArray(contentReports.itemId, f.itemIds)
                : sql`false`
              : undefined,
          ),
        )
        .orderBy(desc(contentReports.createdAt), desc(contentReports.id))
        .limit(limit)
        .offset(offset),

    /** Open reports per item. */
    async openCounts(itemIds: string[]) {
      if (!itemIds.length) return new Map<string, number>();
      const rows = await db
        .select({ itemId: contentReports.itemId, n: count() })
        .from(contentReports)
        .where(and(inArray(contentReports.itemId, itemIds), eq(contentReports.status, 'open')))
        .groupBy(contentReports.itemId);
      return new Map(rows.map((r) => [r.itemId, r.n]));
    },

    async get(id: string) {
      const [row] = await db
        .select({ report: contentReports, name: users.name, email: users.email })
        .from(contentReports)
        .innerJoin(users, eq(users.id, contentReports.userId))
        .where(eq(contentReports.id, id));
      return row ?? null;
    },

    async resolve(
      id: string,
      values: Pick<ReportRow, 'status' | 'resolvedByAdminId' | 'resolutionNote' | 'resolvedAt'>,
    ) {
      await db.update(contentReports).set(values).where(eq(contentReports.id, id));
    },
  };
}

export type ReportRepository = ReturnType<typeof createReportRepository>;

import { z } from 'zod';

/* Admin accounts (spec §11.3, §26.2): created only by other admins; mandatory TOTP 2FA. */

export const adminAccountSchema = z.object({
  id: z.string(),
  email: z.string(),
  fullName: z.string(),
  status: z.enum(['active', 'disabled']),
  /** False until the admin enrolls (first login) or after a 2FA reset. */
  twoFactorEnabled: z.boolean(),
  createdAt: z.string(),
  lastSeenAt: z.string().nullable(),
});
export const adminAccountListSchema = z.array(adminAccountSchema);

export const createAdminBodySchema = z.object({
  email: z.string().trim().toLowerCase().pipe(z.email().max(254)),
  fullName: z.string().trim().min(2).max(120),
  /** Temporary password handed over out of band; the admin enrolls in 2FA at first login. */
  password: z.string().min(10).max(128),
});

export type AdminAccount = z.infer<typeof adminAccountSchema>;

z.globalRegistry.add(adminAccountSchema, { id: 'AdminAccount' });
z.globalRegistry.add(adminAccountListSchema, { id: 'AdminAccountList' });
z.globalRegistry.add(createAdminBodySchema, { id: 'CreateAdminRequest' });

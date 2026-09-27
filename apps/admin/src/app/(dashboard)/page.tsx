'use client';

import { Card, CardDescription, CardTitle } from '@/components/ui/card';
import { useAdmin } from './layout';

export default function DashboardHome() {
  const admin = useAdmin();
  return (
    <div className="mx-auto max-w-5xl space-y-6">
      <Card className="space-y-2">
        <CardTitle>أهلاً {admin?.fullName}</CardTitle>
        <CardDescription>
          هذه هي المرحلة الأولى من لوحة الإدارة. ستظهر أقسام إدارة المحتوى والوصول تباعاً مع المراحل القادمة.
        </CardDescription>
      </Card>
    </div>
  );
}

import { Card, CardDescription, CardTitle } from '@/components/ui/card';

export function AuthShell({
  title,
  description,
  children,
}: {
  title: string;
  description?: string;
  children: React.ReactNode;
}) {
  return (
    <main className="flex min-h-dvh flex-col items-center justify-center gap-6 bg-accent/40 p-4">
      <img src="/wordmark-blue.svg" alt="Plengo" className="h-14 w-auto" />
      <Card className="w-full max-w-sm space-y-6">
        <div className="space-y-1">
          <CardTitle>{title}</CardTitle>
          {description ? <CardDescription>{description}</CardDescription> : null}
        </div>
        {children}
      </Card>
    </main>
  );
}

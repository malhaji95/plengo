import type { Metadata } from 'next';
import { ErrorReporting } from '@/components/error-reporting';
import './globals.css';

export const metadata: Metadata = {
  title: 'لوحة الإدارة',
  robots: { index: false, follow: false },
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="ar" dir="rtl" suppressHydrationWarning>
      <body className="min-h-dvh font-sans">
        <ErrorReporting />
        {children}
      </body>
    </html>
  );
}

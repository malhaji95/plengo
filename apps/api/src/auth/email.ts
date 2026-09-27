import type { FastifyBaseLogger } from 'fastify';

export interface EmailMessage {
  to: string;
  subject: string;
  text: string;
}

export interface EmailSender {
  send(message: EmailMessage): Promise<void>;
}

/** Development/test sender: logs the message and keeps it in memory so tests can read OTPs. */
export class ConsoleEmailSender implements EmailSender {
  readonly outbox: EmailMessage[] = [];

  constructor(private readonly log?: FastifyBaseLogger) {}

  async send(message: EmailMessage): Promise<void> {
    this.outbox.push(message);
    this.log?.info({ to: message.to, subject: message.subject, text: message.text }, 'email (console)');
  }
}

export class ResendEmailSender implements EmailSender {
  constructor(
    private readonly apiKey: string,
    private readonly from: string,
  ) {}

  async send(message: EmailMessage): Promise<void> {
    const res = await fetch('https://api.resend.com/emails', {
      method: 'POST',
      headers: { Authorization: `Bearer ${this.apiKey}`, 'Content-Type': 'application/json' },
      body: JSON.stringify({ from: this.from, to: message.to, subject: message.subject, text: message.text }),
    });
    if (!res.ok) throw new Error(`Resend failed: ${res.status} ${await res.text()}`);
  }
}

export type OtpPurpose = 'sign-in' | 'email-verification' | 'forget-password' | 'change-email';

export function otpEmail(to: string, otp: string, purpose: OtpPurpose): EmailMessage {
  const subject =
    purpose === 'forget-password' ? 'رمز إعادة تعيين كلمة المرور' : 'رمز تفعيل البريد الإلكتروني';
  return {
    to,
    subject,
    text: `رمز التحقق الخاص بك هو: ${otp}\nينتهي خلال 10 دقائق. إذا لم تطلب هذا الرمز فتجاهل هذه الرسالة.`,
  };
}

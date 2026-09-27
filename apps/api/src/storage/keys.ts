export type KeyKind = 'flashcard' | 'banner' | 'teacher' | 'cover' | 'user-card' | 'import' | 'original';
export type Variant = 'full' | 'thumb' | 'original';

/**
 * Opaque object keys with no business meaning (spec §12.2):
 * {env}/{kind}/{yyyy}/{mm}/{uuid}/{variant}.webp — originals keep no extension.
 */
export function objectKey(env: string, kind: KeyKind, id: string, variant: Variant, at = new Date()): string {
  const yyyy = at.getUTCFullYear().toString();
  const mm = (at.getUTCMonth() + 1).toString().padStart(2, '0');
  const file = variant === 'original' ? 'original' : `${variant}.webp`;
  return `${env}/${kind}/${yyyy}/${mm}/${id}/${file}`;
}

import { mkdtempSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { afterAll, describe, expect, it } from 'vitest';
import { MemoryStorage } from '../src/storage/memory-storage.js';

const dir = mkdtempSync(join(tmpdir(), 'plengo-storage-'));
afterAll(() => rmSync(dir, { recursive: true, force: true }));

describe('dev storage on disk (LOCAL_STORAGE_DIR)', () => {
  it('shares objects between instances and survives restarts', async () => {
    const writer = new MemoryStorage({ dir });
    await writer.put('private', 'dev/flashcard/a/full.webp', Buffer.from('abc'), 'image/webp');
    const reader = new MemoryStorage({ dir });
    expect((await reader.getWithType('private', 'dev/flashcard/a/full.webp'))?.contentType).toBe(
      'image/webp',
    );
    expect(await reader.exists('private', 'dev/flashcard/a/full.webp')).toBe(true);
    await reader.copy('private', 'dev/flashcard/a/full.webp', 'dev/flashcard/b/full.webp');
    expect((await new MemoryStorage({ dir }).get('private', 'dev/flashcard/b/full.webp'))?.toString()).toBe(
      'abc',
    );
    await reader.delete('private', 'dev/flashcard/a/full.webp');
    expect(await new MemoryStorage({ dir }).exists('private', 'dev/flashcard/a/full.webp')).toBe(false);
    expect(await reader.get('private', '../escape')).toBeNull();
  });
});
